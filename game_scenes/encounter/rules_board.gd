extends Node2D
class_name RulesBoard

@export var rule_scene:PackedScene
@export var rule_configs:Array[RuleConfig]

func _ready() -> void:
	# Connect to rules targets
	var rule_count:int = 0
	var rule_spawn_positions:Array = $RuleSpawnPositions.get_children()
	
	for config:RuleConfig in rule_configs:
		# Create the Rule Object
		var rule:Rule = rule_scene.instantiate()
		rule.rule_config = config
		rule.position = rule_spawn_positions[rule_count].position
		
		$Rules.add_child(rule)
		# Connect to the Rules Signals. MUST BE DONE AFTER ADDING TO THE TREE
		rule_count += 1

func connect_encounter_to_rule_signals(encounter:Encounter) -> void:
	for rule:Rule in $Rules.get_children():
		rule.left_target.mouse_wire_connection_overlap.connect(encounter.update_hovered_wire_connection)
		rule.effect_target.mouse_wire_connection_overlap.connect(encounter.update_hovered_wire_connection)
		rule.right_target.mouse_wire_connection_overlap.connect(encounter.update_hovered_wire_connection)

func get_current_rules() -> Array[RuleConfig]:
	var rules:Array[RuleConfig]
	
	for rule:Rule in $Rules.get_children():
		rules.append(rule.get_current_rule())
	
	return rules
