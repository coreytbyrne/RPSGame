extends Node
class_name Cartridge

@export var config:CartridgeConfig

var connected_plug:Plug
var is_disabled:bool = false
var cooldown:int = 0
var cooldown_count:int:
	set(value):
		if value > 0:
			disable_cartridge()
		else:
			enable_cartridge()
			value = 0
		cooldown_count = value

var plug_sprite_position:Vector2

signal cart_plug_slot_hovered(cart:Cartridge)

func _ready() -> void:
	$CartridgeLabel.text = GameplayUtils.get_object_name(config.object)
	cooldown = config.base_cooldown
	plug_sprite_position = $PlugSlot.global_position


func cartridge_used() -> void:
	if cooldown > 0:
		cooldown_count = cooldown


func next_round() -> void:
	if cooldown_count > 0:
		cooldown_count -= 1


func disable_cartridge() -> void:
	$CartridgeLabel.text = "DISABLED\n%s" % [GameplayUtils.get_object_name(config.object)]
	is_disabled = true


func enable_cartridge() -> void:
	$CartridgeLabel.text = "%s" % [GameplayUtils.get_object_name(config.object)]
	is_disabled = false


func _on_plug_slot_mouse_entered() -> void:
	cart_plug_slot_hovered.emit(self)


func _on_plug_slot_mouse_exited() -> void:
	cart_plug_slot_hovered.emit(null)
