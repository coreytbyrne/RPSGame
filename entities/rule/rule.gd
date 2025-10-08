extends Node2D
class_name Rule

@export var rule_config:RuleConfig

@onready var left_target:PlugTarget = $LeftTarget
@onready var effect_target:PlugTarget = $EffectTarget
@onready var right_target:PlugTarget = $RightTarget

@onready var left_roller:Roller = $LeftRoller
@onready var effect_roller:Roller = $EffectRoller
@onready var right_roller:Roller = $RightRoller

@onready var rule_swap:CheckButton = $RuleSwapButton

var rule_intent:Dictionary[RULE_TARGET, RuleUpdateIntent]

var is_new_round:bool = false
var swap_change:int = 100

signal rule_swapped(swap_value_change:int)

enum RULE_CHANGE_TYPE {UPDATE,COMMIT,REVERT}
enum RULE_TARGET {LEFT, RIGHT, EFFECT}

func _ready() -> void:
		# Check if static rule is applicable
	if rule_config.constant_effect != GameplayUtils.EFFECT.NONE:
		$StaticRule/Text.text = GameplayUtils.get_effect_name(rule_config.constant_effect)
		$StaticRule.visible = true
	else:
		$StaticRule.visible = false
	
	rule_intent = {
		RULE_TARGET.LEFT: RuleObjectIntent.new(rule_config.left_object),
		RULE_TARGET.EFFECT: RuleEffectIntent.new(rule_config.effect),
		RULE_TARGET.RIGHT: RuleObjectIntent.new(rule_config.right_object),
	}
	
	await roller_round_reset(RULE_TARGET.LEFT)
	await roller_round_reset(RULE_TARGET.EFFECT)
	await roller_round_reset(RULE_TARGET.RIGHT)
	
	# Connect to signals
	left_target.data_updated.connect(player_rule_intent_update.bind(RULE_TARGET.LEFT))
	effect_target.data_updated.connect(player_rule_intent_update.bind(RULE_TARGET.EFFECT))
	right_target.data_updated.connect(player_rule_intent_update.bind(RULE_TARGET.RIGHT))
	

func toggle_rule_swap_disable(is_disable:bool) -> void:
	# If the rule swap is toggled on, you don't want to prevent the player from
	# toggling it off
	if not $RuleSwapButton.button_pressed:
		$RuleSwapButton.disabled = is_disable


func apply_rule_changes() -> void:
	await update_rolls_for_opponent_actions()
	
	rule_intent[RULE_TARGET.LEFT].new_round()
	rule_config.left_object = rule_intent[RULE_TARGET.LEFT].round_start_rule
	
	rule_intent[RULE_TARGET.EFFECT].new_round()
	rule_config.effect = rule_intent[RULE_TARGET.EFFECT].round_start_rule
	
	rule_intent[RULE_TARGET.RIGHT].new_round()
	rule_config.right_object = rule_intent[RULE_TARGET.RIGHT].round_start_rule
	
	is_new_round = true
	$RuleSwapButton.button_pressed = false
	is_new_round = false


func player_rule_intent_update(update:CartridgeConfig, rule_target:RULE_TARGET) -> void:
	if update != null:
		if rule_target == RULE_TARGET.EFFECT:
			rule_intent[rule_target].player_update_rule = update.effect
			await update_roller(rule_target, GameplayUtils.get_effect_name(update.effect))
		else:
			rule_intent[rule_target].player_update_rule = update.object
			await update_roller(rule_target, GameplayUtils.get_object_name(update.object))
	# Rever the rule
	else:
		if rule_target == RULE_TARGET.EFFECT:
			rule_intent[rule_target].reset_player_rule()
			await update_roller(rule_target, GameplayUtils.get_effect_name(rule_intent[rule_target].round_start_rule))
		else:
			rule_intent[rule_target].reset_player_rule()
			await update_roller(rule_target, GameplayUtils.get_object_name(rule_intent[rule_target].round_start_rule))


func opponent_update(rule_target:RULE_TARGET, update) -> void:
	rule_intent[rule_target].opponent_update_rule = update


func update_rolls_for_opponent_actions() -> void:
	for rule_type:RULE_TARGET in rule_intent.keys():
		#if rule_intent[rule_type].opponent_update_rule != null:
		if not rule_intent[rule_type].is_rule_conflict():
			if rule_type == RULE_TARGET.EFFECT and rule_intent[rule_type].opponent_update_rule != GameplayUtils.EFFECT.NONE:
				await update_roller(rule_type, GameplayUtils.get_effect_name(rule_intent[rule_type].opponent_update_rule))
			elif (rule_type == RULE_TARGET.LEFT or rule_type == RULE_TARGET.RIGHT) \
			and rule_intent[rule_type].opponent_update_rule != GameplayUtils.OBJECT.NONE:
				await update_roller(rule_type, GameplayUtils.get_object_name(rule_intent[rule_type].opponent_update_rule))
		else:
			# If there's a rule conflict, reset the rule to what it was at the start of the round
			await roller_round_reset(rule_type)


func roller_round_reset(associated_roller:RULE_TARGET) -> void:
	if associated_roller == RULE_TARGET.EFFECT:
		await update_roller(associated_roller, GameplayUtils.get_effect_name(rule_intent[associated_roller].round_start_rule))
	else:
		await update_roller(associated_roller, GameplayUtils.get_object_name(rule_intent[associated_roller].round_start_rule))


func update_roller(associated_roller:RULE_TARGET, update_text:String) -> void:
	match(associated_roller):
		RULE_TARGET.LEFT:
			if not left_roller.is_roller_display_matching(update_text):
				await left_roller.roll(update_text)
		RULE_TARGET.EFFECT:
			if not effect_roller.is_roller_display_matching(update_text):
				await effect_roller.roll(update_text)
		RULE_TARGET.RIGHT:
			if not right_roller.is_roller_display_matching(update_text):
				await right_roller.roll(update_text)


func get_current_rule() -> RuleConfig:
	var current_rule:RuleConfig = RuleConfig.new()
	current_rule.left_object = rule_intent[RULE_TARGET.LEFT].round_start_rule
	current_rule.effect = rule_intent[RULE_TARGET.EFFECT].round_start_rule
	current_rule.right_object = rule_intent[RULE_TARGET.RIGHT].round_start_rule
	current_rule.constant_effect = rule_config.constant_effect
	
	rule_config = current_rule
	return current_rule


func rule_triggered_update(is_triggered:bool) -> void:
	$RuleActive.visible = is_triggered


func _on_rule_swap_button_toggled(toggled_on: bool) -> void:
	if is_new_round:
		return
	
	
	var left_obj:GameplayUtils.OBJECT = rule_intent[RULE_TARGET.LEFT].round_start_rule
	var right_obj:GameplayUtils.OBJECT = rule_intent[RULE_TARGET.RIGHT].round_start_rule


	if toggled_on:	
		# Apply the swap for the base objects, then apply player changes
		# If the slot already has an effect, keep that
		if $LeftTarget.connected_plug == null:
			update_roller(RULE_TARGET.LEFT, GameplayUtils.get_object_name(right_obj))
			rule_intent[RULE_TARGET.LEFT].player_update_rule = right_obj
		#else:
		rule_intent[RULE_TARGET.LEFT].round_start_rule = right_obj

		if $RightTarget.connected_plug == null:
			update_roller(RULE_TARGET.RIGHT, GameplayUtils.get_object_name(left_obj))
			rule_intent[RULE_TARGET.RIGHT].player_update_rule = left_obj
		#else:
		rule_intent[RULE_TARGET.RIGHT].round_start_rule = left_obj
		rule_swapped.emit(-swap_change)
	else:

		# If they are the same, the that means a plug is not currently applied
		rule_intent[RULE_TARGET.LEFT].round_start_rule = right_obj
		rule_intent[RULE_TARGET.RIGHT].round_start_rule = left_obj
		
		if $LeftTarget.connected_plug == null:
			rule_intent[RULE_TARGET.LEFT].player_update_rule = GameplayUtils.OBJECT.NONE
			update_roller(RULE_TARGET.LEFT, GameplayUtils.get_object_name(right_obj))
		

		if $RightTarget.connected_plug == null:
			rule_intent[RULE_TARGET.RIGHT].player_update_rule = GameplayUtils.OBJECT.NONE
			update_roller(RULE_TARGET.RIGHT, GameplayUtils.get_object_name(left_obj))
		
		rule_swapped.emit(swap_change)


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
