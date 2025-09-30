extends Node2D
class_name Rule

@export var rule_config:RuleConfig

@onready var left_target:ObjectTarget = $ObjectTargetLeft
@onready var effect_target:EffectTarget = $EffectTarget
@onready var right_target:ObjectTarget = $ObjectTargetRight

enum RULE_CHANGE_TYPE {UPDATE,COMMIT,REVERT}
enum RULE_TARGET {LEFT, RIGHT, EFFECT}

func _ready() -> void:
	
	left_target.updated_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.UPDATE))
	left_target.committed_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.COMMIT))
	left_target.reverted_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.REVERT))
	
	left_target.set_initial_assignment(rule_config.left_object)
	
	effect_target.updated_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.UPDATE))
	effect_target.committed_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.COMMIT))
	effect_target.reverted_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.REVERT))
	effect_target.set_initial_assignment(rule_config.effect)
	
	right_target.updated_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.UPDATE))
	right_target.committed_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.COMMIT))
	right_target.reverted_assignment.connect(update_rule_text.bind(RULE_CHANGE_TYPE.REVERT))
	right_target.set_initial_assignment(rule_config.right_object)


func update_rule_text(rule_type:RULE_CHANGE_TYPE) -> void:
	var left_assignment:GameplayUtils.OBJECT
	var effect_assignment:GameplayUtils.EFFECT
	var right_assignment:GameplayUtils.OBJECT
	
	var rule_text_color:Color
	
	if rule_type == RULE_CHANGE_TYPE.COMMIT:
		left_assignment= left_target.assignment
		effect_assignment = effect_target.assignment
		right_assignment= right_target.assignment
		rule_text_color = Color.WHITE
	elif rule_type == RULE_CHANGE_TYPE.UPDATE:
		left_assignment= left_target.temp_assignment
		effect_assignment = effect_target.temp_assignment
		right_assignment= right_target.temp_assignment
		rule_text_color = Color.RED
	# From the perspective of a rule, Revert is the same as Commit currently
	# Keeping these separate so that the visuals/audio fx can be kept unique later
	elif rule_type == RULE_CHANGE_TYPE.REVERT:
		left_assignment= left_target.assignment
		effect_assignment = effect_target.assignment
		right_assignment= right_target.assignment
		rule_text_color = Color.WHITE
		
	$RuleText.text = GameplayUtils.get_effect_text(left_assignment, effect_assignment, right_assignment)
	$RuleText.add_theme_color_override("font_color", rule_text_color)
	
	# Need to deffer the signal emission b/c emitting blocks until connected nodes finish
	# running their functions. Hence, we get stuck in a loop
	(func():SignalBus.rule_updated.emit()).call_deferred()


func get_current_rule() -> RuleConfig:
	var current_rule:RuleConfig = RuleConfig.new()
	current_rule.left_object = left_target.assignment
	current_rule.effect = effect_target.assignment
	current_rule.right_object = right_target.assignment
	
	return current_rule
