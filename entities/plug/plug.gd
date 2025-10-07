extends Node2D
class_name Plug

@onready var cart_plug_sprite:Sprite2D = $CartridgePlugSprite
@onready var target_plug_sprite:Sprite2D = $TargetPlugSprite
var mouse_follow_sprite:Sprite2D:
	set(value):
		if value != null:
			value.visible = true
		mouse_follow_sprite = value

var connected_cartridge:Cartridge
var connected_target:PlugTarget

var is_circuit_complete:bool = false


func _process(delta: float) -> void:
	if mouse_follow_sprite != null:
		mouse_follow_sprite.position = get_local_mouse_position()


func connect_cartidge(cartridge:Cartridge) -> void:
	connected_cartridge = cartridge
	connected_cartridge.connected_plug = self
	
	cart_plug_sprite.position = cartridge.plug_sprite_position
	cart_plug_sprite.visible = true
	
	# Check if connected to a target already
	if connected_target != null:
		transfer_data()
	else:
		mouse_follow_sprite = target_plug_sprite


func connect_target(target:PlugTarget) -> void:
	connected_target = target
	connected_target.connected_plug = self
	
	target_plug_sprite.position = target.plug_sprite_position
	target_plug_sprite.visible = true
	
	# Check if connected to a cartridge already
	if connected_cartridge != null:
		transfer_data()
	else:
		mouse_follow_sprite = cart_plug_sprite


func transfer_data() -> void:
	is_circuit_complete = true
	mouse_follow_sprite = null
	
	if connected_target.is_disabled || connected_cartridge.is_disabled:
		return
	else:
		connected_target.incoming_data = connected_cartridge.config


func next_round() -> void:
	connected_cartridge.cartridge_used()
	disconnect_cartridge()
	disconnect_target()


func stop_data_transfer() -> void:
	is_circuit_complete = false
	if connected_target != null:
		connected_target.incoming_data = null


func destroy_plug() -> void:
	stop_data_transfer()
	connected_cartridge = null
	connected_target = null
	
	cart_plug_sprite.visible = false
	target_plug_sprite.visible = false
	mouse_follow_sprite = null
	queue_free()


func disconnect_cartridge() -> Plug:
	connected_cartridge.connected_plug = null
	
	connected_cartridge = null
	cart_plug_sprite.visible = false
	stop_data_transfer()
	
	if connected_target != null:
		mouse_follow_sprite = cart_plug_sprite
	else:
		# Nothing is connected, destroy the plug
		queue_free()
		return null
	return self

## Returns true if the plug is still valid, false if it has been destroyed
func disconnect_target() -> Plug:
	stop_data_transfer()
	target_plug_sprite.visible = false
	connected_target.connected_plug = null
	connected_target = null
	
	if connected_cartridge != null:
		mouse_follow_sprite = target_plug_sprite
	else:
		# Nothing is connected, destroy the plug
		queue_free()
		return null
	return self
