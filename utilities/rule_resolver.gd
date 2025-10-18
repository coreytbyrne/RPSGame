extends Node

var rule_board_reference:RulesBoard
var rounds_played:int = 0
#var future_tracker:Dictionary[int, Array] = {}
var futures:Array[Future]
var encounter_reference:Encounter


signal rule_resolved


func next_round() -> void:
	rounds_played += 1


func add_future(num_rounds:int, target:Participant, trigger_type:Future.TRIGGER_TIME, function:Callable) -> void:
	var new_future = Future.new(target, function, num_rounds, trigger_type)
	futures.append(new_future)


func resolve_futures_round_start() -> void:
	var temp_futures:Array[Future] = futures.duplicate()
	for future:Future in temp_futures:
		var is_future_exhausted:bool = future.next_round()
		if is_future_exhausted:
			futures.pop_at(futures.find(future))



## The format of these function parameters should always be (winner, loser, other_params)
func delegate_rule_resolve(winner:Participant, loser:Participant, effect:GameplayUtils.EFFECT) -> void:
	# Handle Shielded scenario
	if loser.is_shielded:
		print("%s defends against %s's %s. %s shield broke!" % \
		[loser.participant_name, winner.participant_name, GameplayUtils.get_effect_name(effect), loser.participant_name])
		loser.is_shielded = false
		(func(): rule_resolved.emit()).call_deferred()
		return
	
	# Handle Reverse scenarios
	if loser.has_reverse:
		print("%s uses their reverse to make themselves the winner!" % loser.participant_name)
		loser.has_reverse = false
		
		if winner.has_reverse:
			print("%s uses their reverse to negate %s's reverse!" % [winner.participant_name, loser.participant_name])
			winner.has_reverse = false
		else:
			delegate_rule_resolve(loser, winner, effect)
			return
		
		
	
	# Delegate the effect to the proper function
	match(effect):
		GameplayUtils.EFFECT.BEATS:
			beats(winner, loser)
		GameplayUtils.EFFECT.SMASHES:
			smashes(winner,loser)
		GameplayUtils.EFFECT.SNIPS:
			snips(winner,loser)
		GameplayUtils.EFFECT.COPIES:
			copies(winner,loser)
		GameplayUtils.EFFECT.POISONS:
			poisons(winner, loser)
		GameplayUtils.EFFECT.SHOWS_OFF:
			shows_off(winner, loser)
		GameplayUtils.EFFECT.DEFENDS:
			defends(winner,loser)
		GameplayUtils.EFFECT.REVERSES:
			reverses(winner,loser)
		GameplayUtils.EFFECT.NONE:
			pass
		_:
			var effect_string:String = GameplayUtils.get_effect_name(effect)
			assert(false, "The effect passed does not have a Rule Resolve reference yet. Effect %s" % effect_string)
	
	 
	(func(): rule_resolved.emit()).call_deferred()

func beats(winner:Participant, loser:Participant) -> void:
	loser.dosage += 1
	print("%s's dosage increased! They're now at %d/%d!" % [loser.participant_name, loser.dosage, loser.max_dosage])


func smashes(winner:Participant, loser:Participant) -> void:
	print("%s smashed a plug belonging to %s!" % [winner.participant_name, loser.participant_name])
	loser.plug_count_modifier -= 1
	
	## At the start of 2 rounds from now, restore the wire count modifier
	## Ex: Currently round 0, Wire count effects round 1, and restored on round 2
	add_future(2, loser, Future.TRIGGER_TIME.AFTER_COUNTDOWN, 
	func(targ:Participant): targ.plug_count_modifier += 1; print("%s Plug Count Restored" % targ.participant_name))


func snips(winner:Participant, loser:Participant) -> void:
	print("%s snipped %s's played transmitter!" % [winner.participant_name, loser.participant_name])
	
	if loser is Player:
		for plug:Plug in loser.plugs:
			if plug.connected_target == encounter_reference.get_node("PlayedObject").target:
				var transmitter:Transmitter = plug.connected_transmitter
				transmitter.disable_transmitter()
				#add_future(rounds_played+2, func():transmitter.enable_transmitter();print("Transmitter Restored"))
				add_future(2, loser, Future.TRIGGER_TIME.AFTER_COUNTDOWN, 
				func(targ:Participant):transmitter.enable_transmitter();print("%s Transmitter Restored" % targ.participant_name))
	else:
		loser.disable_transmitter(loser.played_object)
		add_future(2, loser, Future.TRIGGER_TIME.AFTER_COUNTDOWN, 
		func(targ:Participant):loser.enable_transmitter(loser.played_object);print("%s Transmitter Restored" % targ.participant_name))


func copies(winner:Participant, loser:Participant) -> void:
	print("%s copied the effect of %s!" % [winner.participant_name, loser.participant_name])
	
	var copy_target:GameplayUtils.OBJECT
	var effect_to_copy:GameplayUtils.EFFECT
	
	if winner is Player:
		copy_target = loser.played_object
	else:
		copy_target = encounter_reference.get_node("PlayedObject").played_object

	# Copy doesn't do anyting if both are paper - need to break in that case to avoid an infinite loop
	if copy_target == GameplayUtils.OBJECT.PAPER:
		print("%s's copy fizzled out" % [winner.participant_name])
		return

	effect_to_copy = GameplayUtils.get_config_from_object(copy_target).effect
	delegate_rule_resolve(winner, loser, effect_to_copy)


func poisons(winner:Participant, loser:Participant) -> void:
	print("%s poisoned %s!" % [winner.participant_name, loser.participant_name])

	add_future(2, loser, Future.TRIGGER_TIME.PER_ROUND, 
	func(targ:Participant):targ.dosage += 1;print("%s took poison damage!" % loser.participant_name))



func shows_off(winner:Participant, loser:Participant) -> void:

	var winning_object:GameplayUtils.OBJECT
	var effect_to_use:GameplayUtils.EFFECT
	
	if winner is Player:
		winning_object = encounter_reference.get_node("PlayedObject").played_object
	else:
		winning_object = winner.played_object
	
	# Doesn't do anything if the object is a Ham - need to break in that case to avoid an infinite loop
	if winning_object == GameplayUtils.OBJECT.HAM:
		print("%s's Ham fizzled out" % [winner.participant_name])
		return

	effect_to_use = GameplayUtils.get_config_from_object(winning_object).effect
	print("%s shows off and uses the effect of their %s" % [winner.participant_name, GameplayUtils.get_object_name(winning_object)])
	
	delegate_rule_resolve(winner, loser, effect_to_use)


func defends(winner:Participant, loser:Participant) -> void:
	winner.is_shielded = true
	print("%s is defended from the next losing effect!" % winner.participant_name)
	
func reverses(winner:Participant, loser:Participant) -> void:
	winner.has_reverse = true
	print("%s will reverse the effects of their next loss! " % winner.participant_name)



class Future:
	var _target:Participant
	var _function:Callable
	var _remaining_rounds:int
	var _trigger:TRIGGER_TIME
	
	enum TRIGGER_TIME {PER_ROUND, AFTER_COUNTDOWN}
	
	func _init(target:Participant, function:Callable, rounds:int, trigger:TRIGGER_TIME):
		_target = target
		_function = function
		_remaining_rounds = rounds
		_trigger = trigger
	
	func next_round() -> bool:
		_remaining_rounds -= 1
		
		if _trigger == TRIGGER_TIME.PER_ROUND:
			_function.call(_target)
		elif _trigger == TRIGGER_TIME.AFTER_COUNTDOWN and _remaining_rounds == 0:
			_function.call(_target)
		
		if _remaining_rounds <= 0:
			return true
		else:
			return false
	
