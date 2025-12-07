extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var skin: Node3D = $PlayerSkin
@onready var _anim_player: AnimationPlayer = skin.get_node("AnimationPlayer")

@export var rotation_speed: float = 0.5

func _ready() -> void:
	# Play the idle/sit animation when the menu loads
	_anim_player.play("sit")

func _process(delta: float) -> void:
	# Calculate the rotation angle for this frame
	var angle = rotation_speed * delta

	# Rotate the camera's position around the Y axis (Vector3.UP)
	camera.position = camera.position.rotated(Vector3.UP, angle)

	# Make the camera look at the player (offset by 1 unit up to look at the body/head)
	camera.look_at(skin.position + Vector3(0, 1, 0))
