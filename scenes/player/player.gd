extends CharacterBody3D

@export_group("Camera")
@export var _camera_pivot: Node3D
@export var _camera: Camera3D
@export var _tilt_upper_limit: float = PI / 3.0
@export var _tilt_lower_limit: float = -PI / 6.0
@export_range(0.0, 1.0) var _mouse_sensitivy: float = 0.25

@export_group("Movement")
@export var _speed: float = 5.0
@export var _jump_velocity: float = 3.0
@export var _skin: Node3D
@export var _rotation_speed: float = 12.0

@onready var _anim_player: AnimationPlayer = _skin.get_node("AnimationPlayer")

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction = Vector3.BACK


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter_focus"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("exit_focus"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_moving := event is InputEventMouseMotion and \
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

	if is_camera_moving:
		_camera_input_direction = event.screen_relative * _mouse_sensitivy
		


func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, _tilt_lower_limit, _tilt_upper_limit)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	
	_camera_input_direction = Vector2.ZERO
	
	var _is_falling = false
	var _is_jumping = false

	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		_is_falling = true

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = _jump_velocity
		_is_jumping = true

	# Handle WASD
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (_camera.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() > 0.2:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed

		_last_movement_direction = direction
	else:
		velocity.x = move_toward(velocity.x, 0, _speed * delta)
		velocity.z = move_toward(velocity.z, 0, _speed * delta)

	move_and_slide()
	
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, _rotation_speed * delta)

	if _is_jumping:
		_anim_player.play("jump")
	elif _is_falling:
		_anim_player.play("fall")
	elif is_on_floor():
		if velocity.length() > 0:
			_anim_player.play("walk")
		else:
			_anim_player.play("idle")
