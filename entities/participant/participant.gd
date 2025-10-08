@abstract class_name Participant
extends Node2D

@export var health:int = 5:
	set(value):
		if self is Player:
			$HP.text = "HP: %d" % value
		health = value
@export var participant_name:String

var plug_count_modifier:int = 0
