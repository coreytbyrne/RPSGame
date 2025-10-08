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
	
	match(effect):
		GameplayUtils.EFFECT.BEATS:
			beats(winner, loser)
		GameplayUtils.EFFECT.SMASHES:
			smashes(winner,loser)
		GameplayUtils.EFFECT.SNIPS:
			snips(winner,loser)
		GameplayUtils.EFFECT.COPIES:
			copies(winner,loser)
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
	
	#if loser is Player:
		#for wire:Wire in loser.wires.get_children():
			#if wire.connected_target == loser.played_object.target:
				#var button_ref:PlayerButton = wire.connected_button
				#button_ref.toggle_button_disable(true)
				#add_future(rounds_played+2, func():button_ref.toggle_button_disable(false);print("Button Restored"))
	#else:
		#loser.disable_button(loser.played_object)
		#add_future(rounds_played+2, func():loser.enable_button(loser.played_object);print("Opponent Button Restored"))
	

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
		return

	effect_to_copy = GameplayUtils.get_corresponding_effect_from_object(copy_target)
	delegate_rule_resolve(winner, loser, effect_to_copy)
