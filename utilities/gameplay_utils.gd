extends Node
class_name GameplayUtils

enum OBJECT {
	NONE,
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


static func get_effect_name(effect:EFFECT) -> String:
	return EFFECT.keys()[effect].capitalize()


static func get_effect_text(left_object:OBJECT, effect:EFFECT, right_object:OBJECT) -> String:
	return _effect_text[effect] % [get_object_name(left_object), get_object_name(right_object)]


static func get_corresponding_effect_from_object(obj:OBJECT) -> EFFECT:
	var object_name:String = get_object_name(obj).to_lower()
	var button_config:ButtonConfig = load("res://entities/player_buttons/button_configs/%s_button.tres" % object_name)
	return button_config.effect
