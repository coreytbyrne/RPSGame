extends Node2D
class_name RulesBoard

@export var rule_scene:PackedScene
@export var rule_configs:Array[RuleConfig]

var swap_threshold:int = 100

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
		#await rule.ready
		# Connect to the Rules Signals. MUST BE DONE AFTER ADDING TO THE TREE
		rule_count += 1


func update_player_swap_buttons(swap_charge:int) -> void:
	var is_swap_disabled:bool = (swap_charge < swap_threshold)
	for rule:Rule in $Rules.get_children():
		rule.toggle_rule_swap_disable(is_swap_disabled)
	

func connect_player_to_rule_signals(player:Player) -> void:
	player.swap_charge_updated.connect(update_player_swap_buttons)
	
	for rule:Rule in $Rules.get_children():
		rule.rule_swapped.connect(player.update_swap_charge)
	
	# Since the player will be ready in the tree before the RuleBoard, need to do an 
	# initial check to see if the player's starting swap charge is high enough for a swap
	update_player_swap_buttons(player.swap_charge)

func connect_encounter_to_rule_signals(encounter:Encounter) -> void:
	for rule:Rule in $Rules.get_children():
		rule.left_target.target_plug_slot_hovered.connect(encounter.update_hovered_target)
		rule.effect_target.target_plug_slot_hovered.connect(encounter.update_hovered_target)
		rule.right_target.target_plug_slot_hovered.connect(encounter.update_hovered_target)


func get_current_rules() -> Array[RuleConfig]:
	var rules:Array[RuleConfig]
	
	for rule:Rule in $Rules.get_children():
		rules.append(rule.get_current_rule())
	return rules


func apply_changes_to_rules() -> void:
	for rule:Rule in $Rules.get_children():
		await rule.apply_rule_changes()


func opponent_rule_update(rule_update:Opponent.Action) -> void:
	var rule_nodes:Array = $Rules.get_children()
	if rule_update is Opponent.RuleObjectAction:
		rule_nodes[rule_update.rule_num].opponent_update(rule_update.update_target, rule_update.update)
	elif rule_update is Opponent.RuleEffectAction:
		rule_nodes[rule_update.rule_num].opponent_update(Rule.RULE_TARGET.EFFECT, rule_update.update)
	elif rule_update is Opponent.RuleSwapAction:
		rule_nodes[rule_update.rule_num].opponent_swap()


func mark_rule_triggered(rule_num:int, is_active:bool) -> void:
	$Rules.get_child(rule_num).rule_triggered_update(is_active)
