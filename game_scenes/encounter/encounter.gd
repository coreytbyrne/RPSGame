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
		var button_position:Marker2D = $PlayerButtonPositions.get_child(count)
		var new_button:PlayerButton = button_scene.instantiate()
		new_button.mouse_wire_connection_overlap.connect(update_hovered_wire_connection)
		new_button.button_config = encounter_config.player_buttons[count]
		button_position.add_child(new_button)
	
	
	var rules_board:RulesBoard = rule_board_scene.instantiate()
	rules_board.rule_configs = encounter_config.rules
	$RuleBoardSpawnPosition.add_child(rules_board)
	rules_board.connect_encounter_to_rule_signals(self)
	
	# Connect to Played Object target
	$PlayedObject.target.mouse_wire_connection_overlap.connect(update_hovered_wire_connection)
	
	remaining_wires = encounter_config.num_player_wires



func update_hovered_wire_connection(button, is_hovering) -> void:
	if is_hovering:
		hovered_button = button
	else:
		if hovered_button == button:
			hovered_button = null


func create_wire() -> void:
	current_wire = wire_scene.instantiate()
	current_wire.circuit_completed.connect(wire_circuit_completed)
	$Wires.add_child(current_wire)


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
		for wire:Wire in $Wires.get_children():
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
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		# If you're hovering over a button, create a wire
		update_current_wire()
	
	if event.is_action_pressed("deselect"):
		remove_wire()


## TODO: This is for testing only. In practice, there would need to be a more elegant
## option to remove a single wire at a time
func _on_reset_wires_pressed() -> void:
	for wire:Wire in $Wires.get_children():
		wire.disconnect_button()
		wire.disconnect_target()
		wire.queue_free()
	
	remaining_wires = encounter_config.num_player_wires


func _on_next_round_button_pressed() -> void:
	# Ignore a "next round" button press if you're in the middle of drawing a wire
	if current_wire != null:
		return
	
	for wire:Wire in $Wires.get_children():
		wire.connected_target.commit_assignment()
		await SignalBus.rule_updated
	_on_reset_wires_pressed()
	
	resolve_round()
