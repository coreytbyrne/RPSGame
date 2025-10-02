extends Node2D
class_name Encounter

@export var wire_scene:PackedScene
@export var button_scene:PackedScene
@export var rule_board_scene:PackedScene

@export var encounter_config:EncounterConfig

var remaining_wires:int
var current_wire:Wire = null

var hovered_button = null

func _ready() -> void:
	# Create the player buttons
	for count:int in encounter_config.player_buttons.size():
		var button_position:Marker2D = $Player/PlayerButtonPositions.get_child(count)
		var new_button:PlayerButton = button_scene.instantiate()
		new_button.mouse_wire_connection_overlap.connect(update_hovered_wire_connection)
		new_button.button_config = encounter_config.player_buttons[count]
		button_position.add_child(new_button)
	
	# Create the Rules Board and give the Resolver a reference to it
	var rules_board:RulesBoard = rule_board_scene.instantiate()
	rules_board.rule_configs = encounter_config.rules
	
	RuleResolver.rule_board_reference = rules_board
	
	$RuleBoardSpawnPosition.add_child(rules_board)
	rules_board.connect_encounter_to_rule_signals(self)
	
	# Connect to Played Object target
	$Player/PlayedObject.target.mouse_wire_connection_overlap.connect(update_hovered_wire_connection)
	
	remaining_wires = encounter_config.num_player_wires
	
	# Setup Opponent dependencies/configs
	$Opponent.rule_board_reference = rules_board
	$Opponent.set_available_buttons(encounter_config.opponent_buttons)
	$Opponent.default_wire_count = encounter_config.num_opponent_wires


func update_hovered_wire_connection(button, is_hovering) -> void:
	if is_hovering:
		hovered_button = button
	else:
		if hovered_button == button:
			hovered_button = null


func create_wire() -> void:
	current_wire = wire_scene.instantiate()
	current_wire.circuit_completed.connect(wire_circuit_completed)
	$Player/Wires.add_child(current_wire)


func wire_circuit_completed() -> void:
	current_wire = null


func update_current_wire() -> void:
	if hovered_button != null:
		# Create a new wire if you aren't currently drawing a wire and you have wires to spare
		if current_wire == null and remaining_wires > 0:
			remaining_wires -= 1
			create_wire()
		
		# If you have a current wire being drawn, then update. 
		if current_wire != null:
			if hovered_button is PlayerButton:
				current_wire.connect_button(hovered_button)
			elif hovered_button is Target:
				current_wire.connect_target(hovered_button)
	
	else:
			if current_wire != null:
				current_wire.disconnect_button()
				current_wire.queue_free()
				remaining_wires = clamp(remaining_wires + 1, 0, encounter_config.num_player_wires)

func remove_wire() -> void:
	# Don't cut wires while you're drawing a wire
	if hovered_button != null and current_wire == null:
		for wire:Wire in $Player/Wires.get_children():
			if wire.connected_button == hovered_button:
				current_wire = wire
				wire.disconnect_button()
				await SignalBus.rule_updated
				wire.resume_drawing_wire()
			elif wire.connected_target == hovered_button:
				current_wire = wire
				wire.disconnect_target()
				await SignalBus.rule_updated
				wire.resume_drawing_wire()


func resolve_round() -> void:
	# Get the objects that both players have played
	var player_object:GameplayUtils.OBJECT = $Player/PlayedObject.get_played_object()
	var opponent_object:GameplayUtils.OBJECT = $Opponent.get_played_object()
	
	# Get the current rules
	var rules:Array[RuleConfig] = $RuleBoardSpawnPosition.get_child(0).get_current_rules()
	
	# Check what rules are applicable
	var applicable_rules:Array[RuleConfig] = get_applicable_rules(player_object, opponent_object, rules)
	
	# Resolve the applicable rules
	if not applicable_rules.is_empty():
		resolve_rules(player_object, opponent_object, applicable_rules)
	
	# Clear current played object
	$Player/PlayedObject.clear_played_object()


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
		# If you're hovering over a button, create a wire
		update_current_wire()
	
	if event.is_action_pressed("deselect"):
		remove_wire()


## TODO: This is for testing only. In practice, there would need to be a more elegant
## option to remove a single wire at a time
func _on_reset_wires_pressed() -> void:
	for wire:Wire in $Player/Wires.get_children():
		wire.disconnect_button()
		wire.disconnect_target()
		wire.queue_free()
	
	remaining_wires = encounter_config.num_player_wires + $Player.wire_count_modifier


func _on_next_round_button_pressed() -> void:
	var player_actions_str:String = ""
	var opponent_action_str:String = ""
	
	# Ignore a "next round" button press if you're in the middle of drawing a wire
	if current_wire != null:
		return
	
	# Opponent chooses their action
	var opponent_action_sequence:Opponent.ActionSequence = $Opponent.choose_actions_to_perform()
	$Opponent.apply_actions(opponent_action_sequence)
	
	for action:Opponent.Action in opponent_action_sequence.get_actions():
		if action is Opponent.PlayAction:
			opponent_action_str += "%s played: %s\n" % [$Opponent.participant_name, GameplayUtils.get_object_name(action.obj)]
		else:
			opponent_action_str += "%s updated: %s\n" % [$Opponent.participant_name, action.to_string()]
	
	# Check for rule update conflicts
	
	
	# Commit the player changes
	for wire:Wire in $Player/Wires.get_children():
		wire.connected_target.commit_assignment()
		await SignalBus.rule_updated
	
	player_actions_str += "%s played %s\n" % [$Player.participant_name, GameplayUtils.get_object_name($Player.played_object.target.assignment)]
	$LastRoundHistory.text = "%s\n%s\n\n" % [player_actions_str, opponent_action_str]
	
	$Opponent.add_to_player_history($Player/PlayedObject.get_played_object())
	
	# Resolve the outcome of the cards played, given the new updates
	resolve_round()
	
	# Transition to the next round
	RuleResolver.next_round()
	
	# Resolve any "in X round" effects at the beginning of the relevant round
	RuleResolver.resolve_futures_round_start()
	
	check_if_game_over()
	
	_on_reset_wires_pressed()
	print("**************************************************************")
