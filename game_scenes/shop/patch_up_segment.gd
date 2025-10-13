extends ShopSegment
class_name ServiceSegment

## The Patch Up shop doesn't sell items, it sells mid-encounter heals/fixes
## It will repair your stuff in the middle of an encounter, but it doesn't 
## sell the repair kits that can be kept + used later. That's in the Utility Shop
enum POSSIBLE_INVENTORY {
	PLUG_REPAIR, # Fixes broken plugs 
	TRANSMITTER_REPAIR, # Fixes broken transmitter 
	
	DOSE_REDUCE, # Heal 
	STATUS_EFFECT_CLEAR, # Removes any outstanding status effects 
	SWAP_CHARGE_REFRESH # Adds 100 to your swap charge 
}
