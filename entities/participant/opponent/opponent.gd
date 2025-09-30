extends Participant
class_name Opponent

@export var preferences:OpponentPreferences
@export var played_object:GameplayUtils.OBJECT

var buttons:Array[ButtonConfig]
var default_wire_count:int :
	set(value):
		default_wire_count = value
		current_wire_count = value
var current_wire_count:int
var rule_board_reference:RulesBoard
var player_history:Dictionary[GameplayUtils.OBJECT, int]


func get_played_object() -> GameplayUtils.OBJECT:
	return played_object


func get_current_rules() -> Array[RuleConfig]:
	return rule_board_reference.get_current_rules()


func generate_rules() -> Array[ActionSequence]:
	var all_actions:Array[ActionSequence]
	var rule_list:Dictionary[int, Array]
	
	for button:ButtonConfig in buttons:
		var play_object:PlayAction = PlayAction.new()
		play_object.obj = button.object_name
		
		var action_sequence:ActionSequence = ActionSequence.new(1)
		action_sequence.add_action(play_object)
		
		# Determine Action length	
		var num_actions:int = mini(current_wire_count - 1, buttons.size() - 1)
		var remaining_buttons:Array[ButtonConfig] = buttons.duplicate()
		remaining_buttons.pop_at(remaining_buttons.find(button))
		
		for rule_num:int in range(get_current_rules().size()):
			rule_list[rule_num] = [Rule.RULE_TARGET.LEFT, Rule.RULE_TARGET.RIGHT, Rule.RULE_TARGET.EFFECT]
			
		var temp_sequence:Array[ActionSequence]
		generate_rule_update_list([action_sequence], remaining_buttons, rule_list, num_actions, temp_sequence)
		
		all_actions.append_array(temp_sequence)
		
	return all_actions


func generate_rule_update_list(action_sequence_list:Array[ActionSequence], remaining_buttons:Array[ButtonConfig], remaining_rules:Dictionary[int,Array], actions_to_add:int, end_list:Array[ActionSequence]) -> void:
	end_list.append_array(action_sequence_list)
	
	if actions_to_add <= 0:
		return
	
	for button:ButtonConfig in remaining_buttons:
		for rule_num:int in remaining_rules.keys():
			var remaining_rule_targets:Array = remaining_rules[rule_num]
			var next_buttons:Array[ButtonConfig] = remaining_buttons.duplicate()
			next_buttons.pop_at(remaining_buttons.find(button))
			
			# Generate a future sequence where the current button, current rule, and LEFT are chosen
			if remaining_rule_targets.has(Rule.RULE_TARGET.LEFT):
				var new_rule_action:RuleObjectAction
				new_rule_action = RuleObjectAction.new()
				new_rule_action.rule = get_current_rules()[rule_num]
				new_rule_action.rule_num = rule_num
				new_rule_action.update_target = Rule.RULE_TARGET.LEFT
				new_rule_action.update = button.object_name
				
				var remaining_rule_targets_left_removed:Array = remaining_rule_targets.duplicate()
				remaining_rule_targets_left_removed.pop_at(remaining_rule_targets_left_removed.find(Rule.RULE_TARGET.LEFT))
				
				var updated_rules:Dictionary[int, Array] = remaining_rules.duplicate()
				
				if remaining_rule_targets_left_removed.is_empty():
					updated_rules.erase(rule_num)
				else:
					updated_rules[rule_num] = remaining_rule_targets_left_removed
				
				var left_action_sequences:Array[ActionSequence]
				for action_sequence:ActionSequence in action_sequence_list: ##.duplicate(true):
					var new_action_sequence:ActionSequence = action_sequence.new_extended_sequence()
					new_action_sequence.add_action(new_rule_action)
					left_action_sequences.append(new_action_sequence)
				
				generate_rule_update_list(left_action_sequences.duplicate(true), next_buttons.duplicate(true), updated_rules.duplicate(true), actions_to_add - 1, end_list)

# Generate a future sequence where the current button, current rule, and RIGHT are chosen
			if remaining_rule_targets.has(Rule.RULE_TARGET.RIGHT):
				var new_rule_action:RuleObjectAction
				new_rule_action = RuleObjectAction.new()
				new_rule_action.rule = get_current_rules()[rule_num]
				new_rule_action.rule_num = rule_num
				new_rule_action.update_target = Rule.RULE_TARGET.RIGHT
				new_rule_action.update = button.object_name
				
				var remaining_rule_targets_right_removed:Array = remaining_rule_targets.duplicate()
				remaining_rule_targets_right_removed.pop_at(remaining_rule_targets_right_removed.find(Rule.RULE_TARGET.RIGHT))
				
				var updated_rules:Dictionary[int, Array] = remaining_rules.duplicate()
				
				if remaining_rule_targets_right_removed.is_empty():
					updated_rules.erase(rule_num)
				else:
					updated_rules[rule_num] = remaining_rule_targets_right_removed
				
				var right_action_sequences:Array[ActionSequence]
				for action_sequence:ActionSequence in action_sequence_list: ##.duplicate(true):
					var new_action_sequence:ActionSequence = action_sequence.new_extended_sequence()
					new_action_sequence.add_action(new_rule_action)
					right_action_sequences.append(new_action_sequence)

				generate_rule_update_list(right_action_sequences.duplicate(true), next_buttons.duplicate(true), updated_rules.duplicate(true), actions_to_add - 1, end_list)


# Generate a future sequence where the current button, current rule, and RIGHT are chosen
			if remaining_rule_targets.has(Rule.RULE_TARGET.EFFECT):
				var new_rule_action:RuleObjectAction
				new_rule_action = RuleObjectAction.new()
				new_rule_action.rule = get_current_rules()[rule_num]
				new_rule_action.rule_num = rule_num
				new_rule_action.update_target = Rule.RULE_TARGET.EFFECT
				new_rule_action.update = button.object_name
				
				var remaining_rule_targets_effect_removed:Array = remaining_rule_targets.duplicate()
				remaining_rule_targets_effect_removed.pop_at(remaining_rule_targets_effect_removed.find(Rule.RULE_TARGET.EFFECT))
				
				var updated_rules:Dictionary[int, Array] = remaining_rules.duplicate()
				
				if remaining_rule_targets_effect_removed.is_empty():
					updated_rules.erase(rule_num)
				else:
					updated_rules[rule_num] = remaining_rule_targets_effect_removed
				
				var right_action_sequences:Array[ActionSequence]
				for action_sequence:ActionSequence in action_sequence_list: ##.duplicate(true):
					var new_action_sequence:ActionSequence = action_sequence.new_extended_sequence()
					new_action_sequence.add_action(new_rule_action)
					right_action_sequences.append(new_action_sequence)

				generate_rule_update_list(right_action_sequences.duplicate(true), next_buttons.duplicate(true), updated_rules.duplicate(true), actions_to_add - 1, end_list)


func evaluate_actions(sequence_list:Array[ActionSequence]) -> void:
	var prefs


################################################################################
## Nested classes for keeping track of actions that the AI may use. 		  ##
## Local only to this class													  ##
################################################################################
class Action:
	pass

class ActionSequence:
	var max_sequence_size:int
	var _actions:Array[Action]
	
	func _init(max_size:int):
		max_sequence_size = max_size
	
	func add_action(action:Action) -> void:
		if _actions.size() < max_sequence_size:
			_actions.append(action)
		else:
			assert(false, "Attempted to add an Action to an ActionSequence that is already full.")
	
	func new_extended_sequence() -> ActionSequence:
		var new_sequence:ActionSequence = ActionSequence.new(max_sequence_size+1)
		new_sequence._actions = _actions.duplicate()
		return new_sequence
	
	func simulate_rule_updates(rule_ref:Array[RuleConfig]) -> void:
		for action:Action in _actions:
			# Skip if the action is playing an object
			if action is RuleObjectAction:
				if action.update_target == Rule.RULE_TARGET.LEFT:
					rule_ref[action.rule_num].left_object = action.update
				else:
					rule_ref[action.rule_num].right_object = action.update
			elif action is RuleEffectAction:
				rule_ref[action.rule_num].effect = action.update
	
	func evalue_action(rule_ref:Array[RuleConfig]) -> void:
		# Duplicate Deep because we don't want to keep overwriting the actual rule resource being used
		var updated_rule_ref:Array[RuleConfig] = rule_ref.duplicate_deep(Resource.DeepDuplicateMode.DEEP_DUPLICATE_ALL)
		simulate_rule_updates(updated_rule_ref)
		
		# The first action is a sequence is always the object being played
		var obj_played:GameplayUtils.OBJECT = _actions[0].obj
		
		for rule:RuleConfig in updated_rule_ref:
			if rule.left_object == obj_played:
				#Evaluate based on left preference
				pass
			elif rule.right_object == obj_played:
				#Evaluate based on right preference
				pass
		
	func _to_string() -> String:
		var print_str:String = ""
		for count:int in range(_actions.size()):
			print_str += "Action Number: %d. Action{%s}\n" % [count, _actions[count].to_string()]
		
		print_str += "---------------------------------------------------------\n"
		return print_str

class RuleObjectAction extends Action:
	var rule:RuleConfig
	var rule_num:int
	var update_target:Rule.RULE_TARGET
	var update:GameplayUtils.OBJECT
	
	func _to_string() -> String:
		var obj_name:String = GameplayUtils.get_object_name(update)
		return "Object:%s | Rule Num:%d | Target:%s" % [obj_name, rule_num, Rule.RULE_TARGET.keys()[update_target]]

class RuleEffectAction extends Action:
	var rule:RuleConfig
	var rule_num:int
	var update:GameplayUtils.EFFECT
	
	func _to_string() -> String:
		var obj_name:String = GameplayUtils.get_effect_name(update)
		return "Effect:%s | Rule Num:%d" % [obj_name, rule_num]

class PlayAction extends Action:
	var obj:GameplayUtils.OBJECT
	
	func _to_string() -> String:
		var obj_name:String = GameplayUtils.get_object_name(obj)
		return "Play %s" % obj_name
	

##TODO: Need to work on this once items are implemented
class ItemAction extends Action:
	var item
	var target
