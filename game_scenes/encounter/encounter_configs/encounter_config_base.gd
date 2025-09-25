extends Resource
class_name EncounterConfig

@export_category("Player Configurations")
@export var num_player_wires:int = 2
@export var player_buttons:Array[ButtonConfig]
##@export var player_items:Array[Items]

@export_category("Opponent Configurations")
@export var num_opponent_wires:int = 2
@export var opponent_buttons:Array[ButtonConfig]
##@export var opponent_personality:OpponentPersonality
##@export var opponent_items:Array[Items]
