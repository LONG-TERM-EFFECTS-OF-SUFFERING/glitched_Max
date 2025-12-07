class_name Checkpoint extends Node3D

signal pressed

@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _on_area_3d_body_entered(_body: Node3D) -> void: # It just listen to the player layer
	_anim_player.play("toggle")
	_audio_player.play()
	pressed.emit()
