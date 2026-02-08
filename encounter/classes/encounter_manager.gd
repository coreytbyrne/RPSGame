class_name EncounterManager
extends Node

'''
Class responsible for acting as a proctor between players and the game state. 
Players submit actions to the encounter manager, then the encounter manager
acts on them / sends them to the rule resolution engine to get "effects." This class
will then send any updates the players need to make back to them.
'''

# Dictionary has a key for each player, then their corresponding set of Actions
var pending_actions:Dictionary[EnUtil.PLAYER, Array]
var action_history:Array[Dictionary]
var rules:Array[Rule]

func receive_actions(player:EnUtil.PLAYER, action_list:Array[PlayerAction]) -> void:
	pending_actions[player] = action_list
	
	# Both players have submitted their actions
	if len(pending_actions.keys()) == 2:
		submit_actions()


func submit_actions() -> void:
	var play_actions:Dictionary[EnUtil.PLAYER, PlayerPlayAction]
	
	# Apply Rule edits first
	for player:EnUtil.PLAYER in pending_actions.keys():
		for action:PlayerAction in pending_actions[player]:
			if action is PlayerEditAction:
				rules[action.target_rule_num].stage_update(action.edit_type, action.button_used)
			elif action is PlayerPlayAction:
				play_actions[player] = action
	
	for rule:Rule in rules:
		var new_rule:Rule = rule.apply_changes()
		if new_rule != null:
			add_rule(rule)

	RuleResolver.generate_effects(play_actions, rules)

#func check_for_triggered_rules(play_actions:Array[PlayerPlayAction]) -> Array[Rule]:
	#var triggered_rules:Array[Rule] = []
	#
	#for rule:Rule in rules:
		#if rule.check_if_triggered(play_actions[0].button_used.types, play_actions[1].button_used.types):
			#triggered_rules.append(rule)
	#
	#return triggered_rules


func add_rule(new_rule:Rule) -> void:
	rules.append(new_rule)
