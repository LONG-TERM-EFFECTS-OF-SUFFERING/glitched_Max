class_name Kate extends Node3D

@export_multiline var intro_text: String = "Max! Remember to collect coins to gain stamina and complete the level..."
@export var head_image: Texture2D

@onready var _interaction_area: Area3D = $Area3D

var _can_interact := false


func _ready() -> void:
	# Connect the area signals via code or editor
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _can_interact and event.is_action_pressed("interact"):
		GameController.show_dialog(head_image, intro_text)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_can_interact = true
		GameController.toggle_interaction_hint(true)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		_can_interact = false
		GameController.toggle_interaction_hint(false)
