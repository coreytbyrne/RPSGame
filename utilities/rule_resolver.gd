extends Node

var rule_board_reference:RulesBoard
var rounds_played:int = 0
var future_tracker:Dictionary[int, Array] = {}
var encounter_reference:Encounter


signal rule_resolved


func next_round() -> void:
	rounds_played += 1


func add_future(future_round:int, function:Callable) -> void:
	var futures:Array = future_tracker.get_or_add(future_round, [])
	
	if futures.is_empty():
		future_tracker[future_round] = [function]
	else:
		future_tracker[future_round].append(function)


func resolve_futures_round_start() -> void:
	if future_tracker.has(rounds_played):
		var futures_to_resolve:Array = future_tracker[rounds_played]
		
		for future:Callable in futures_to_resolve:
			future.call()


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
	loser.health -= 1
	print("%s down to %d health!" % [loser.participant_name, loser.health])


func smashes(winner:Participant, loser:Participant) -> void:
	print("%s smashed a plug belonging to %s!" % [winner.participant_name, loser.participant_name])
	loser.plug_count_modifier -= 1
	
	## At the start of 2 rounds from now, restore the wire count modifier
	## Ex: Currently round 0, Wire count effects round 1, and restored on round 2
	add_future(rounds_played+2, func():loser.plug_count_modifier += 1;print("Plug Count Restored"))


func snips(winner:Participant, loser:Participant) -> void:
	print("%s snipped %s's played cartridge!" % [winner.participant_name, loser.participant_name])
	
	if loser is Player:
		for plug:Plug in loser.plugs:
			if plug.connected_target == encounter_reference.get_node("PlayedObject").target:
				var cartridge:Cartridge = plug.connected_cartridge
				cartridge.disable_cartridge()
				add_future(rounds_played+2, func():cartridge.enable_cartridge();print("Cartridge Restored"))
	else:
		loser.disable_cartridge(loser.played_object)
		add_future(rounds_played+2, func():loser.enable_cartridge(loser.played_object);print("Opponent Cartridge Restored"))


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
	print("%s poisoned %s for the next 2 rounds!" % [winner.participant_name, loser.participant_name])
	
	add_future(rounds_played+2, func():loser.health -= 1;print("%s took poison damage!" % loser.participant_name))
	add_future(rounds_played+3, func():loser.health -= 1;print("%s took poison damage! They recovered from their poison" % loser.participant_name))



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
