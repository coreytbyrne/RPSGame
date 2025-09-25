extends Node2D
class_name Rule

@onready var left_target:ObjectTarget = $ObjectTargetLeft
@onready var effect_target:EffectTarget = $EffectTarget
@onready var right_target:ObjectTarget = $ObjectTargetRight

func _ready() -> void:
	left_target.updated_assignment.connect(update_rule_text.bind(false))
	left_target.committed_assignment.connect(update_rule_text.bind(true))
	
	effect_target.updated_assignment.connect(update_rule_text.bind(false))
	effect_target.committed_assignment.connect(update_rule_text.bind(true))
	
	right_target.updated_assignment.connect(update_rule_text.bind(false))
	right_target.committed_assignment.connect(update_rule_text.bind(true))

func update_rule_text(is_commited:bool) -> void:
	var left_assignment:GameplayUtils.OBJECT
	var effect_assignment:GameplayUtils.EFFECT
	var right_assignment:GameplayUtils.OBJECT
	
	var rule_text_color:Color
	
	if is_commited:
		left_assignment= left_target.assignment
		effect_assignment = effect_target.assignment
		right_assignment= right_target.assignment
		rule_text_color = Color.BLACK
	else:
		left_assignment= left_target.temp_assignment
		effect_assignment = effect_target.temp_assignment
		right_assignment= right_target.temp_assignment
		rule_text_color = Color.RED
		
	$RuleText.text = GameplayUtils.get_effect_text(left_assignment, effect_assignment, right_assignment)
	$RuleText.add_theme_color_override("font_color", rule_text_color)
