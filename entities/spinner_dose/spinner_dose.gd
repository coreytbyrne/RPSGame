extends Node2D
class_name SpinnerDose

@export var spinner_tile_scene:PackedScene
@export var max_dose:int = 10

@export var empty_vial_left_texture:Texture
@export var full_vial_left_texture:Texture
@export var empty_vial_body_texture:Texture
@export var full_vial_body_texture:Texture
@export var empty_vial_right_texture:Texture
@export var full_vial_right_texture:Texture

var buffer_size:int = 16
var current_dose:int
var spinner_tiles:Array[SpinnerTile]


func _ready() -> void:
	for i:int in range(max_dose):
		var new_spinner:SpinnerTile = spinner_tile_scene.instantiate()
		new_spinner.position.x = i * buffer_size
		spinner_tiles.append(new_spinner)
		add_child(new_spinner)
		
		update_dose_value(current_dose)



func update_dose_value(dose:int) -> void:
	for i:int in range(dose):
		if i == 0:
			await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
			spinner_tiles[i].spin_to_symbol(full_vial_left_texture, 1)
		elif (i == max_dose - 1):
			await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
			spinner_tiles[i].spin_to_symbol(full_vial_right_texture, 1)
		else:
			await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
			spinner_tiles[i].spin_to_symbol(full_vial_body_texture, 1)
	
	for i:int in range(dose, max_dose):
		if i == 0:
			await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
			spinner_tiles[i].spin_to_symbol(empty_vial_left_texture, 1)
		elif (i == max_dose - 1):
			await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
			spinner_tiles[i].spin_to_symbol(empty_vial_right_texture, 1)
		else:
			await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
			spinner_tiles[i].spin_to_symbol(empty_vial_body_texture, 1)
	
	
