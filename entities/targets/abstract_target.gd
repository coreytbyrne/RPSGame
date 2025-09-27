@abstract class_name Target
extends Node2D

var wire_connection_point:Vector2
var is_connected:bool = false

signal mouse_wire_connection_overlap(target:Target, is_hovering:bool)


func _on_wire_connection_mouse_entered() -> void:
	mouse_wire_connection_overlap.emit(self, true)


func _on_wire_connection_mouse_exited() -> void:
	mouse_wire_connection_overlap.emit(self, false)
