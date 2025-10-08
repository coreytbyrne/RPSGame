extends Participant
class_name Player

@export var default_plug_count:int :
	set(value):
		default_plug_count = value
		remaining_plug_count = value
@export var remaining_plug_count:int :
	set(value):
		$PlugCount.text = "Plugs: %d" % value
		remaining_plug_count = value

@export var swap_charge:int = 100:
	set(value):
		swap_charge_updated.emit(value)
		swap_charge = value
@export var swap_recharge_rate:int = 25
var swap_recharge_modifer:int = 0

var plugs:Array[Plug]
var cartridges:Array[Cartridge]

signal swap_charge_updated(swap_charge:int)

func _ready() -> void:
	$SwapCharge.text = "Swap Charge: %d" % swap_charge


func update_swap_charge(swap_change:int) -> void:
	swap_charge += swap_change
	$SwapCharge.text = "Swap Charge: %d" % swap_charge


func recharge_swap() -> void:
	update_swap_charge(swap_recharge_rate + swap_recharge_modifer)
