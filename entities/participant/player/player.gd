extends Participant
class_name Player

@export var default_plug_count:int :
	set(value):
		default_plug_count = value
		remaining_plug_count = value
		
@export var remaining_plug_count:int :
	set(value):
		remaining_plug_count = value
		$PlugCount.update_word("Plugs " + str(value), 1, 3)
		#update_plug_label()

@export var swap_charge:int = 100:
	set(value):
		swap_charge_updated.emit(value)
		$SwapCharge.update_word("Charge " + str(value),1,3)
		swap_charge = value
@export var swap_recharge_rate:int = 25
var swap_recharge_modifer:int = 0

var plugs:Array[Plug]
var transmitters:Array[Transmitter]

signal swap_charge_updated(swap_charge:int)

func _ready() -> void:
	super._ready()
	spinner_dose_node.position = $DoseLocation.position
	spinner_name_node.position = $NameLocation.position
	spinner_status_node.position = $StatusLocation.position
	$SwapCharge.update_word("Charge " + str(swap_charge))
	


#func update_plug_label() -> void:
	#$PlugCount.text = "Plugs: %d" % [remaining_plug_count + plug_count_modifier]


func update_swap_charge(swap_change:int) -> void:
	swap_charge += swap_change


func recharge_swap() -> void:
	update_swap_charge(swap_recharge_rate + swap_recharge_modifer)
