extends Node2D
class_name PlayedObject

@onready var target:PlugTarget = $PlugTarget
@onready var roller:Roller = $Roller


func _ready() -> void:
	target.data_updated.connect(played_object_updated)



func played_object_updated(data:CartridgeConfig) -> void:
	var update_text:String
	
	if data == null:
		update_text = ""
	else:
		update_text = GameplayUtils.get_object_name(data.object)
	
	#if not roller.is_roller_display_matching(update_text):
	roller.roll(update_text)
