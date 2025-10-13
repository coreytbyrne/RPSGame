extends Node2D
class_name Shop

## Using separate nodes to categorize item types. If the item type is not available in one of the 
## shop types, we can just disable it entirely. 

@onready var service_shop:ShopSegment = $Services
@onready var utility_shop:ShopSegment  = $Utility
@onready var disposable_transmitter_shop:ShopSegment  = $DisposableTransmitters
@onready var new_cart_shop:ShopSegment  = $NewCartridges
@onready var upgrade_shop:ShopSegment  = $Upgrades

@export var available_shop_segments:Array[ShopSegment.SEGMENT_TYPE]
@export var shop_type:TYPE

## Repair, Utility, and Disposable Carts are always present 
## Inventory will change depending on if we're in the middle of an encounter or not
##
## New Carts and Upgrade will only be available in between encounters
enum TYPE {ENCOUNTER, ROUND_END}
