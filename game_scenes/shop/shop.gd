extends Node2D
class_name Shop

## Using separate nodes to categorize item types. If the item type is not available in one of the 
## shop types, we can just disable it entirely. 

@onready var repair_shop:ShopSegment = $Repairs
@onready var utility_shop:ShopSegment  = $Utility
@onready var disposable_cart_shop:ShopSegment  = $DisposableCartridges
@onready var new_cart_shop:ShopSegment  = $NewCartridges
@onready var upgrade_shop:ShopSegment  = $Upgrades


## Repair, Utility, and Disposable Carts are always present 
## Inventory will change depending on if we're in the middle of an encounter or not
##
## New Carts and Upgrade will only be available in between encounters
