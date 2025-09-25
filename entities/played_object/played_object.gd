extends Node2D
class_name PlayedObject

@onready var target:ObjectTarget = $ObjectTarget

func _ready() -> void:
	target.updated_assignment.connect(update_played_card_slot.bind(false))
	target.committed_assignment.connect(update_played_card_slot.bind(true))


func update_played_card_slot(is_commited:bool) -> void:
	var target_assignment:GameplayUtils.OBJECT
	var target_color:Color
	
	if is_commited:
		target_assignment = target.assignment
		target_color = Color.BLACK
	else:
		target_assignment = target.temp_assignment
		target_color = Color.RED
		
	$PlayedCardText.text = GameplayUtils.get_object_name(target_assignment)
	$PlayedCardText.add_theme_color_override("font_color", target_color)
