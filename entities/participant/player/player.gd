extends Participant
class_name Player

@export var default_plug_count:int :
	set(value):
		default_plug_count = value
		remaining_plug_count = value
@export var remaining_plug_count:int

var plugs:Array[Plug]
var cartridges:Array[Cartridge]
