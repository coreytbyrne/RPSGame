extends Button
class_name ShopItem

@export var item_name:String
@export var item_price:float
@export var available_qty:int
# var item_lookup_name (or something like that)
## This should have a variable that contains a relevant/standardized piece of info that can be
## used to perform a lookup/generate the object that is being purchased. Will probably be easier
## this way for setting up Opponent purchases later.

func _ready() -> void:
	text = item_name
	$PriceTag.text = "$%.2f" % item_price
