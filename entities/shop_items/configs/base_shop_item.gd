@abstract
class_name ShopItem
extends Resource

@export var item_name: String

@export var base_price:float =  1.00
@export var price_modifier:float = 0.00

@abstract func purchase_item(buyer:Participant)
