extends VBoxContainer

@export var principal_scene: PackedScene

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_packed(principal_scene)


func _on_continue_pressed() -> void:
	GameController.load_game()
	get_tree().change_scene_to_packed(principal_scene)


func _on_instructions_pressed() -> void:
	pass # Replace with function body.
