extends Node2D
class_name Encounter

@export var cartridge_scene:PackedScene
@export var rule_board_scene:PackedScene
@export var encounter_config:EncounterConfig
@export var plug_scene:PackedScene

@onready var player:Player = $Player

var remaining_plugs:int

var active_plug:Plug
var hovered_cartridge:Cartridge = null
var hovered_plug_target:PlugTarget = null

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
	
	$RuleBoardSpawnPosition.add_child(rules_board)
	rules_board.connect_encounter_to_rule_signals(self)
	
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


func resolve_round() -> void:
	# Get the objects that both players have played
	var player_object:GameplayUtils.OBJECT = $PlayedObject.played_object
	var opponent_object:GameplayUtils.OBJECT = $Opponent.get_played_object()
	
	# Get the current rules
	var rules:Array[RuleConfig] = $RuleBoardSpawnPosition.get_child(0).get_current_rules()
	
	# Check what rules are applicable
	var applicable_rules:Array[RuleConfig] = get_applicable_rules(player_object, opponent_object, rules)
	
	# Resolve the applicable rules
	if not applicable_rules.is_empty():
		resolve_rules(player_object, opponent_object, applicable_rules)
	
	# Clear current played object
	#$Player/PlayedObject.clear_played_object()
	$PlayedObject.played_object_updated(null)


func get_applicable_rules(player_obj:GameplayUtils.OBJECT,opponent_obj:GameplayUtils.OBJECT,rules:Array[RuleConfig]) -> Array[RuleConfig]:
	var applicable_rules:Array[RuleConfig]
	
	for rule:RuleConfig in rules:
		var left_rule:GameplayUtils.OBJECT = rule.left_object
		var right_rule:GameplayUtils.OBJECT = rule.right_object
		
		var is_applicable:bool = (
			 ( (player_obj == left_rule) and (opponent_obj == right_rule) ) or
			 ( (player_obj == right_rule) and (opponent_obj == left_rule) )
			)
		
		if is_applicable:
			applicable_rules.append(rule)
	
	return applicable_rules


func resolve_rules(player_obj:GameplayUtils.OBJECT,opponent_obj:GameplayUtils.OBJECT,rules:Array[RuleConfig]) -> void:
	for rule:RuleConfig in rules:
		print("Rule Triggered: %s\n" % GameplayUtils.get_effect_text(rule.left_object,rule.effect, rule.right_object))
		# Check if it is the player or opponent that wins the rule
		if rule.left_object != rule.right_object:
			var winner:Participant
			var loser:Participant
			if player_obj == rule.left_object:
				winner = $Player
				loser = $Opponent
			else:
				winner = $Opponent
				loser = $Player
			
			RuleResolver.delegate_rule_resolve(winner, loser, rule.effect)
			RuleResolver.delegate_rule_resolve(winner, loser, rule.constant_effect)
			
		# If the objects are the same, the rule resolution should trigger for both participants.
		else:
			RuleResolver.delegate_rule_resolve($Player, $Opponent, rule.effect)
			RuleResolver.delegate_rule_resolve($Player, $Opponent, rule.constant_effect)
			RuleResolver.delegate_rule_resolve($Opponent, $Player, rule.effect)
			RuleResolver.delegate_rule_resolve($Opponent, $Player, rule.constant_effect)

func check_if_game_over() -> void:
	if $Player.health <= 0:
		print("%s loses" % $Player.participant_name)
	if $Opponent.health <= 0:
		print("%s loses" % $Opponent.participant_name)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		if hovered_cartridge != null or hovered_plug_target != null:
			plug_in()
		elif hovered_cartridge == null and hovered_plug_target == null and active_plug != null:
			unplug()
	if event.is_action_pressed("deselect"):
		if (hovered_cartridge != null or hovered_plug_target != null) and active_plug == null:
			unplug()



## TODO: This is for testing only. In practice, there would need to be a more elegant
## option to remove a single wire at a time
#func _on_reset_wires_pressed() -> void:
	#for wire:Wire in $Player/Wires.get_children():
		#wire.disconnect_button()
		#wire.disconnect_target()
		#wire.queue_free()
	#
	#remaining_wires = encounter_config.num_player_wires + $Player.wire_count_modifier


func _on_next_round_button_pressed() -> void:
	#var player_actions_str:String = ""
	#var opponent_action_str:String = ""
	
	# Ignore a "next round" button press if you're in the middle of drawing a wire
	#if current_wire != null:
		#return
	
	# Opponent chooses their action
	var opponent_action_sequence:Opponent.ActionSequence = $Opponent.choose_actions_to_perform()
	$Opponent.apply_actions(opponent_action_sequence)
	
	for action:Opponent.Action in opponent_action_sequence.get_actions():
		if action is Opponent.PlayAction:
			#opponent_action_str += "%s played: %s\n" % [$Opponent.participant_name, GameplayUtils.get_object_name(action.obj)]
			$EnemyPlayedObject.played_object_updated(GameplayUtils.get_config_from_object(action.obj))
		else:
			pass
			#opponent_action_str += "%s updated: %s\n" % [$Opponent.participant_name, action.to_string()]
	
	# Check for rule update conflicts
	
	
	# Commit the player changes
	#for wire:Wire in $Player/Wires.get_children():
		#wire.connected_target.commit_assignment()
		#await SignalBus.rule_updated
	
	#player_actions_str += "%s played %s\n" % [$Player.participant_name, GameplayUtils.get_object_name($Player.played_object.target.assignment)]
	#$LastRoundHistory.text = "%s\n%s\n\n" % [player_actions_str, opponent_action_str]
	
	
	$Opponent.add_to_player_history($PlayedObject.played_object)
	
	# Resolve the outcome of the cards played, given the new updates
	resolve_round()
	
	# Transition to the next round
	RuleResolver.next_round()
	
	# Resolve any "in X round" effects at the beginning of the relevant round
	RuleResolver.resolve_futures_round_start()
	
	check_if_game_over()
	
	#_on_reset_wires_pressed()
	print("**************************************************************")
