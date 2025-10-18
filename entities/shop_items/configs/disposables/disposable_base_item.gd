extends ShopItem
class_name DisposableShopItem

@export var cartridge:CartridgeConfig
@export var num_uses:int = 3
var num_use_price_multiplier:float = 1.10

# Base price should be based off of a single use, then incremented for each additional use

func purchase_item(buyer:Participant):
	pass


func create_item() -> DisposableTransmitter:
	var disposable_transmitter:DisposableTransmitter = DisposableTransmitter.new()
	disposable_transmitter.config = cartridge
	disposable_transmitter.num_uses = num_uses
	return disposable_transmitter


func establish_price() -> void:
	var price:float = base_price
	price += ((num_uses - 1) * num_use_price_multiplier)
	price_modifier += cartridge.tier
	base_price = snappedf(price * price_modifier, 0.01)
