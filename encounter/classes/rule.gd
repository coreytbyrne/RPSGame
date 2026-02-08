class_name Rule
extends Resource

# Winnig/losing type will often only have a single type associated, but they
# CAN have multiple
var winning_type:Array[ConUtil.BUTTON_TYPE]
var losing_type:Array[ConUtil.BUTTON_TYPE]
var effect:ConUtil.BUTTON_EFFECT

var staged_updates:Dictionary[EnUtil.RULE_COMPONENT, Array] = \
{
	EnUtil.RULE_COMPONENT.WIN: [],
	EnUtil.RULE_COMPONENT.LOSE: [],
	EnUtil.RULE_COMPONENT.EFFECT: []
}

func stage_update(edit_target:EnUtil.RULE_COMPONENT, button_used:ConsoleButton) -> void:
	staged_updates[edit_target].append(button_used)

## When more than 1 update is being applied to the same component of a rule, 
## the rule will split into 2 rules. Even if there are multiple conflicts, 
## only 1 new rule is generated

func apply_changes() -> Rule:
	
	# First, apply rules changes where no multi-edit conflicts occur
	if staged_updates[EnUtil.RULE_COMPONENT.WIN].size() == 1:
		winning_type = staged_updates[EnUtil.RULE_COMPONENT.WIN][0].types

	if staged_updates[EnUtil.RULE_COMPONENT.LOSE].size() == 1:
		losing_type = staged_updates[EnUtil.RULE_COMPONENT.LOSE][0].types

	if staged_updates[EnUtil.RULE_COMPONENT.EFFECT].size() == 1:
		effect = staged_updates[EnUtil.RULE_COMPONENT.EFFECT][0].effect
	
	# Next check for multiple edits to a single rule component. If there are, new
	# rules should be created
	var new_rule:Rule = null
	var is_win_split:bool = (staged_updates[EnUtil.RULE_COMPONENT.WIN].size() == 2)
	var is_lose_split:bool = (staged_updates[EnUtil.RULE_COMPONENT.LOSE].size() == 2)
	var is_effect_split:bool = (staged_updates[EnUtil.RULE_COMPONENT.EFFECT].size() == 2)

	if (is_win_split || is_lose_split || is_effect_split):
		new_rule = self.duplicate(true)
		
		if is_win_split:
			winning_type = staged_updates[EnUtil.RULE_COMPONENT.WIN][0]
			new_rule.winning_type = staged_updates[EnUtil.RULE_COMPONENT.WIN][0]
		if is_lose_split:
			losing_type = staged_updates[EnUtil.RULE_COMPONENT.LOSE][0]
			new_rule.losing_type = staged_updates[EnUtil.RULE_COMPONENT.LOSE][0]
		if is_effect_split:
			effect = staged_updates[EnUtil.RULE_COMPONENT.EFFECT][0]
			new_rule.effect = staged_updates[EnUtil.RULE_COMPONENT.EFFECT][0]
	
	clear_staged_updates()
	return new_rule


func clear_staged_updates() -> void:
	staged_updates[EnUtil.RULE_COMPONENT.WIN].clear()
	staged_updates[EnUtil.RULE_COMPONENT.LOSE].clear()
	staged_updates[EnUtil.RULE_COMPONENT.EFFECT].clear()


func check_if_triggered(
	type_set_1:Array[ConUtil.BUTTON_TYPE], type_set_2:Array[ConUtil.BUTTON_TYPE]
) -> bool:
	for type1:ConUtil.BUTTON_TYPE in type_set_1:
		if winning_type.has(type1):
			for type2:ConUtil.BUTTON_TYPE in type_set_2:
				if losing_type.has(type2):
					return true
		elif losing_type.has(type1):
			for type2:ConUtil.BUTTON_TYPE in type_set_2:
				if winning_type.has(type2):
					return true
	
	return false
