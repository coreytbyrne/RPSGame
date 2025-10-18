extends Node
class_name GameplayUtils

enum OBJECT {
	NONE,
	ROCK,
	PAPER,
	SCISSORS,
	DART_FROG,
	HAM,
	SHIELD,
	NO_YOU,
}

enum EFFECT {
	NONE,
	BEATS,
	SMASHES,
	SNIPS,
	COPIES,
	POISONS,
	SHOWS_OFF,
	DEFENDS,
	REVERSES
}

static var object_effect_map:Dictionary[OBJECT, EFFECT] = {
	OBJECT.ROCK : EFFECT.SMASHES,
	OBJECT.PAPER : EFFECT.COPIES,
	OBJECT.SCISSORS : EFFECT.SNIPS,
	OBJECT.DART_FROG : EFFECT.POISONS,
	OBJECT.HAM : EFFECT.SHOWS_OFF,
	OBJECT.SHIELD : EFFECT.DEFENDS,
	OBJECT.NO_YOU : EFFECT.REVERSES,
}


static func get_object_name(obj:OBJECT) -> String:
	return OBJECT.keys()[obj].capitalize()


static func get_effect_name(effect:EFFECT) -> String:
	return EFFECT.keys()[effect].capitalize()


static func get_object_from_effect(effect:EFFECT) -> OBJECT:
	return object_effect_map.find_key(effect)


static func get_config_from_object(obj:OBJECT) -> CartridgeConfig:
	var object_name:String = get_object_name(obj).to_lower()
	object_name = object_name.replace(" ", "_")
	var cart_config:CartridgeConfig = load("res://entities/cartridge/configs/%s_cartridge.tres" % object_name)
	return cart_config
