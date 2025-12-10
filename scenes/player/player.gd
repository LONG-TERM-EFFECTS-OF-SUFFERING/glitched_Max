class_name Player extends CharacterBody3D

signal dead

@export_group("Camera")
@export var tilt_upper_limit: float = PI / 3.0
@export var tilt_lower_limit: float = -PI / 6.0
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25
@export var death_camera_tilt_duration: float = 0.5
@export var death_camera_tilt_angle: float = - PI / 2.0

@onready var _camera_pivot: Node3D = $CameraPivot

@export_group("Movement")
@export var speed: float = 5.0
@export var jump_velocity: float = 3.0
@export var rotation_speed: float = 12.0

@onready var _skin: Node3D = $Skin
@onready var _anim_player: AnimationPlayer = _skin.get_node("AnimationPlayer")
@onready var _footstep_sound: AudioStreamPlayer = $FootstepSound
@onready var _jump_sound: AudioStreamPlayer = $JumpSound
@onready var _land_sound: AudioStreamPlayer = $LandSound
@onready var _game_over_sound: AudioStreamPlayer = $GameOverSound

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction = Vector3.FORWARD
var _death_tween: Tween


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
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	var was_on_floor = is_on_floor()

	var is_falling = false
	var is_jumping = false

	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		is_falling = true

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true
		_jump_sound.play()

	# Handle WASD
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (_camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.2:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		_last_movement_direction = direction
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	if not was_on_floor and is_on_floor():
		_land_sound.play()

	var align_axis := Vector3.UP
	if is_on_floor():
		align_axis = get_floor_normal()

	var right_axis := align_axis.cross(_last_movement_direction).normalized()
	var forward_axis := right_axis.cross(align_axis).normalized()

	var target_basis := Basis(right_axis, align_axis, forward_axis)
	_skin.global_transform.basis = _skin.global_transform.basis.slerp(target_basis, rotation_speed * delta).orthonormalized()

	if is_jumping:
		_anim_player.play("jump")
	elif is_falling:
		_anim_player.play("fall")
	elif is_on_floor():
		if velocity.length() > 0:
			_anim_player.play("walk")
			if not _footstep_sound.playing:
				_footstep_sound.play()
		else:
			_anim_player.play("idle")
			_footstep_sound.stop()

func die() -> void:
	_game_over_sound.play()
	_anim_player.play("die")
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	dead.emit()
	
func die_falling() -> void:
	_game_over_sound.play()
	_anim_player.play("die_falling")
	set_physics_process(false)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_animate_death_camera()
	
	await get_tree().create_timer(1.0).timeout
	dead.emit()

func _animate_death_camera() -> void:
	if _death_tween:
		_death_tween.kill()
	
	_death_tween = create_tween()
	_death_tween.set_parallel(true)
	
	_death_tween.tween_property(
		_camera_pivot,
		"rotation:x",
		death_camera_tilt_angle,
		death_camera_tilt_duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
