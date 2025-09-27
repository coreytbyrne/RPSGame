extends Node2D
class_name PlayerButton

@export var button_config:ButtonConfig

var wire_connection_point:Vector2
var is_connected:bool = false

signal player_button_pressed(name:GameplayUtils.OBJECT, effect:GameplayUtils.EFFECT)
signal mouse_wire_connection_overlap(player_button:PlayerButton, is_hovering:bool)

func _ready() -> void:
	$Button.text = GameplayUtils.get_object_name(button_config.object_name)
	wire_connection_point = $WireConnection.global_position


func _on_button_pressed() -> void:
	player_button_pressed.emit(button_config.object_name, button_config.effect)


func _on_wire_connection_mouse_entered() -> void:
	mouse_wire_connection_overlap.emit(self, true)


func _on_wire_connection_mouse_exited() -> void:
	mouse_wire_connection_overlap.emit(self, false)
