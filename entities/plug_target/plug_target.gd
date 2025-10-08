extends Node2D
class_name PlugTarget


var is_disabled:bool = false
var connected_plug:Plug
var plug_sprite_position:Vector2

var incoming_data:CartridgeConfig:
	set(value):
		data_updated.emit(value)
		incoming_data = value

signal target_plug_slot_hovered(target:PlugTarget)
signal data_updated(data:CartridgeConfig)

enum TARGET_TYPE {OBJECT, EFFECT}

func _ready() -> void:
	plug_sprite_position = $PlugSlot.global_position


func _on_plug_slot_mouse_entered() -> void:
	target_plug_slot_hovered.emit(self)


func _on_plug_slot_mouse_exited() -> void:
	target_plug_slot_hovered.emit(null)
