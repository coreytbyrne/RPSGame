extends Node2D
class_name SpinnerStatus

@export var spinner_tile_scene:PackedScene
@export var shield_texture:Texture
@export var reverse_texture:Texture

var buffer_size:int = 16
var spinner_tiles:Array[SpinnerTile]

enum STATUS {SHIELD, REVERSE}

func _ready() -> void:
	for i:int in range(STATUS.size()):
		var new_spinner:SpinnerTile = spinner_tile_scene.instantiate()
		new_spinner.position.x = i * buffer_size
		spinner_tiles.append(new_spinner)
		add_child(new_spinner)

func update_status_value(status:STATUS, is_applied:bool) -> void:
	var new_symbol:Texture

	match(status):
		STATUS.SHIELD:
			new_symbol = shield_texture
		STATUS.REVERSE:
			new_symbol = reverse_texture
	
	if is_applied:
		spinner_tiles[status].spin_to_symbol(new_symbol, 1)
	else:
		spinner_tiles[status].spin_to_letter("", 1)
