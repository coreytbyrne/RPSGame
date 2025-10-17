extends Node2D
class_name SpinnerTile

@export var current_tile:Texture
@export var next_tile:Texture

const character_list:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const tile_file_path:String = "res://entities/spinner_tile/tile_images/%s_Tile.png"

signal letter_updated


func _ready() -> void:
	$NextTileTop.texture = next_tile
	$NextTileBottom.texture = next_tile
	
	$CurrentTileTop.texture = current_tile
	$CurrentTileBottom.texture = current_tile
	


func spin_to_letter(character:String, num_spins:int) -> void:
	var file_name:String
	
	if character == "" or character == " ":
		file_name = tile_file_path % "blank"
	else:
		file_name = tile_file_path % character.to_upper()
	var character_file:Texture = load(file_name)
	
	for i:int in range(num_spins - 1):
		var rand_letter:String = character_list[randi() % len(character_list)]
		var rand_file:Texture = load(tile_file_path % rand_letter)
		$NextTileTop.texture = rand_file
		$NextTileBottom.texture = rand_file
		
		$AnimationPlayer.play("flip_tile_down")
		await $AnimationPlayer.animation_finished
		$CurrentTileTop.texture = rand_file
		$CurrentTileBottom.texture = rand_file
		
	$NextTileTop.texture = character_file
	$NextTileBottom.texture = character_file
	
	$AnimationPlayer.play("flip_tile_down")
	await $AnimationPlayer.animation_finished
	$CurrentTileTop.texture = character_file
	$CurrentTileBottom.texture = character_file
	
	letter_updated.emit()


func spin_to_symbol(symbol:Texture, num_spins:int) -> void:
	if symbol == null:
		spin_to_letter("", num_spins)
		return

	
	for i:int in range(num_spins - 1):
		var rand_letter:String = character_list[randi() % len(character_list)]
		var rand_file:Texture = load(tile_file_path % rand_letter)
		$NextTileTop.texture = rand_file
		$NextTileBottom.texture = rand_file
		
		$AnimationPlayer.play("flip_tile_down")
		await $AnimationPlayer.animation_finished
		$CurrentTileTop.texture = rand_file
		$CurrentTileBottom.texture = rand_file
		
	$NextTileTop.texture = symbol
	$NextTileBottom.texture = symbol
	
	$AnimationPlayer.play("flip_tile_down")
	await $AnimationPlayer.animation_finished
	$CurrentTileTop.texture = symbol
	$CurrentTileBottom.texture = symbol
	
	letter_updated.emit()
