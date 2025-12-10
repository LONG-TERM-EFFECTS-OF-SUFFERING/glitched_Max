extends Control

@onready var _click_sound: AudioStreamPlayer = $ClickSound


func _on_button_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	queue_free()
