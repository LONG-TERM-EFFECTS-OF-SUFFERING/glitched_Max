extends AnimatableBody3D

@export var move_offset := Vector3(0, 5, 0)
@export var duration := 3.0


func _ready() -> void:
	# Create a tween that runs in the physics process to ensure smooth player movement
	# Loops indefinitely
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Tween to the target position (current + offset)
	tween.tween_property(self, "position", position + move_offset, duration)
	# Tween back to the start position
	tween.tween_property(self, "position", position, duration)
