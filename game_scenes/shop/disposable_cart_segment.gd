extends ShopSegment
class_name DisposableCartSegment

var min_uses:int = 3
var max_uses:int = 10


func choose_inventory(rule_set:Array[RuleConfig] = []) -> Array[DisposableShopItem]:
	var rand_transmitters:int = 0
	var rule_based_transmitters:int = 0
	var inventory:Array[DisposableShopItem] = []
	
	if rule_set.is_empty():
		rand_transmitters = 4
	else:
		rand_transmitters = 1
		rule_based_transmitters = 3
	
	for i:int in range(rule_based_transmitters):
		var item:DisposableShopItem = DisposableShopItem.new()
		var object_from_rule:GameplayUtils.OBJECT
		var rand_rule:RuleConfig = rule_set[randi_range(0, rule_set.size() - 1)]
		var max_range:int
		
		# BEATS doesn't have an associated object, so we don't want to try and assign
		# an object to it
		if rand_rule.effect == GameplayUtils.EFFECT.BEATS:
			max_range = 1
		else:
			max_range = 2

		match(randi_range(0, max_range)):
			0:
				object_from_rule = rand_rule.left_object
			1:
				object_from_rule = rand_rule.right_object
			2:
				object_from_rule = GameplayUtils.get_object_from_effect(rand_rule.effect)
		
		item.cartridge = GameplayUtils.get_config_from_object(object_from_rule)
		item.num_uses = randi_range(min_uses, max_uses)
		item.establish_price()
		inventory.append(item)
	
	for i:int in range(rand_transmitters):
		var item:DisposableShopItem = DisposableShopItem.new()
		var rand_obj:GameplayUtils.OBJECT = randi_range(0, GameplayUtils.OBJECT.size() - 1) as GameplayUtils.OBJECT
		
		item.cartridge = GameplayUtils.get_config_from_object(rand_obj)
		item.num_uses = randi_range(min_uses, max_uses)
		item.establish_price()
		inventory.append(item)
		
	
	return inventory
