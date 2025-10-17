extends Node2D
class_name PlayedObject

@onready var target:PlugTarget = $PlugTarget
@onready var spinner:SpinnerWord = $SpinnerWord
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

	if not spinner.is_word_matching(update_text):
		await spinner.update_word(update_text, 1, 5)
	
