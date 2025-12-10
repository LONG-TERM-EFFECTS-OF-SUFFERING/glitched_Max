extends VBoxContainer

@onready var _click_sound: AudioStreamPlayer = $ClickSound


func _on_new_game_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	GameController.reset_level()
	GameController.reset_level_data()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_exit_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	get_tree().quit()
