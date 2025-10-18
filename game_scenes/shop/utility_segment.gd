extends ShopSegment
class_name UtilitySegment

enum POSSIBLE_INVENTORY {
	DOSE_REDUCE_KIT, # Health Kit that can be used later 
	PLUG_REPAIR_KIT, # Plug Repair Kit that can be used later 
	TRANSMITTER_REPAIR_KIT, # Transmitter Repair Kit that can be used later 
	SWAP_CHARGE_TONIC, # Swap Charge that can be used later 
	DEFENSE_TONIC, # Gives a "defense" 
	REVERSE_TONIC, # Gives a "reverse"
}


func choose_inventory() -> Array[UtilityShopItem]:
	return []
