extends VBoxContainer

@onready var _click_sound: AudioStreamPlayer = $ClickSound


func _on_checkpoint_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	GameController.load_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_main_menu_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_exit_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	get_tree().quit()
