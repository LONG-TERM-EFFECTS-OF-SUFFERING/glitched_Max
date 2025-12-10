extends VBoxContainer

@onready var _click_sound: AudioStreamPlayer = $ClickSound

const INSTRUCTIONS_SCENE = preload("res://scenes/instructions/instructions.tscn")


func _on_new_game_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	GameController.reset_game_data()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_continue_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	GameController.load_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_instructions_pressed() -> void:
	_click_sound.play()
	await _click_sound.finished
	var instructions = INSTRUCTIONS_SCENE.instantiate()
	get_tree().current_scene.add_child(instructions)
