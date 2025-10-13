extends Node2D
class_name Plug

@onready var transmitter_plug_sprite:Sprite2D = $TransmitterPlugSprite
@onready var target_plug_sprite:Sprite2D = $TargetPlugSprite
var mouse_follow_sprite:Sprite2D:
	set(value):
		if value != null:
			value.visible = true
		mouse_follow_sprite = value

var connected_transmitter:Transmitter
var connected_target:PlugTarget

var is_circuit_complete:bool = false


func _process(delta: float) -> void:
	if mouse_follow_sprite != null:
		mouse_follow_sprite.position = get_local_mouse_position()


func connect_transmitter(transmitter:Transmitter) -> void:
	if transmitter.is_disabled:
		return
		
	connected_transmitter = transmitter
	connected_transmitter.connected_plug = self
	
	transmitter_plug_sprite.position = transmitter.plug_sprite_position
	transmitter_plug_sprite.visible = true
	
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
	
	# Check if connected to a transmitter already
	if connected_transmitter != null:
		transfer_data()
	else:
		mouse_follow_sprite = transmitter_plug_sprite


func transfer_data() -> void:
	is_circuit_complete = true
	mouse_follow_sprite = null
	
	if connected_target.is_disabled || connected_transmitter.is_disabled:
		return
	else:
		connected_target.incoming_data = connected_transmitter.config


func next_round() -> void:
	connected_transmitter.transmitter_used()
	disconnect_transmitter()
	disconnect_target()


func stop_data_transfer() -> void:
	is_circuit_complete = false
	if connected_target != null:
		connected_target.incoming_data = null


func destroy_plug() -> void:
	stop_data_transfer()
	connected_transmitter = null
	connected_target = null
	
	transmitter_plug_sprite.visible = false
	target_plug_sprite.visible = false
	mouse_follow_sprite = null
	queue_free()


func disconnect_transmitter() -> Plug:
	connected_transmitter.connected_plug = null
	
	connected_transmitter = null
	transmitter_plug_sprite.visible = false
	stop_data_transfer()
	
	if connected_target != null:
		mouse_follow_sprite = transmitter_plug_sprite
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
	
	if connected_transmitter != null:
		mouse_follow_sprite = target_plug_sprite
	else:
		# Nothing is connected, destroy the plug
		queue_free()
		return null
	return self
