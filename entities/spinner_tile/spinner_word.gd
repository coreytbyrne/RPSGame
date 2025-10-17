extends Node2D
class_name SpinnerWord

@export var spinner_tile_scene:PackedScene
@export var word_max_length:int = 10

var letter_space:int = 16
var spinner_tiles:Array[SpinnerTile]
var current_word:String


func _ready() -> void:
	for i:int in range(word_max_length):
		var new_spinner:SpinnerTile = spinner_tile_scene.instantiate()
		new_spinner.position.x = i * letter_space
		spinner_tiles.append(new_spinner)
		add_child(new_spinner)



func update_word(new_word:String, min_spins:int = 1, max_spins:int = 1) -> void:
	assert(len(new_word) <= spinner_tiles.size(), "The word provided %s is too long for this spinner (max length = %d)" %[new_word, word_max_length])
	
	for i:int in range(len(new_word)):
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
		spinner_tiles[i].spin_to_letter(new_word[i], randi_range(min_spins, max_spins))
	
	for i:int in range(len(new_word), word_max_length):
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
		spinner_tiles[i].spin_to_letter("", randi_range(min_spins, max_spins))
	
	# TODO: Not sure if this is going to work. Need to find a way to have the function wait until the end of the word is done
	await spinner_tiles[word_max_length - 1].letter_updated
	
	current_word = new_word



func is_word_matching(new_word:String) -> bool:
	return new_word.to_upper() == current_word.to_upper()
