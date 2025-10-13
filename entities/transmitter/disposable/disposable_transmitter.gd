extends Transmitter
class_name DisposableTransmitter

@export var num_uses:int = 3 :
	set(value):
		$RemainingUseLabel.text = str(value)
		num_uses = value


func transmitter_used() -> void:
	num_uses -= 1
	
	if num_uses <= 0:
		print("Transmitter used up!")
		queue_free()
		
	if cooldown > 0:
		cooldown_count = cooldown
