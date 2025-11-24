extends Area3D


@export var sound_player: AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _on_body_entered(_body: Node3D) -> void:
	sound_player.reparent(get_parent())
	sound_player.play()
	queue_free()
