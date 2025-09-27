extends Node2D
class_name Wire

var connected_button:PlayerButton
var connected_target:Target

var is_drawing_line:bool = false :
	set(value):
		if value:
			$WireLine.visible = true
		else:
			$WireLine.visible = false
		is_drawing_line = value
		
var is_full_circuit:bool = false :
	set(value):
		is_full_circuit = value
		if is_full_circuit:
			circuit_completed.emit()

signal circuit_completed()

## TODO: Need to add a way to create wires in game.
## Either when clicking a WireConnection, or when clicking a "WireSpool" item


func _ready() -> void:
	# Create 2 points that can be edited via other functions
	$WireLine.add_point(Vector2.ZERO)
	$WireLine.add_point(Vector2.ZERO)
	$WireLine.visible = false


func _process(delta: float) -> void:
	if not is_full_circuit and is_drawing_line:
		var mouse_pos:Vector2 = get_global_mouse_position()
		$WireLine.points[1] = mouse_pos



func connect_button(button:PlayerButton) -> void:
	if not button.is_connected and connected_button == null:
		connected_button = button
		connected_button.is_connected = true
		
		connected_button.player_button_pressed.connect(send_button_signal)
		
		# On the first connection established, draw from the button -> mouse
		if not is_drawing_line:
			is_drawing_line = true
			$StartConnection.position = connected_button.wire_connection_point
		# If the button is the second connection established, draw from button -> target
		else:
			is_full_circuit = true
			$EndConnection.position = connected_button.wire_connection_point
			
		draw_wire()


func disconnect_button() -> void:
	if connected_button != null:
		connected_button.is_connected = false
		connected_button.player_button_pressed.disconnect(send_button_signal)
		connected_button = null
		
		if connected_target != null:
			connected_target.revert_assignment()


func draw_wire() -> void:
	$WireLine.points[0] = $StartConnection.position
	if is_full_circuit:
		$WireLine.points[1] = $EndConnection.position
	else:
		$WireLine.points[1] = get_global_mouse_position()

# Called after snipping one end of the wire - this allows the player to 
# move one of the wire ends
func resume_drawing_wire() -> void:
	is_drawing_line = true
	is_full_circuit = false
	if connected_button != null:
		$StartConnection.position = connected_button.wire_connection_point
	elif connected_target != null:
		$StartConnection.position = connected_target.wire_connection_point
	
	draw_wire()

func connect_target(target:Target) -> void:
	if not target.is_connected and connected_target == null:
		connected_target = target
		connected_target.is_connected = true
		
		# On the first connection established, draw from the button -> mouse
		if not is_drawing_line:
			is_drawing_line = true
			$StartConnection.position = connected_target.wire_connection_point
		# If the button is the second connection established, draw from button -> target
		else:
			is_full_circuit = true
			$EndConnection.position = connected_target.wire_connection_point
		draw_wire()


func disconnect_target() -> void:
	if connected_target != null:
		connected_target.revert_assignment()
		connected_target.is_connected = false
		connected_target = null


func send_button_signal(button_name:GameplayUtils.OBJECT, button_effect:GameplayUtils.EFFECT) -> void:
	if connected_target is EffectTarget:
		connected_target.update_assignment(button_effect)
	elif connected_target is ObjectTarget:
		connected_target.update_assignment(button_name)
