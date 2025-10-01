extends Target
class_name ObjectTarget

var assignment:GameplayUtils.OBJECT
var temp_assignment:GameplayUtils.OBJECT

signal committed_assignment
signal updated_assignment
signal reverted_assignment

func _ready() -> void:
	wire_connection_point = $WireConnection.global_position


func set_initial_assignment(object:GameplayUtils.OBJECT) -> void:
	temp_assignment = object
	commit_assignment()


func update_assignment(new_assignment:GameplayUtils.OBJECT) -> void:
		temp_assignment = new_assignment
		updated_assignment.emit()


func revert_assignment() -> void:
	temp_assignment = assignment
	reverted_assignment.emit()


func direct_update(new_assignment:GameplayUtils.OBJECT) -> void:
	temp_assignment = new_assignment
	commit_assignment()


# Some color/visual change most likely
func commit_assignment() -> void:
	assignment = temp_assignment
	committed_assignment.emit()
