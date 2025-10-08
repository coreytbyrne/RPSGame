extends Node2D
class_name PlayedObject

@onready var target:PlugTarget = $PlugTarget
@onready var roller:Roller = $Roller
var played_object:GameplayUtils.OBJECT


func _ready() -> void:
	target.data_updated.connect(played_object_updated)
	played_object = GameplayUtils.OBJECT.NONE



func played_object_updated(data:CartridgeConfig) -> void:
	var update_text:String
	
	if data == null:
		update_text = ""
		played_object = GameplayUtils.OBJECT.NONE
	else:
		update_text = GameplayUtils.get_object_name(data.object)
		played_object = data.object
	#if not roller.is_roller_display_matching(update_text):
	await roller.roll(update_text)
	
