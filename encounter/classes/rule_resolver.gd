class_name RuleResolver
extends Node


static func generate_effects(played_objects:Dictionary, rules:Array[Rule]):	
	var effects_to_apply:Array
	
	for rule:Rule in rules:
		var winners:Array[EnUtil.PLAYER]
		
		# Check if player 1 won
		for type1:ConUtil.BUTTON_TYPE in played_objects[EnUtil.PLAYER.ONE]:
			if rule.winning_type.has(type1):
				for type2:ConUtil.BUTTON_TYPE in played_objects[EnUtil.PLAYER.TWO]:
					if rule.losing_type.has(type2):
						winners.append(EnUtil.PLAYER.ONE)
		
		# Check if player 2 won
		for type2:ConUtil.BUTTON_TYPE in played_objects[EnUtil.PLAYER.TWO]:
			if rule.winning_type.has(type2):
				for type1:ConUtil.BUTTON_TYPE in played_objects[EnUtil.PLAYER.ONE]:
					if rule.losing_type.has(type1):
						winners.append(EnUtil.PLAYER.TWO)
		
		for winner:EnUtil.PLAYER in winners:
			if winner == EnUtil.PLAYER.ONE:
				generate_effect(EnUtil.PLAYER.ONE, EnUtil.PLAYER.TWO, rule.effect, effects_to_apply)
			if winner == EnUtil.PLAYER.TWO:
				generate_effect(EnUtil.PLAYER.TWO, EnUtil.PLAYER.ONE, rule.effect, effects_to_apply)


static func generate_effect(winner:EnUtil.PLAYER, loser:EnUtil.PLAYER, effect:ConUtil.BUTTON_EFFECT, effects_to_apply:Array) -> void:
	var effect_outcome:EffectOutcome = EffectOutcome.new()
	pass
