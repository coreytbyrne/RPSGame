extends Node2D
class_name PlayedObject

@onready var target:ObjectTarget = $ObjectTarget

enum RULE_CHANGE_TYPE {UPDATE,COMMIT,REVERT}

func _ready() -> void:
	target.updated_assignment.connect(update_played_card_slot.bind(RULE_CHANGE_TYPE.UPDATE))
	target.committed_assignment.connect(update_played_card_slot.bind(RULE_CHANGE_TYPE.COMMIT))
	target.reverted_assignment.connect(update_played_card_slot.bind(RULE_CHANGE_TYPE.REVERT))


func clear_played_object() -> void:
	target.assignment = GameplayUtils.OBJECT.NONE
	target.temp_assignment = GameplayUtils.OBJECT.NONE
	target.commit_assignment()


func update_played_card_slot(rule_type:RULE_CHANGE_TYPE) -> void:
	var target_assignment:GameplayUtils.OBJECT
	var target_color:Color
	
	if rule_type == RULE_CHANGE_TYPE.COMMIT:
		target_assignment = target.assignment
		target_color = Color.WHITE
	elif rule_type == RULE_CHANGE_TYPE.UPDATE:
		target_assignment = target.temp_assignment
		target_color = Color.RED
	
	# From the perspective of a rule, Revert is the same as Commit currently
	# Keeping these separate so that the visuals/audio fx can be kept unique later
	elif rule_type == RULE_CHANGE_TYPE.REVERT:
		target_assignment = target.assignment
		target_color = Color.WHITE
	
	# If the object name is "None", that means we disconnected. For a
	# played object slot, we don't want to display any text for "None"
	var update_text:String = GameplayUtils.get_object_name(target_assignment)
	if update_text.to_lower() == "none":
		update_text = ""
	
	$PlayedCardText.text = update_text
	$PlayedCardText.add_theme_color_override("font_color", target_color)
	
	# Need to deffer the signal emission b/c emitting blocks until connected nodes finish
	# running their functions. Hence, we get stuck in a loop
	(func():SignalBus.rule_updated.emit()).call_deferred()


func get_played_object() -> GameplayUtils.OBJECT:
	return target.assignment
