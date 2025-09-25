extends Node
class_name GameplayUtils

enum OBJECT {
	ROCK,
	PAPER,
	SCISSORS
}

enum EFFECT {
	BEATS,
	SMASHES,
	SNIPS,
	COPIES
}

static var _effect_text:Dictionary[EFFECT, String] = {
	EFFECT.BEATS : "%s beats %s",
	EFFECT.SMASHES: "%s smashes %s's button", 
	EFFECT.SNIPS: "%s snips %s's wire",
	EFFECT.COPIES: "%s copies the effect of %s",
}

static func get_object_name(obj:OBJECT) -> String:
	return OBJECT.keys()[obj].capitalize()


static func get_effect_text(left_object:OBJECT, effect:EFFECT, right_object:OBJECT) -> String:
	return _effect_text[effect] % [get_object_name(left_object), get_object_name(right_object)]
