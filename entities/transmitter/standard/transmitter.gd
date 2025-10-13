extends Node
class_name Transmitter

@export var config:CartridgeConfig


var connected_plug:Plug
var is_disabled:bool = false
var cooldown:int = 0
var cooldown_count:int:
	set(value):
		if value > 0:
			disable_transmitter()
		else:
			enable_transmitter()
			value = 0
		cooldown_count = value

var plug_sprite_position:Vector2

signal transmitter_plug_slot_hovered(cart:Transmitter)

func _ready() -> void:
	$TransmitterLabel.text = GameplayUtils.get_object_name(config.object)
	cooldown = config.base_cooldown
	plug_sprite_position = $PlugSlot.global_position


func transmitter_used() -> void:
	if cooldown > 0:
		cooldown_count = cooldown


func next_round() -> void:
	if cooldown_count > 0:
		cooldown_count -= 1


func disable_transmitter() -> void:
	$TransmitterLabel.text = "DISABLED\n%s" % [GameplayUtils.get_object_name(config.object)]
	is_disabled = true
	$PlaceholderBackground.color = Color.CRIMSON


func enable_transmitter() -> void:
	$TransmitterLabel.text = "%s" % [GameplayUtils.get_object_name(config.object)]
	is_disabled = false
	$PlaceholderBackground.color = Color.WHITE


func _on_plug_slot_mouse_entered() -> void:
	transmitter_plug_slot_hovered.emit(self)


func _on_plug_slot_mouse_exited() -> void:
	transmitter_plug_slot_hovered.emit(null)
