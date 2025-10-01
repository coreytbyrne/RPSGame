extends Resource
class_name OpponentPreferences

@export var preferences:Dictionary[GameplayUtils.EFFECT, EffectPreference]
@export var high_weight:float = 10.0
@export var med_weight:float = 5.0
@export var low_weight:float = 0.0
