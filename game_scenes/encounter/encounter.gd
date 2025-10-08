extends Node2D
class_name Encounter

@export var cartridge_scene:PackedScene
@export var rule_board_scene:PackedScene
@export var encounter_config:EncounterConfig
@export var plug_scene:PackedScene

@onready var player:Player = $Player
var remaining_plugs:int

var rule_board_ref:RulesBoard

var active_plug:Plug
var hovered_cartridge:Cartridge = null
var hovered_plug_target:PlugTarget = null

var disable_input:bool = false

func _ready() -> void:
	# Init Player details
	player.default_plug_count = encounter_config.num_player_plugs
	
	for count:int in encounter_config.player_cartridges.size():
		var cartridge_node:Cartridge = cartridge_scene.instantiate()
		var spawn_position:Marker2D = $CartidgeSpawnPositions.get_child(count)
		
		cartridge_node.config = encounter_config.player_cartridges[count]
		cartridge_node.cart_plug_slot_hovered.connect(update_hovered_cartidge)
		spawn_position.add_child(cartridge_node)
		player.cartridges.append(cartridge_node)
	
	# Create the Rules Board and give the Resolver a reference to it
	var rules_board:RulesBoard = rule_board_scene.instantiate()
	rules_board.rule_configs = encounter_config.rules
	
	RuleResolver.rule_board_reference = rules_board
	RuleResolver.encounter_reference = self
	
	$RuleBoardSpawnPosition.add_child(rules_board)
	rule_board_ref = rules_board
	rules_board.connect_encounter_to_rule_signals(self)
	rules_board.connect_player_to_rule_signals(player)
	
	# Connect to Played Object target
	$PlayedObject.target.target_plug_slot_hovered.connect(update_hovered_target)
	
	# Setup Opponent dependencies/configs
	$Opponent.rule_board_reference = rules_board
	$Opponent.set_available_cartridges(encounter_config.opponent_cartridges)
	$Opponent.default_plug_count = encounter_config.num_opponent_plugs
	



func update_hovered_cartidge(cartridge:Cartridge) -> void:
	hovered_cartridge = cartridge


func update_hovered_target(plug_target:PlugTarget) -> void:
	hovered_plug_target = plug_target


func plug_in() -> void:
	
	var is_new_plug:bool = false
	is_new_plug = ( active_plug == null and (player.remaining_plug_count + player.plug_count_modifier > 0) )
	
	if is_new_plug:
		var plug_node:Plug = plug_scene.instantiate()
		$Plugs.add_child(plug_node)
		
		player.plugs.append(plug_node)
		active_plug = plug_node
		player.remaining_plug_count -= 1

	if active_plug != null:
		# Check if that cartridge is already occupied by a different plug
		if hovered_cartridge != null and hovered_cartridge.connected_plug == null:
			active_plug.connect_cartidge(hovered_cartridge)
		# Check if that cartridge is already occupied by a different plug
		elif hovered_plug_target != null and hovered_plug_target.connected_plug == null:
			active_plug.connect_target(hovered_plug_target)

		# Once both ends are connected, it should not longer be the active plug
		if active_plug.is_circuit_complete:
			active_plug = null
	

func unplug() -> void:
	if active_plug == null:
		if hovered_cartridge != null:
			active_plug = hovered_cartridge.connected_plug
			if active_plug != null:
				active_plug = active_plug.disconnect_cartridge()
				if active_plug == null:
					player.remaining_plug_count += 1
					
		if hovered_plug_target != null:
			active_plug = hovered_plug_target.connected_plug
			if active_plug != null:
				active_plug = active_plug.disconnect_target()
				if active_plug == null:
					player.remaining_plug_count += 1

	else:
		active_plug.destroy_plug()
		active_plug = null
		player.remaining_plug_count += 1


func clear_plugs() -> void:
	for plug in $Plugs.get_children():
		plug.queue_free()
		player.remaining_plug_count += 1
	
	player.plugs.clear()

	
	


func resolve_round() -> void:
	# Get the objects that both players have played
	var player_object:GameplayUtils.OBJECT = $PlayedObject.played_object
	var opponent_object:GameplayUtils.OBJECT = $Opponent.get_played_object()
	
	# Check if either played NONE
	await check_for_none_played(player_object, opponent_object)

	
	# Get the current rules
	var rules:Array[RuleConfig] = rule_board_ref.get_current_rules()
	
	# Check what rules are applicable
	var applicable_rules:Dictionary[int,RuleConfig] = get_applicable_rules(player_object, opponent_object, rules)
	
	# Resolve the applicable rules
	if not applicable_rules.is_empty():
		await resolve_rules(player_object, opponent_object, applicable_rules)
	
	# Clear current played object
	
	await $EnemyPlayedObject.played_object_updated(null)
	await $PlayedObject.played_object_updated(null)
	
func check_for_none_played(player_obj:GameplayUtils.OBJECT,opponent_obj:GameplayUtils.OBJECT) -> void:

	## Static rule of "Anything beats NOTHING"
	if player_obj == GameplayUtils.OBJECT.NONE:
		RuleResolver.delegate_rule_resolve($Opponent, $Player, GameplayUtils.EFFECT.BEATS)
		await RuleResolver.rule_resolved
		
	if opponent_obj == GameplayUtils.OBJECT.NONE:
		RuleResolver.delegate_rule_resolve($Player, $Opponent, GameplayUtils.EFFECT.BEATS)
		await RuleResolver.rule_resolved




func get_applicable_rules(player_obj:GameplayUtils.OBJECT,opponent_obj:GameplayUtils.OBJECT,rules:Array[RuleConfig]) -> Dictionary[int,RuleConfig]:
	var applicable_rules:Dictionary[int,RuleConfig]
	
	#for rule:RuleConfig in rules:
	for count:int in range(rules.size()):
		var left_rule:GameplayUtils.OBJECT = rules[count].left_object
		var right_rule:GameplayUtils.OBJECT = rules[count].right_object
		
		var is_applicable:bool = (
			 ( (player_obj == left_rule) and (opponent_obj == right_rule) ) or
			 ( (player_obj == right_rule) and (opponent_obj == left_rule) )
			)
		
		if is_applicable:
			applicable_rules[count] = rules[count]

	return applicable_rules


func resolve_rules(player_obj:GameplayUtils.OBJECT,opponent_obj:GameplayUtils.OBJECT,rules:Dictionary[int,RuleConfig]) -> void:
	#for rule:RuleConfig in rules.values():
	for rule_num in rules.keys():
		rule_board_ref.mark_rule_triggered(rule_num, true)
		
		print("Rule Triggered: %s\n" % GameplayUtils.get_effect_text(rules[rule_num].left_object,rules[rule_num].effect, rules[rule_num].right_object))
		# Check if it is the player or opponent that wins the rule
		if rules[rule_num].left_object != rules[rule_num].right_object:
			var winner:Participant
			var loser:Participant
			if player_obj == rules[rule_num].left_object:
				winner = $Player
				loser = $Opponent
			else:
				winner = $Opponent
				loser = $Player
			

			RuleResolver.delegate_rule_resolve(winner, loser, rules[rule_num].effect)
			await RuleResolver.rule_resolved
			RuleResolver.delegate_rule_resolve(winner, loser, rules[rule_num].constant_effect)
			await RuleResolver.rule_resolved
			
		# If the objects are the same, the rule resolution should trigger for both participants.
		else:
			RuleResolver.delegate_rule_resolve($Player, $Opponent, rules[rule_num].effect)
			await RuleResolver.rule_resolved
			RuleResolver.delegate_rule_resolve($Player, $Opponent, rules[rule_num].constant_effect)
			await RuleResolver.rule_resolved
			RuleResolver.delegate_rule_resolve($Opponent, $Player, rules[rule_num].effect)
			await RuleResolver.rule_resolved
			RuleResolver.delegate_rule_resolve($Opponent, $Player, rules[rule_num].constant_effect)
			await RuleResolver.rule_resolved
		
		#NOTE: This is here just so the player can see the activated rule in the interim
		await get_tree().create_timer(2.0).timeout
		rule_board_ref.mark_rule_triggered(rule_num, false)



func check_if_game_over() -> void:
	if $Player.health <= 0:
		print("%s loses" % $Player.participant_name)
	if $Opponent.health <= 0:
		print("%s loses" % $Opponent.participant_name)


func disable_interaction(is_disabled:bool) -> void:
	disable_input = is_disabled
	$ResetPlugsButton.disabled = is_disabled
	$EndRoundButton.disabled = is_disabled
	


func _unhandled_input(event: InputEvent) -> void:
	if disable_input:
		return
		
	if event.is_action_pressed("select"):
		if hovered_cartridge != null or hovered_plug_target != null:
			plug_in()
		elif hovered_cartridge == null and hovered_plug_target == null and active_plug != null:
			unplug()
	if event.is_action_pressed("deselect"):
		if (hovered_cartridge != null or hovered_plug_target != null) and active_plug == null:
			unplug()


func _on_next_round_button_pressed() -> void:
	disable_interaction(true)

	# Opponent chooses their action
	var opponent_action_sequence:Opponent.ActionSequence = $Opponent.choose_actions_to_perform()
	$Opponent.apply_actions(opponent_action_sequence)
	await rule_board_ref.apply_changes_to_rules()
	await $EnemyPlayedObject.played_object_updated(GameplayUtils.get_config_from_object($Opponent.played_object))
	
	$Opponent.add_to_player_history($PlayedObject.played_object)
	
	# Resolve the outcome of the cards played, given the new updates
	await resolve_round()
	
	# Transition to the next round
	RuleResolver.next_round()
	
	# Resolve any "in X round" effects at the beginning of the relevant round
	RuleResolver.resolve_futures_round_start()
	
	check_if_game_over()
	
	# Remove plugs for player
	clear_plugs()
	player.recharge_swap()
	
	disable_interaction(false)
	#_on_reset_wires_pressed()
	print("**************************************************************")


func _on_reset_plugs_button_pressed() -> void:
	for plug:Plug in $Plugs.get_children():
		plug.destroy_plug()
		player.remaining_plug_count += 1
