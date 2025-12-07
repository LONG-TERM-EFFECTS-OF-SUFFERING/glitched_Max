extends VBoxContainer

@onready var click_sound: AudioStreamPlayer = $ClickSound

@export var principal_scene: PackedScene


func _on_new_game_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	GameController.reset_game_data()
	get_tree().change_scene_to_packed(principal_scene)


func _on_continue_pressed() -> void:
	click_sound.play()
	await click_sound.finished
	GameController.load_game()
	get_tree().change_scene_to_packed(principal_scene)


func _on_instructions_pressed() -> void:
	click_sound.play()
	await click_sound.finished
