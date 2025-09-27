extends Participant
class_name Opponent

## Placeholder for testing
@export var played_object:GameplayUtils.OBJECT
#var wire_count_modifer:int = 0


func get_played_object() -> GameplayUtils.OBJECT:
	return played_object
