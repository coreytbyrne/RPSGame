extends Participant
class_name Opponent


@export var preferences:OpponentPreferences
@export var played_object:GameplayUtils.OBJECT
@export var player_history:Dictionary[GameplayUtils.OBJECT, int]

@export var swap_charge:int = 100
@export var swap_recharge_rate:int = 25
@export var swap_threshold:int = 100
var swap_recharge_modifer:int = 0

var transmitters:Array[CartridgeConfig]
var disposable_transmitters:Dictionary[CartridgeConfig, int]
var available_transmitters:Array[CartridgeConfig]
var disabled_transmitters:Array[CartridgeConfig]

var default_plug_count:int :
	set(value):
		default_plug_count = value
		current_plug_count = value
var current_plug_count:int
var rule_board_reference:RulesBoard

func _ready() -> void:
	super._ready()
	spinner_dose_node.position = $DoseLocation.position
	spinner_name_node.position = $NameLocation.position
	spinner_status_node.position = $StatusLocation.position


func set_available_transmitters(transmitter_list:Array[CartridgeConfig]) -> void:
	available_transmitters = transmitter_list
	transmitters = transmitter_list


func set_disposable_transmitters(disposables:Dictionary[CartridgeConfig, int]) -> void:
	#disposable_transmitters = disposables
	for transmitter:CartridgeConfig in disposables.keys():
		var unique_config:CartridgeConfig = transmitter.duplicate()
		available_transmitters.append(unique_config)
		disposable_transmitters[unique_config] =  disposables[transmitter]



func disable_transmitter(obj:GameplayUtils.OBJECT) -> void:
	for transmitter:CartridgeConfig in available_transmitters:
		if transmitter.object == obj:
			disabled_transmitters.append(available_transmitters.pop_at(available_transmitters.find(transmitter)))


func enable_transmitter(obj:GameplayUtils.OBJECT) -> void:
	for transmitter:CartridgeConfig in disabled_transmitters:
		if transmitter.object == obj:
			available_transmitters.append(disabled_transmitters.pop_at(disabled_transmitters.find(transmitter)))


func choose_actions_to_perform() -> ActionSequence:
	var possible_actions:Array[ActionSequence] = generate_rules()
	append_swaps_to_rule_updates(possible_actions)
	
	#### NOTE: Temp file, just for testing
	#var file = FileAccess.open("res://opponent_options.txt", FileAccess.WRITE)
	#for action_set in possible_actions:
		#file.store_string(action_set.to_string())
	
	# Sort actions
	evaluate_actions(possible_actions)
	# Remove suboptimal actions
	possible_actions = filter_suboptimal_actions(possible_actions)
	

	
	# Choose a random action
	var chosen_action_sequence:ActionSequence
	chosen_action_sequence = possible_actions[randi_range(0, possible_actions.size() - 1)]
	print(chosen_action_sequence)
	#### NOTE: Temp, just for testing
	#file.store_string("\n\nACTION SELECTED: %s" %chosen_action_sequence.to_string())
	#file.close()
	
	return chosen_action_sequence


func apply_actions(chosen_action_sequence:ActionSequence) -> void:
	var actions:Array[Action] = chosen_action_sequence.get_actions()
	for action:Action in actions:
		check_for_disposable_transmitter_use(action)
		
		if action is PlayAction:
			played_object = action.obj
			continue
		elif action is RuleSwapAction:
			swap_charge -= swap_threshold

		rule_board_reference.opponent_rule_update(action)
		
		

func check_for_disposable_transmitter_use(action:Action) -> void:
	if action.associated_transmitter == null:
		return
		
	# Check if the transmitter used is disposable
	if action.associated_transmitter in disposable_transmitters:
		disposable_transmitters[action.associated_transmitter] -= 1
		
		# Remove the transmitter from the available actions
		if disposable_transmitters[action.associated_transmitter] <= 0:
			var disposable_ind:int = available_transmitters.find(action.associated_transmitter)
			available_transmitters.pop_at(disposable_ind)
			disposable_transmitters.erase(action.associated_transmitter)


#func add_to_player_history(player_played_obj:GameplayUtils.OBJECT) -> void:
	#var current_count:int = player_history.get_or_add(player_played_obj, 0)
	#player_history[player_played_obj] = current_count + 1


func get_played_object() -> GameplayUtils.OBJECT:
	return played_object


func get_current_rules() -> Array[RuleConfig]:
	return rule_board_reference.get_current_rules()


func evaluate_actions(actions:Array[ActionSequence]) -> void:
	for action:ActionSequence in actions:
		action.evaluate_action(get_current_rules(), preferences, player_history)
	
	actions.sort_custom(func(a:ActionSequence, b:ActionSequence): return a.action_weight > b.action_weight)


## This function assumes that the actions are already sorted by action weight
func filter_suboptimal_actions(actions:Array[ActionSequence]) -> Array[ActionSequence]:
	var best_weight:float = actions[0].action_weight
	var filtered_actions:Array[ActionSequence]
	
	filtered_actions = actions.filter(
		(func(action:ActionSequence,filter_weight:float): return action.action_weight >= filter_weight
		).bind(best_weight * preferences.optimality))
		
	return filtered_actions


func generate_rules() -> Array[ActionSequence]:
	var all_actions:Array[ActionSequence]
	var rule_list:Dictionary[int, Array]
	
	if (current_plug_count + plug_count_modifier <= 0) or (available_transmitters.size() <= 0 ):
		var play_object:PlayAction = PlayAction.new()
		play_object.obj = GameplayUtils.OBJECT.NONE

		var action_sequence:ActionSequence = ActionSequence.new(1)
		action_sequence.add_action(play_object)
		return [action_sequence]
		
	for transmitter:CartridgeConfig in available_transmitters:
		var play_object:PlayAction = PlayAction.new()
		play_object.associated_transmitter = transmitter
		play_object.obj = transmitter.object
		
		var action_sequence:ActionSequence = ActionSequence.new(1)
		action_sequence.add_action(play_object)
		
		# Determine Action length	
		var num_actions:int = mini(current_plug_count - 1 + plug_count_modifier, available_transmitters.size() - 1)
		var remaining_transmitters:Array[CartridgeConfig] = available_transmitters.duplicate()
		remaining_transmitters.pop_at(remaining_transmitters.find(transmitter))
		
		for rule_num:int in range(get_current_rules().size()):
			rule_list[rule_num] = [Rule.RULE_TARGET.LEFT, Rule.RULE_TARGET.RIGHT, Rule.RULE_TARGET.EFFECT]
			
		var temp_sequence:Array[ActionSequence]
		generate_rule_update_list([action_sequence], remaining_transmitters, rule_list, num_actions, temp_sequence)
		
		all_actions.append_array(temp_sequence)
		
	#evaluate_actions(all_actions)
	return all_actions


func generate_rule_update_list(action_sequence_list:Array[ActionSequence], remaining_transmitters:Array[CartridgeConfig], remaining_rules:Dictionary[int,Array], actions_to_add:int, end_list:Array[ActionSequence]) -> void:
	end_list.append_array(action_sequence_list)
	
	if actions_to_add <= 0:
		return
	
	for transmitter:CartridgeConfig in remaining_transmitters:
		for rule_num:int in remaining_rules.keys():
			var remaining_rule_targets:Array = remaining_rules[rule_num]
			var next_transmitters:Array[CartridgeConfig] = remaining_transmitters.duplicate()
			next_transmitters.pop_at(remaining_transmitters.find(transmitter))
			
			# Generate a future sequence where the current transmitter, current rule, and LEFT are chosen
			if remaining_rule_targets.has(Rule.RULE_TARGET.LEFT):
				var new_rule_action:RuleObjectAction
				new_rule_action = RuleObjectAction.new()
				new_rule_action.associated_transmitter = transmitter
				new_rule_action.rule = get_current_rules()[rule_num]
				new_rule_action.rule_num = rule_num
				new_rule_action.update_target = Rule.RULE_TARGET.LEFT
				new_rule_action.update = transmitter.object
				
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
				
				generate_rule_update_list(left_action_sequences.duplicate(true), next_transmitters.duplicate(true), updated_rules.duplicate(true), actions_to_add - 1, end_list)

# Generate a future sequence where the current transmitter, current rule, and RIGHT are chosen
			if remaining_rule_targets.has(Rule.RULE_TARGET.RIGHT):
				var new_rule_action:RuleObjectAction
				new_rule_action = RuleObjectAction.new()
				new_rule_action.associated_transmitter = transmitter
				new_rule_action.rule = get_current_rules()[rule_num]
				new_rule_action.rule_num = rule_num
				new_rule_action.update_target = Rule.RULE_TARGET.RIGHT
				new_rule_action.update = transmitter.object
				
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

				generate_rule_update_list(right_action_sequences.duplicate(true), next_transmitters.duplicate(true), updated_rules.duplicate(true), actions_to_add - 1, end_list)


# Generate a future sequence where the current transmitter, current rule, and RIGHT are chosen
			if remaining_rule_targets.has(Rule.RULE_TARGET.EFFECT):
				var new_rule_action:RuleEffectAction
				new_rule_action = RuleEffectAction.new()
				new_rule_action.associated_transmitter = transmitter
				new_rule_action.rule = get_current_rules()[rule_num]
				new_rule_action.rule_num = rule_num
				new_rule_action.update = transmitter.effect
				
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

				generate_rule_update_list(right_action_sequences.duplicate(true), next_transmitters.duplicate(true), updated_rules.duplicate(true), actions_to_add - 1, end_list)


func append_swaps_to_rule_updates(action_sequence_list:Array[ActionSequence]) -> void:
	# If the swap charge isn't high enough, then pass
	if swap_charge < swap_threshold:
		return
	
	var swap_sequences:Array[ActionSequence]
	var rules:Array[RuleConfig] = get_current_rules()
	
	for action_sequence:ActionSequence in action_sequence_list:
		for rule_num:int in range(rules.size()):
			var swap_action:RuleSwapAction = RuleSwapAction.new()
			swap_action.rule = rules[rule_num]
			swap_action.rule_num = rule_num
			
			var new_sequence:ActionSequence = action_sequence.new_extended_sequence()
			new_sequence.add_action(swap_action)
			swap_sequences.append(new_sequence)

	action_sequence_list.append_array(swap_sequences)


func recharge_swap() -> void:
	swap_charge += swap_recharge_rate + swap_recharge_modifer


################################################################################
## Nested classes for keeping track of actions that the AI may use. 		  ##
## Local only to this class													  ##
################################################################################
class Action:
	var associated_transmitter:CartridgeConfig


class ActionSequence:
	var max_sequence_size:int
	var action_weight:float
	
	var _actions:Array[Action]

	
	func _init(max_size:int):
		max_sequence_size = max_size
	
	func get_actions() -> Array[Action]:
		return _actions
	
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
			elif action is RuleSwapAction:
				rule_ref[action.rule_num].left_object = action.rule.right_object
				rule_ref[action.rule_num].right_object = action.rule.left_object
	
	func evaluate_action(rule_ref:Array[RuleConfig], prefs:OpponentPreferences, player_history:Dictionary[GameplayUtils.OBJECT, int]) -> void:
		# Duplicate Deep because we don't want to keep overwriting the actual rule resource being used
		var updated_rule_ref:Array[RuleConfig] = rule_ref.duplicate_deep(Resource.DeepDuplicateMode.DEEP_DUPLICATE_ALL)
		simulate_rule_updates(updated_rule_ref)
		
		# The first action is a sequence is always the object being played
		var obj_played:GameplayUtils.OBJECT = _actions[0].obj
		#Base weight
		var rule_weight:float = 10.0
		
		for rule:RuleConfig in updated_rule_ref:
			var effect_prefs:EffectPreference = prefs.preferences[rule.effect]
			var player_odds_denom:float = player_history.values().reduce(func(accum, number): return accum + number, 0)
			var player_odds:float = 1.0
			
			# Winning Position
			if rule.left_object == obj_played:
				if player_history.has(rule.right_object):
					player_odds += (player_history[rule.right_object]/ player_odds_denom)
				
				match(effect_prefs.winning_preference):
					EffectPreference.PREFERENCE.FIVE:
						rule_weight += prefs.five_weight
					EffectPreference.PREFERENCE.FOUR:
						rule_weight += prefs.four_weight
					EffectPreference.PREFERENCE.THREE:
						rule_weight += prefs.three_weight
					EffectPreference.PREFERENCE.TWO:
						rule_weight += prefs.two_weight
					EffectPreference.PREFERENCE.ONE:
						rule_weight += prefs.one_weight
				
				# Static rules only have a fraction of the weight. This is done to avoid the
				# Opponent ALWAYS playing into static rules
				if rule.constant_effect != GameplayUtils.EFFECT.NONE:
					var const_effect_prefs:EffectPreference = prefs.preferences[rule.effect] 
					match(const_effect_prefs.winning_preference):
						EffectPreference.PREFERENCE.FIVE:
							rule_weight = rule_weight + (prefs.five_weight/2)
						EffectPreference.PREFERENCE.FOUR:
							rule_weight  = rule_weight + (prefs.four_weight/2)
						EffectPreference.PREFERENCE.THREE:
							rule_weight = rule_weight + (prefs.three_weight/2)
						EffectPreference.PREFERENCE.TWO:
							rule_weight = rule_weight + (prefs.two_weight/2)
						EffectPreference.PREFERENCE.ONE:
							rule_weight = rule_weight + (prefs.one_weight/2)
				
				rule_weight *= player_odds
			# Losing Position
			elif rule.right_object == obj_played:
				if player_history.has(rule.left_object):
					player_odds += (player_history[rule.left_object]/ player_odds_denom)
					
				match(effect_prefs.losing_preference):
					EffectPreference.PREFERENCE.FIVE:
						rule_weight -= prefs.five_weight
					EffectPreference.PREFERENCE.FOUR:
						rule_weight -= prefs.four_weight
					EffectPreference.PREFERENCE.THREE:
						rule_weight -= prefs.three_weight
					EffectPreference.PREFERENCE.TWO:
						rule_weight -= prefs.two_weight
					EffectPreference.PREFERENCE.ONE:
						rule_weight -= prefs.one_weight
				
				# Static rules only have a fraction of the weight. This is done to avoid the
				# Opponent ALWAYS playing into static rules
				if rule.constant_effect != GameplayUtils.EFFECT.NONE:
					var const_effect_prefs:EffectPreference = prefs.preferences[rule.effect] 
					match(const_effect_prefs.losing_preference):
						EffectPreference.PREFERENCE.FIVE:
							rule_weight = rule_weight - (prefs.five_weight/2)
						EffectPreference.PREFERENCE.FOUR:
							rule_weight  = rule_weight - (prefs.four_weight/2)
						EffectPreference.PREFERENCE.THREE:
							rule_weight = rule_weight - (prefs.three_weight/2)
						EffectPreference.PREFERENCE.TWO:
							rule_weight = rule_weight - (prefs.two_weight/2)
						EffectPreference.PREFERENCE.ONE:
							rule_weight = rule_weight - (prefs.one_weight/2)
				
				
				rule_weight /= player_odds
				
		action_weight = snappedf(rule_weight, .001)

		
		
	func _to_string() -> String:
		var print_str:String = "Sequence Weight: %f.\n" % action_weight
		for count:int in range(_actions.size()):
			print_str += "Action Number: %d. Action{%s}\n" % [count, _actions[count].to_string()]
		return print_str

class RuleObjectAction extends Action:
	var rule:RuleConfig
	var rule_num:int
	var update_target:Rule.RULE_TARGET
	var update:GameplayUtils.OBJECT
	
	func apply_action() -> void:
		if update_target == Rule.RULE_TARGET.LEFT:
			rule.left_object = update
		elif update_target == Rule.RULE_TARGET.RIGHT:
			rule.right_object = update
	
	func _to_string() -> String:
		var obj_name:String = GameplayUtils.get_object_name(update)
		return "Object:%s | Rule Num:%d | Target:%s" % [obj_name, rule_num, Rule.RULE_TARGET.keys()[update_target]]

class RuleEffectAction extends Action:
	var rule:RuleConfig
	var rule_num:int
	var update:GameplayUtils.EFFECT
	
	func apply_action() -> void:
		rule.effect = update
	
	func _to_string() -> String:
		var obj_name:String = GameplayUtils.get_effect_name(update)
		return "Effect:%s | Rule Num:%d" % [obj_name, rule_num]


class RuleSwapAction extends Action:
	var rule:RuleConfig
	var rule_num:int
	
	func apply_action() -> void: 
		var left_action:GameplayUtils.OBJECT = rule.left_object
		var right_action:GameplayUtils.OBJECT = rule.right_object
		
		rule.left_object = right_action
		rule.right_object = left_action
	
	func _to_string() -> String:
		return "Rule Num:%d swapped" % rule_num


class PlayAction extends Action:
	var obj:GameplayUtils.OBJECT
	
	func _to_string() -> String:
		var obj_name:String = GameplayUtils.get_object_name(obj)
		return "Play %s" % obj_name
	

##TODO: Need to work on this once items are implemented
class ItemAction extends Action:
	var item
	var target
