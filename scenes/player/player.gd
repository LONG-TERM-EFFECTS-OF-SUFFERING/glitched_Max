extends CharacterBody3D

@export_group("Camera")
@export var camera_pivot: Node3D
@export var camera: Camera3D
@export var tilt_upper_limit: float = PI / 3.0
@export var tilt_lower_limit: float = -PI / 6.0
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25

@export_group("Movement")
@export var speed: float = 5.0
@export var jump_velocity: float = 3.0
@export var skin: Node3D
@export var rotation_speed: float = 12.0

@onready var _anim_player: AnimationPlayer = skin.get_node("AnimationPlayer")

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction = Vector3.BACK


func _ready() -> void:
	add_to_group("player")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter_focus"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("exit_focus"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_moving := event is InputEventMouseMotion and \
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

	if is_camera_moving:
		_camera_input_direction = event.screen_relative * mouse_sensitivity


func _physics_process(delta: float) -> void:
	camera_pivot.rotation.x += _camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	var _is_falling = false
	var _is_jumping = false

	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		_is_falling = true

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		_is_jumping = true

	# Handle WASD
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (camera.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() > 0.2:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		_last_movement_direction = direction
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		velocity.z = move_toward(velocity.z, 0, speed * delta)

	move_and_slide()

	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	skin.global_rotation.y = lerp_angle(skin.rotation.y, target_angle, rotation_speed * delta)

	if _is_jumping:
		_anim_player.play("jump")
	elif _is_falling:
		_anim_player.play("fall")
	elif is_on_floor():
		if velocity.length() > 0:
			_anim_player.play("walk")
		else:
			_anim_player.play("idle")
