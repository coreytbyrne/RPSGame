@abstract class_name Target
extends Node2D

var wire_connection_point:Vector2

signal mouse_wire_connection_overlap(target:Target, is_hovering:bool)


func _on_wire_connection_mouse_entered() -> void:
	mouse_wire_connection_overlap.emit(self, true)


func _on_wire_connection_mouse_exited() -> void:
	mouse_wire_connection_overlap.emit(self, false)

#func _ready() -> void:
	#wire_connection_point = $WireConnection.global_position
#
#func update_assignment(new_assignment) -> void:
	##if target_type == TYPE.OBJECT:
		##print(PlayOptions.NAME.keys()[new_assignment])
	##elif target_type == TYPE.EFFECT:
		##print(PlayOptions.EFFECT.keys()[new_assignment])
		#assignment = new_assignment
		#updated_assignent.emit()
