extends ShopSegment
class_name UpgradeSegment

enum POSSIBLE_INVENTORY {
	INVENTORY_SIZE, # Upgrades the number number of items you can keep in your inventory
	PLUG_COUNT, # Upgrades the max number of plugs you can use each round
	TRANSMITTER_COUNT, # Upgrades the max number of transmitters you have available each round
	SWAP_CHARGE_REFRESH_RATE, # Upgrades the amound of SWAP that gets restored after each round
	MAX_DOSAGE # Upgrades the max dosage required before losing
}
