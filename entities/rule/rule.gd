extends Node2D
class_name Rule

@export var rule_config:RuleConfig

@onready var left_target:PlugTarget = $LeftTarget
@onready var effect_target:PlugTarget = $EffectTarget
@onready var right_target:PlugTarget = $RightTarget

@onready var left_roller:Roller = $LeftRoller
@onready var effect_roller:Roller = $EffectRoller
@onready var right_roller:Roller = $RightRoller

var rule_intent:Dictionary[RULE_TARGET, RuleUpdateIntent]

enum RULE_CHANGE_TYPE {UPDATE,COMMIT,REVERT}
enum RULE_TARGET {LEFT, RIGHT, EFFECT}

func _ready() -> void:
	rule_intent = {
		RULE_TARGET.LEFT: RuleObjectIntent.new(rule_config.left_object),
		RULE_TARGET.EFFECT: RuleEffectIntent.new(rule_config.effect),
		RULE_TARGET.RIGHT: RuleObjectIntent.new(rule_config.right_object),
	}
	
	roller_round_reset(RULE_TARGET.LEFT)
	roller_round_reset(RULE_TARGET.EFFECT)
	roller_round_reset(RULE_TARGET.RIGHT)
	
	# Connect to signals
	left_target.data_updated.connect(player_rule_intent_update.bind(RULE_TARGET.LEFT))
	effect_target.data_updated.connect(player_rule_intent_update.bind(RULE_TARGET.EFFECT))
	right_target.data_updated.connect(player_rule_intent_update.bind(RULE_TARGET.RIGHT))
	
	
	# Check if static rule is applicable
	if rule_config.constant_effect != GameplayUtils.EFFECT.NONE:
		$StaticRule/Text.text = GameplayUtils.get_effect_name(rule_config.constant_effect)
		$StaticRule.visible = true
	else:
		$StaticRule.visible = false


func end_round() -> void:
	apply_opponent_roll_updates()
	for rule_type:RULE_TARGET in rule_intent.keys():
		rule_intent[rule_type].new_round()


func player_rule_intent_update(update:CartridgeConfig, rule_target:RULE_TARGET) -> void:

	if update != null:
		if rule_target == RULE_TARGET.EFFECT:
			rule_intent[rule_target].player_update_rule = update.effect
			update_roller(rule_target, GameplayUtils.get_effect_name(update.effect))
		else:
			rule_intent[rule_target].player_update_rule = update.object
			update_roller(rule_target, GameplayUtils.get_object_name(update.object))
	# Rever the rule
	else:
		if rule_target == RULE_TARGET.EFFECT:
			rule_intent[rule_target].reset_player_rule()
			update_roller(rule_target, GameplayUtils.get_effect_name(rule_intent[rule_target].round_start_rule))
		else:
			rule_intent[rule_target].reset_player_rule()
			update_roller(rule_target, GameplayUtils.get_object_name(rule_intent[rule_target].round_start_rule))

func opponent_update(rule_target:RULE_TARGET, update) -> void:
	rule_intent[rule_target].opponent_update_rule = update


func apply_opponent_roll_updates() -> void:
	for rule_type:RULE_TARGET in rule_intent.keys():
		if rule_intent[rule_type].opponent_update_rule != null:
			if not rule_intent[rule_type].is_rule_conflict():
				if rule_type == RULE_TARGET.EFFECT:
					update_roller(rule_type, GameplayUtils.get_effect_name(rule_intent[rule_type].opponent_update_rule))
				else:
					update_roller(rule_type, GameplayUtils.get_object_name(rule_intent[rule_type].opponent_update_rule))
			else:
				# If there's a rule conflict, reset the rule to what it was at the start of the round
				roller_round_reset(rule_type)


func roller_round_reset(associated_roller:RULE_TARGET) -> void:
	if associated_roller == RULE_TARGET.EFFECT:
		update_roller(associated_roller, GameplayUtils.get_effect_name(rule_intent[associated_roller].round_start_rule))
	else:
		update_roller(associated_roller, GameplayUtils.get_object_name(rule_intent[associated_roller].round_start_rule))


func update_roller(associated_roller:RULE_TARGET, update_text:String) -> void:
	match(associated_roller):
		RULE_TARGET.LEFT:
			if not left_roller.is_roller_display_matching(update_text):
				left_roller.roll(update_text)
		RULE_TARGET.EFFECT:
			if not effect_roller.is_roller_display_matching(update_text):
				effect_roller.roll(update_text)
		RULE_TARGET.RIGHT:
			if not right_roller.is_roller_display_matching(update_text):
				right_roller.roll(update_text)


func get_current_rule() -> RuleConfig:
	var current_rule:RuleConfig = RuleConfig.new()
	current_rule.left_object = rule_intent[RULE_TARGET.LEFT].round_start_rule
	current_rule.effect = rule_intent[RULE_TARGET.EFFECT].round_start_rule
	current_rule.right_object = rule_intent[RULE_TARGET.RIGHT].round_start_rule
	current_rule.constant_effect = rule_config.constant_effect
	
	return current_rule

####################### Internal Classes #######################
class RuleUpdateIntent:
	pass


class RuleObjectIntent extends RuleUpdateIntent:
	var initial_rule:GameplayUtils.OBJECT
	var round_start_rule:GameplayUtils.OBJECT
	var player_update_rule:GameplayUtils.OBJECT
	var opponent_update_rule:GameplayUtils.OBJECT
	
	func _init(init_rule:GameplayUtils.OBJECT) -> void:
		initial_rule = init_rule
		round_start_rule = init_rule
		new_round()
	
	func new_round() -> void:
		if not is_rule_conflict():
			if player_update_rule != GameplayUtils.OBJECT.NONE:
				round_start_rule = player_update_rule
			elif opponent_update_rule != GameplayUtils.OBJECT.NONE:
				round_start_rule = opponent_update_rule
		player_update_rule = GameplayUtils.OBJECT.NONE
		opponent_update_rule = GameplayUtils.OBJECT.NONE
	
	func is_rule_conflict() -> bool:
		return ( (player_update_rule != GameplayUtils.OBJECT.NONE) and (opponent_update_rule != GameplayUtils.OBJECT.NONE) )

	func reset_player_rule() -> void:
		player_update_rule = GameplayUtils.OBJECT.NONE


class RuleEffectIntent extends RuleUpdateIntent:
	var initial_rule:GameplayUtils.EFFECT
	var round_start_rule:GameplayUtils.EFFECT
	var player_update_rule:GameplayUtils.EFFECT
	var opponent_update_rule:GameplayUtils.EFFECT
	
	func _init(init_rule:GameplayUtils.EFFECT) -> void:
		initial_rule = init_rule
		round_start_rule = init_rule
		new_round()
	
	func new_round() -> void:
		if not is_rule_conflict():
			if player_update_rule != GameplayUtils.EFFECT.NONE:
				round_start_rule = player_update_rule
			elif opponent_update_rule != GameplayUtils.EFFECT.NONE:
				round_start_rule = opponent_update_rule
		player_update_rule = GameplayUtils.EFFECT.NONE
		opponent_update_rule = GameplayUtils.EFFECT.NONE
	
	func reset_player_rule() -> void:
		player_update_rule = GameplayUtils.EFFECT.NONE
	
	func is_rule_conflict() -> bool:
		return ( (player_update_rule != GameplayUtils.EFFECT.NONE) and (opponent_update_rule != GameplayUtils.EFFECT.NONE) )
