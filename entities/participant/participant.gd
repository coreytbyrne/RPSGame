@abstract class_name Participant
extends Node2D

@export var spinner_dose_node_scene:PackedScene
@export var spinner_word_scene:PackedScene
@export var spinner_status_scene:PackedScene
@export var participant_name:String

@onready var dosage:int = 0:
	set(value):
		spinner_dose_node.update_dose_value(value)
		dosage = value

@onready var max_dosage:int = 5:
	set(value):
		spinner_dose_node.max_dose = value
		max_dosage = value

var spinner_dose_node:SpinnerDose
var spinner_name_node:SpinnerWord
var spinner_status_node:SpinnerStatus

# Variables for tracking specific effects
var plug_count_modifier:int = 0
var is_shielded:bool = false :
	set(value):
		spinner_status_node.update_status_value(SpinnerStatus.STATUS.SHIELD, value)
		is_shielded = value
var has_reverse:bool = false:
	set(value): 
		spinner_status_node.update_status_value(SpinnerStatus.STATUS.REVERSE, value)
		has_reverse = value
var play_history:Dictionary[GameplayUtils.OBJECT, int]

enum TYPE {PLAYER, OPPONENT}

func _ready() -> void:
	spinner_dose_node = spinner_dose_node_scene.instantiate()
	spinner_dose_node.max_dose = max_dosage
	
	add_child(spinner_dose_node)
	spinner_dose_node.update_dose_value(dosage)
	
	spinner_name_node = spinner_word_scene.instantiate()
	spinner_name_node.word_max_length = len(participant_name)
	add_child(spinner_name_node)
	spinner_name_node.update_word(participant_name)

	spinner_status_node = spinner_status_scene.instantiate()
	add_child(spinner_status_node)


func add_to_play_history(obj:GameplayUtils.OBJECT) -> void:
	var current_count:int = play_history.get_or_add(obj, 0)
	play_history[obj] = current_count + 1
