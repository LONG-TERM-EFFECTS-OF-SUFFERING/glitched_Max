class_name Player extends CharacterBody3D

signal dead

@export_group("Camera")
@export var tilt_upper_limit: float = PI / 3.0
@export var tilt_lower_limit: float = -PI / 6.0
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25
@export var death_camera_tilt_duration: float = 0.5
@export var death_camera_tilt_angle: float = - PI / 2.0

@export_group("Movement")
@export var speed: float = 5.0
@export var jump_velocity: float = 3.0
@export var rotation_speed: float = 12.0
@export var max_jumps: int = 2 
@export var double_jump_velocity: float = 4.0

@export_group("Sleep System")
@export var time_until_sleep: float = 20.0

@export_group("Dash System")
@export var dash_speed: float = 10.0 
@export var dash_duration: float = 0.4 
@export var dash_cooldown: float = 1.0
@export var dash_fov_increase: float = 20.0 
@export var dash_fov_duration: float = 0.3  
@export var dash_camera_shake: float = 0.15
@export var max_stamina: float = 100.0
@export var double_jump_stamina_cost: float = 15.0
@export var dash_stamina_cost: float = 25.0
@export var stamina_per_coin: float = 20.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _skin: Node3D = $Skin
@onready var _anim_player: AnimationPlayer = _skin.get_node("AnimationPlayer")
@onready var _footstep_sound: AudioStreamPlayer = $FootstepSound
@onready var _jump_sound: AudioStreamPlayer = $JumpSound
@onready var _double_jump_sound: AudioStreamPlayer = $DoubleJumpSound
@onready var _land_sound: AudioStreamPlayer = $LandSound
@onready var _game_over_sound: AudioStreamPlayer = $GameOverSound
@onready var _dash_sound: AudioStreamPlayer = $DashSound
@onready var _sleep_particles: GPUParticles3D = $Skin/SleepParticles
@onready var _dash_trail: GPUParticles3D = $Skin/DashTrail
@onready var _dash_aura: Node3D = $Skin/DashAura/DashOutline1

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction = Vector3.FORWARD
var _death_tween: Tween

var _idle_timer: float = 0.0
var _is_sleeping: bool = false
var _was_moving_last_frame: bool = false
var _jumps_remaining: int = 2

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _aura_fade_tween: Tween
var _current_stamina: float = 50.0

var _default_fov: float = 75.0
var _camera_shake_offset: Vector3 = Vector3.ZERO
var _fov_tween: Tween
var _double_jump_trail_timer: float = 0.0

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

func _ready() -> void:
	_default_fov = _camera.fov
	_current_stamina = max_stamina / 2.0  
	GameController.update_stamina.connect(_on_stamina_changed)

func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	var was_on_floor = is_on_floor()

	var is_falling = false
	var is_jumping = false

	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta
		
	if _double_jump_trail_timer > 0:
		_double_jump_trail_timer -= delta
		if _double_jump_trail_timer <= 0:
			_dash_trail.emitting = false
			
	if is_on_floor():
		_jumps_remaining = max_jumps

	# Add the gravity
	if not is_on_floor() and not _is_dashing:
		velocity += get_gravity() * delta
		if velocity.y < 0:
			is_falling = true
		else:
			is_jumping = true

	# Handle jump
	if Input.is_action_just_pressed("jump"):

		if is_on_floor():
			velocity.y = jump_velocity
			_jumps_remaining = max_jumps - 1
			_jump_sound.play()
			_wake_up()

		elif _jumps_remaining > 0 and _current_stamina >= double_jump_stamina_cost:
			velocity.y = double_jump_velocity
			_jumps_remaining -= 1
			_current_stamina -= double_jump_stamina_cost
			_update_stamina_ui()
			_double_jump_sound.play()
			_wake_up()
			_show_aura()
			_dash_trail.emitting = true
			_double_jump_trail_timer = 0.2  
		
		
	# Handle WASD
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (_camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# Handle dash
	if Input.is_action_just_pressed("dash") and not is_on_floor() and _dash_cooldown_timer <= 0 and not _is_dashing and _current_stamina >= dash_stamina_cost:
		_start_dash(direction if direction.length() > 0 else _last_movement_direction)

	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0:
			_is_dashing = false
			_dash_trail.emitting = false  
		else:
			velocity.x = _dash_direction.x * dash_speed
			velocity.z = _dash_direction.z * dash_speed
			velocity.y = 0  

	var is_moving = direction.length() > 0.2
	
	if is_moving and not _was_moving_last_frame:
		_wake_up()
	
	_was_moving_last_frame = is_moving

	if not _is_dashing:
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
		_fade_out_aura()

	var align_axis := Vector3.UP
	if is_on_floor():
		align_axis = get_floor_normal()

	var right_axis := align_axis.cross(_last_movement_direction).normalized()
	var forward_axis := right_axis.cross(align_axis).normalized()

	var target_basis := Basis(right_axis, align_axis, forward_axis)
	_skin.global_transform.basis = _skin.global_transform.basis.slerp(target_basis, rotation_speed * delta).orthonormalized()

	_update_camera_shake(delta)

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
	
	if _is_dashing:
		_anim_player.play("air-dash_001", 0.05) 
	elif is_jumping and _jumps_remaining < max_jumps - 1:
		_anim_player.play("double-jump", 0.1)
	elif is_jumping:
		_anim_player.play("jump2",0.1)
	elif is_falling:
		_anim_player.play("fall_character-male-e",0.1)
	elif is_on_floor():
		if is_moving:
			_anim_player.play("walk",0.2)
			if not _footstep_sound.playing:
				_footstep_sound.play()
		else:
			_anim_player.play("idle",0.2)
			_footstep_sound.stop()

func _go_to_sleep() -> void:
	_is_sleeping = true
	
	if _anim_player.has_animation("sleep"):
		_anim_player.play("sleep_001",0.3)
	else:
		print("✗ ERROR: No existe la animación 'sleep'")
		print("Reproduciendo 'sit' como alternativa...")
		if _anim_player.has_animation("sit"):
			_anim_player.play("sit",0.3)
		else:
			_anim_player.play("idle",0.3)
	
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
	
	_anim_player.play("idle",0.2)
	
func _start_dash(direction: Vector3) -> void:
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dash_direction = direction.normalized()
	_current_stamina -= dash_stamina_cost
	_update_stamina_ui()
	_wake_up()
	_dash_trail.emitting = true	
	_show_aura()
	_apply_dash_camera_effects()
	_dash_sound.play()
	
func _show_aura() -> void:
	if _aura_fade_tween:
		_aura_fade_tween.kill()
	
	_dash_aura.visible = true
	var material = _dash_aura.material_override as ShaderMaterial
	if material:
		var current_color: Color = material.get_shader_parameter("aura_color")
		material.set_shader_parameter("aura_color", Color(current_color.r, current_color.g, current_color.b, 1.0))

func _fade_out_aura() -> void:
	if _aura_fade_tween:
		_aura_fade_tween.kill()
	
	var material = _dash_aura.material_override as ShaderMaterial
	if not material:
		_dash_aura.visible = false
		return
	
	_aura_fade_tween = create_tween()
	_aura_fade_tween.set_ease(Tween.EASE_OUT)
	_aura_fade_tween.set_trans(Tween.TRANS_CUBIC)
	
	var current_color: Color = material.get_shader_parameter("aura_color")	

	_aura_fade_tween.tween_method(
		func(value: float):
			material.set_shader_parameter("aura_color", Color(current_color.r, current_color.g, current_color.b, value)),
		current_color.a,
		0.0,
		1.0 
	)
	
	_aura_fade_tween.tween_callback(func(): _dash_aura.visible = false)

func _update_camera_shake(delta: float) -> void:
	_camera_shake_offset = _camera_shake_offset.lerp(Vector3.ZERO, delta * 15.0)
	_camera.position = _camera_shake_offset

func _apply_dash_camera_effects() -> void:
	if _fov_tween:
		_fov_tween.kill()
	
	_fov_tween = create_tween()
	_fov_tween.set_ease(Tween.EASE_OUT)
	_fov_tween.set_trans(Tween.TRANS_CUBIC)
	
	_fov_tween.tween_property(_camera, "fov", _default_fov + dash_fov_increase, 0.1)
	_fov_tween.tween_property(_camera, "fov", _default_fov, dash_fov_duration)
	
	var shake_tween = create_tween()
	shake_tween.set_ease(Tween.EASE_IN_OUT)
	shake_tween.set_trans(Tween.TRANS_SINE)
	
	for i in range(4):
		var random_offset = Vector3(
			randf_range(-dash_camera_shake, dash_camera_shake),
			randf_range(-dash_camera_shake, dash_camera_shake),
			0
		)
		shake_tween.tween_property(self, "_camera_shake_offset", random_offset, 0.05)
		
	shake_tween.tween_property(self, "_camera_shake_offset", Vector3.ZERO, 0.1)

func add_stamina(amount: float) -> void:
	var old_stamina = _current_stamina
	_current_stamina = min(_current_stamina + amount, max_stamina)
	print("Stamina añadida: ", amount, " (", old_stamina, " -> ", _current_stamina, ")")  # Debug
	_update_stamina_ui()
	
func _update_stamina_ui() -> void:
	print("Emitiendo señal update_stamina: ", _current_stamina, "/", max_stamina)  # Debug
	GameController.update_stamina.emit(_current_stamina, max_stamina)

func _on_stamina_changed() -> void:
	pass  # Placeholder por si necesitas reaccionar a cambios externos

func get_stamina_percentage() -> float:
	return (_current_stamina / max_stamina) * 100.0
