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

var is_new_round:bool
var swap_change:int = 100

signal rule_swapped(swap_value_change:int)

#enum RULE_CHANGE_TYPE {UPDATE,COMMIT,REVERT}
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
	
	await update_all_rollers()
	
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
	await update_all_rollers()
	
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
			rule_intent[rule_target].participant_intent_add(Participant.TYPE.PLAYER, update.effect)
			await update_roller(rule_target, GameplayUtils.get_effect_name(update.effect))
		else:
			rule_intent[rule_target].participant_intent_add(Participant.TYPE.PLAYER, update.object)
			await update_roller(rule_target, GameplayUtils.get_object_name(update.object))
	# Rever the rule
	else:
		rule_intent[rule_target].participant_intent_remove(Participant.TYPE.PLAYER)
		
		if rule_target == RULE_TARGET.EFFECT:
			await update_roller(rule_target, GameplayUtils.get_effect_name(rule_intent[rule_target].determine_rule_update()))
		else:
			await update_roller(rule_target, GameplayUtils.get_object_name(rule_intent[rule_target].determine_rule_update()))


func opponent_update(rule_target:RULE_TARGET, update) -> void:
	rule_intent[rule_target].participant_intent_add(Participant.TYPE.OPPONENT, update)


func opponent_swap() -> void:
	rule_intent[RULE_TARGET.LEFT].rule_swap(Participant.TYPE.OPPONENT, rule_intent[RULE_TARGET.RIGHT])
	rule_intent[RULE_TARGET.RIGHT].rule_swap(Participant.TYPE.OPPONENT, rule_intent[RULE_TARGET.LEFT])
	


func update_all_rollers() -> void:
	
	await update_roller(RULE_TARGET.LEFT, GameplayUtils.get_object_name(rule_intent[RULE_TARGET.LEFT].determine_rule_update()))
	await update_roller(RULE_TARGET.EFFECT, GameplayUtils.get_effect_name(rule_intent[RULE_TARGET.EFFECT].determine_rule_update()))
	await update_roller(RULE_TARGET.RIGHT, GameplayUtils.get_object_name(rule_intent[RULE_TARGET.RIGHT].determine_rule_update()))
	
	


#func roller_round_reset(associated_roller:RULE_TARGET) -> void:
	#if associated_roller == RULE_TARGET.EFFECT:
		#await update_roller(associated_roller, GameplayUtils.get_effect_name(rule_intent[associated_roller].round_start_rule))
	#else:
		#await update_roller(associated_roller, GameplayUtils.get_object_name(rule_intent[associated_roller].round_start_rule))


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
	
	if toggled_on: 
		rule_intent[RULE_TARGET.LEFT].rule_swap(Participant.TYPE.PLAYER, rule_intent[RULE_TARGET.RIGHT])
		rule_intent[RULE_TARGET.RIGHT].rule_swap(Participant.TYPE.PLAYER, rule_intent[RULE_TARGET.LEFT])
		await update_all_rollers()
		rule_swapped.emit(-swap_change)
	else:
		rule_intent[RULE_TARGET.LEFT].player_rule_swap_revert()
		rule_intent[RULE_TARGET.RIGHT].player_rule_swap_revert()
		await update_all_rollers()
		rule_swapped.emit(swap_change)
	

####################### Internal Classes #######################
class RuleUpdateIntent:
	pass


class RuleObjectIntent extends RuleUpdateIntent:
	var initial_rule:GameplayUtils.OBJECT
	var round_start_rule:GameplayUtils.OBJECT

	var _player_update_rule:GameplayUtils.OBJECT
	var _opponent_update_rule:GameplayUtils.OBJECT
	
	var _is_player_swap:bool = false
	var _is_opponent_swap:bool = false
	var _swap_update_rule:GameplayUtils.OBJECT
	
	func _init(init_rule:GameplayUtils.OBJECT) -> void:
		initial_rule = init_rule
		round_start_rule = init_rule
		new_round()
	
	func new_round() -> void:
		round_start_rule = determine_rule_update()
		_player_update_rule = GameplayUtils.OBJECT.NONE
		_opponent_update_rule = GameplayUtils.OBJECT.NONE
		_swap_update_rule = GameplayUtils.OBJECT.NONE
	
	func rule_swap(participant_type:Participant.TYPE, other_rule:RuleObjectIntent) -> void:
		if participant_type == Participant.TYPE.PLAYER:
			_is_player_swap = true
		else:
			_is_opponent_swap = true
		
		# If both are targeting the same rule for swap, it effectively negates it
		if _is_player_swap and _is_opponent_swap:

			if other_rule._player_update_rule != GameplayUtils.OBJECT.NONE:
				_swap_update_rule = other_rule._player_update_rule
			else:
				_swap_update_rule = round_start_rule
			
		else:
			# If the opponent is swapping, the player's action should get swapped too
			if _is_opponent_swap and other_rule._player_update_rule != GameplayUtils.OBJECT.NONE:
				_swap_update_rule = other_rule._player_update_rule
			else:
				_swap_update_rule = other_rule.round_start_rule
	
	# Realistically, only the player will revert a swap. This will happen before an Opponent's turn
	func player_rule_swap_revert() -> void:
		_is_player_swap = false
		_swap_update_rule = GameplayUtils.OBJECT.NONE

	
	func participant_intent_add(participant_type:Participant.TYPE, object:GameplayUtils.OBJECT) -> void:
		if participant_type == Participant.TYPE.PLAYER:
			_player_update_rule = object
		else:
			_opponent_update_rule = object
		
		
	func participant_intent_remove(participant_type:Participant.TYPE) -> void:
		if participant_type == Participant.TYPE.PLAYER:
			_player_update_rule = GameplayUtils.OBJECT.NONE
		else:
			_opponent_update_rule = GameplayUtils.OBJECT.NONE
	
	
	
	func determine_rule_update() -> GameplayUtils.OBJECT:
		# Scenario: Rule conflict, no swap
		# Result: Conflicting rules cancel out
		if is_rule_conflict() and _swap_update_rule == GameplayUtils.OBJECT.NONE:
			return round_start_rule
		
		# Scenario: Rule Conflict, but there is a swap.
		# Result: Conflictin rules cancel out, but the swap is still applied
		if is_rule_conflict() and _swap_update_rule != GameplayUtils.OBJECT.NONE:
			return _swap_update_rule
		
		# Scenario: The player made an update, then the opponent swapped the rule
		# Result: The Swap occurs AFTER the player's update, swapping its position
		if _player_update_rule != GameplayUtils.OBJECT.NONE:
			if _swap_update_rule != GameplayUtils.OBJECT.NONE and _is_opponent_swap:
				return _swap_update_rule
			else:
				# Scenario: No Rule conflict, player played a rule (regardless of swap)
				# Result: Player's rule applied
				return _player_update_rule
		
		
		# Scenario: No Rule conflict, opponent played a rule (regardless of swap)
		# Result: Opponent's rule applied
		if _opponent_update_rule != GameplayUtils.OBJECT.NONE:
			return _opponent_update_rule
		
		# Scenario: Neither player has played a bespoke rule update, but a swap was played
		# Result: Swap applied
		if _swap_update_rule != GameplayUtils.OBJECT.NONE:
			return _swap_update_rule
		


		
		return round_start_rule
	
	func is_rule_conflict() -> bool:
		return ( (_player_update_rule != GameplayUtils.OBJECT.NONE) and (_opponent_update_rule != GameplayUtils.OBJECT.NONE))


class RuleEffectIntent extends RuleUpdateIntent:
	var initial_rule:GameplayUtils.EFFECT
	var round_start_rule:GameplayUtils.EFFECT
	var _player_update_rule:GameplayUtils.EFFECT
	var _opponent_update_rule:GameplayUtils.EFFECT
	
	func _init(init_rule:GameplayUtils.EFFECT) -> void:
		initial_rule = init_rule
		round_start_rule = init_rule
		new_round()
	
	func new_round() -> void:
		round_start_rule = determine_rule_update()
		#if not is_rule_conflict():
			#if _player_update_rule != GameplayUtils.EFFECT.NONE:
				#round_start_rule = _player_update_rule
			#elif _opponent_update_rule != GameplayUtils.EFFECT.NONE:
				#round_start_rule = _opponent_update_rule
		_player_update_rule = GameplayUtils.EFFECT.NONE
		_opponent_update_rule = GameplayUtils.EFFECT.NONE
	
	func participant_intent_add(participant_type:Participant.TYPE, object:GameplayUtils.EFFECT) -> void:
		if participant_type == Participant.TYPE.PLAYER:
			_player_update_rule = object
		else:
			_opponent_update_rule = object
		
		
	func participant_intent_remove(participant_type:Participant.TYPE) -> void:
		if participant_type == Participant.TYPE.PLAYER:
			_player_update_rule = GameplayUtils.EFFECT.NONE
		else:
			_opponent_update_rule = GameplayUtils.EFFECT.NONE
	
	
	
	func determine_rule_update() -> GameplayUtils.EFFECT:
		# Scenario: Rule conflict, no swap
		# Result: Conflicting rules cancel out
		if is_rule_conflict():
			return round_start_rule
		# Scenario: No Rule conflict, player played a rule (regardless of swap)
		# Result: Player's rule applied
		if _player_update_rule != GameplayUtils.EFFECT.NONE:
			return _player_update_rule
		
		# Scenario: No Rule conflict, opponent played a rule (regardless of swap)
		# Result: Opponent's rule applied
		if _opponent_update_rule != GameplayUtils.EFFECT.NONE:
			return _opponent_update_rule
		
		
		return round_start_rule
	
	func is_rule_conflict() -> bool:
		return ( (_player_update_rule != GameplayUtils.EFFECT.NONE) and (_opponent_update_rule != GameplayUtils.EFFECT.NONE) )
