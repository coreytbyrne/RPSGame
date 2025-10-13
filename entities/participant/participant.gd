@abstract class_name Participant
extends Node2D

@export var dosage:int = 0:
	set(value):
		if self is Player:
			$Dose.text = "Dose: %d / %d" % [value, max_dosage]
		dosage = value

@export var max_dosage:int = 5

@export var participant_name:String

# Variables for tracking specific effects
var plug_count_modifier:int = 0
var is_shielded:bool = false
var has_reverse:bool = false
var play_history:Dictionary[GameplayUtils.OBJECT, int]

enum TYPE {PLAYER, OPPONENT}


func add_to_play_history(obj:GameplayUtils.OBJECT) -> void:
	var current_count:int = play_history.get_or_add(obj, 0)
	play_history[obj] = current_count + 1
