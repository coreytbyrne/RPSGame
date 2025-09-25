extends Target
class_name ObjectTarget

var assignment:GameplayUtils.OBJECT
var temp_assignment:GameplayUtils.OBJECT

signal committed_assignment()
signal updated_assignment()

func _ready() -> void:
	wire_connection_point = $WireConnection.global_position


func update_assignment(new_assignment:GameplayUtils.OBJECT) -> void:
		temp_assignment = new_assignment
		updated_assignment.emit()


func revert_assignment() -> void:
	temp_assignment = assignment
	updated_assignment.emit()


# Some color/visual change most likely
func commit_assignment() -> void:
	assignment = temp_assignment
	committed_assignment.emit()
