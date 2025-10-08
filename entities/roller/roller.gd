extends Node2D
class_name Roller

var current_text:String = ""
var next_text:String = ""


func _ready() -> void:
	$NextText.text = next_text
	$CurrentText.text = current_text


func is_roller_display_matching(desired_next:String) -> bool:
	# Conver to lowercase for consistency
	return current_text.to_lower() == desired_next.to_lower()


func roll(next:String) -> void:
	$NextText.text = next
	$AnimationPlayer.play("roll")
	await $AnimationPlayer.animation_finished
	
	$CurrentText.text = next
	$CurrentText.position = $NextText.position
	$CurrentText.visible = true
	
	$NextText.visible = false
	$NextText.text = ""
	$AnimationPlayer.play("RESET")
	
	
