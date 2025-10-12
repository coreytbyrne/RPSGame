@abstract class_name Participant
extends Node2D

@export var health:int = 5:
	set(value):
		if self is Player:
			$HP.text = "HP: %d" % value
		health = value
@export var participant_name:String

# Variables for tracking specific effects
var plug_count_modifier:int = 0
var is_shielded:bool = false
var has_reverse:bool = false

enum TYPE {PLAYER, OPPONENT}
