extends Node2D
class_name EncounterScene

@export var wire_scene:PackedScene
@export var button_scene:PackedScene
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
	
	# Connect to rules targets
	for rule:Rule in $RulesBoard.get_children():
		rule.left_target.mouse_wire_connection_overlap.connect(update_hovered_wire_connection)
		rule.effect_target.mouse_wire_connection_overlap.connect(update_hovered_wire_connection)
		rule.right_target.mouse_wire_connection_overlap.connect(update_hovered_wire_connection)
	
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		# If you're hovering over a button, create a wire
		update_current_wire()


## TODO: This is for testing only. In practice, there would need to be a more elegant
## option to remove a single wire at a time
func _on_reset_wires_pressed() -> void:
	for wire:Wire in $Wires.get_children():
		wire.disconnect_button()
		wire.disconnect_target()
		wire.queue_free()
	
	remaining_wires = encounter_config.num_player_wires

## TODO: Need to clear wires after the round
func _on_next_round_button_pressed() -> void:
	for wire:Wire in $Wires.get_children():
		wire.connected_target.commit_assignment()
	
		
