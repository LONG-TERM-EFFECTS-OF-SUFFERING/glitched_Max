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

@export_group("Sleep System")
@export var time_until_sleep: float = 25.0

@onready var _skin: Node3D = $Skin
@onready var _anim_player: AnimationPlayer = _skin.get_node("AnimationPlayer")
@onready var _footstep_sound: AudioStreamPlayer = $FootstepSound
@onready var _jump_sound: AudioStreamPlayer = $JumpSound
@onready var _land_sound: AudioStreamPlayer = $LandSound
@onready var _game_over_sound: AudioStreamPlayer = $GameOverSound
@onready var _sleep_particles: GPUParticles3D = $Skin/SleepParticles

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction = Vector3.FORWARD
var _death_tween: Tween

var _idle_timer: float = 0.0
var _is_sleeping: bool = false
var _was_moving_last_frame: bool = false

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
	
	if _is_sleeping:
		if event.is_action("left") or event.is_action("right") or \
		   event.is_action("up") or event.is_action("down") or \
		   event.is_action("jump"):
			if event.is_pressed():
				_wake_up()


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
		_wake_up()  

	# Handle WASD
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (_camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var is_moving = direction.length() > 0.2
	
	if is_moving and not _was_moving_last_frame:
		_wake_up()
	
	_was_moving_last_frame = is_moving

	if is_moving:
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

	_update_animation_state(is_jumping, is_falling, is_moving, delta)

func die() -> void:
	_is_sleeping = false
	_idle_timer = 0.0
	_sleep_particles.emitting = false
	_game_over_sound.play()
	_anim_player.play("die")
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	dead.emit()
	
func die_falling() -> void:
	_is_sleeping = false
	_idle_timer = 0.0
	_sleep_particles.emitting = false
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

func _update_animation_state(is_jumping: bool, is_falling: bool, is_moving: bool, delta: float) -> void:
	if _is_sleeping:
		return
	
	var is_idle = is_on_floor() and not is_moving and not is_jumping and not is_falling
	
	if is_idle:
		_idle_timer += delta
		
		if _idle_timer >= time_until_sleep:
			_go_to_sleep()
			return
	else:
		_idle_timer = 0.0
	
	if is_jumping:
		_anim_player.play("jump")
	elif is_falling:
		_anim_player.play("fall")
	elif is_on_floor():
		if is_moving:
			_anim_player.play("walk")
			if not _footstep_sound.playing:
				_footstep_sound.play()
		else:
			_anim_player.play("idle")
			_footstep_sound.stop()

func _go_to_sleep() -> void:
	_is_sleeping = true
	
	if _anim_player.has_animation("sleep"):
		_anim_player.play("sleep")
	else:
		print("✗ ERROR: No existe la animación 'sleep'")
		print("Reproduciendo 'sit' como alternativa...")
		if _anim_player.has_animation("sit"):
			_anim_player.play("sit")
		else:
			_anim_player.play("idle")
	
	_footstep_sound.stop()
	await get_tree().create_timer(3.5).timeout
	if _is_sleeping:
		_sleep_particles.emitting = true

func _wake_up() -> void:
	if not _is_sleeping:
		return
	
	_is_sleeping = false
	_idle_timer = 0.0
	
	_sleep_particles.restart()
	_sleep_particles.emitting = false
	
	_anim_player.play("idle")
