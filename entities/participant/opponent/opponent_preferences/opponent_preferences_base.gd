extends Resource
class_name OpponentPreferences

@export_category("Preferences")
@export var preferences:Dictionary[GameplayUtils.EFFECT, EffectPreference]
@export_category("Weights")
@export var five_weight:float = 10.0
@export var four_weight:float = 7.5
@export var three_weight:float = 5.0
@export var two_weight:float = 3.5
@export var one_weight:float = 0.0
@export_category("Difficulty")
@export_range (0,1.0,.01)
var optimality:float = 1.0
