extends Node3D

@export var rotation_speed: float = 0.5

@onready var _camera: Camera3D = $Camera3D
@onready var _skin: Node3D = $PlayerSkin
@onready var _anim_player: AnimationPlayer = _skin.get_node("AnimationPlayer")


func _ready() -> void:
	# Play the "die" animation when the Game Over screen loads
	_anim_player.play("die")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	# Calculate the rotation angle for this frame
	var angle = rotation_speed * delta

	# Rotate the camera's position around the Y axis (Vector3.UP)
	_camera.position = _camera.position.rotated(Vector3.UP, angle)

	# Make the camera look at the player (offset by 1 unit up to look at the body/head)
	_camera.look_at(_skin.position + Vector3(0, 1, 0))
