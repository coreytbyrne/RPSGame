extends Resource
class_name EncounterConfig

@export_category("Player Configurations")
@export var num_player_plugs:int = 2
@export var player_cartridges:Array[CartridgeConfig]
##@export var player_items:Array[Items]

@export_category("Opponent Configurations")
@export var num_opponent_plugs:int = 2
@export var opponent_cartridges:Array[CartridgeConfig]
##@export var opponent_personality:OpponentPersonality
##@export var opponent_items:Array[Items]

@export_category("Starting Rules")
@export var rules:Array[RuleConfig]
