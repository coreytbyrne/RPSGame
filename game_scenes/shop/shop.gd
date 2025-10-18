extends Node2D
class_name Shop

## Using separate nodes to categorize item types. If the item type is not available in one of the 
## shop types, we can just disable it entirely. 

@onready var service_shop:ShopSegment = $Services
@onready var utility_shop:ShopSegment  = $Utility
@onready var disposable_transmitter_shop:ShopSegment  = $DisposableTransmitters
@onready var new_cart_shop:ShopSegment  = $NewCartridges
@onready var upgrade_shop:ShopSegment  = $Upgrades

#@export var available_shop_segments:Array[ShopSegment.SEGMENT_TYPE]
@export var shop_type:TYPE

@export var active_rule_set:Array[RuleConfig]

## Repair, Utility, and Disposable Carts are always present 
## Inventory will change depending on if we're in the middle of an encounter or not
##
## New Carts and Upgrade will only be available in between encounters
enum TYPE {ENCOUNTER, ROUND_END}

func _ready() -> void:
	generate_shop(TYPE.ROUND_END, active_rule_set)


func generate_shop(type:TYPE, rule_set:Array[RuleConfig] = []) -> void:
	match(type):
		TYPE.ENCOUNTER:
			generate_mid_encounter_shop(rule_set)
		TYPE.ROUND_END:
			generate_post_encounter_shop()


func generate_mid_encounter_shop(rule_set:Array[RuleConfig]) -> void:
	#service_shop.choose_inventory()
	var disposable_transmitters:Array[DisposableShopItem] = disposable_transmitter_shop.choose_inventory(rule_set)
	#utility_shop.choose_inventory()
	return


func generate_post_encounter_shop() -> void:
	service_shop.choose_inventory()
	var disposable_transmitters:Array[DisposableShopItem] = disposable_transmitter_shop.choose_inventory()
	utility_shop.choose_inventory()
	upgrade_shop.choose_inventory()
	new_cart_shop.choose_inventory()
