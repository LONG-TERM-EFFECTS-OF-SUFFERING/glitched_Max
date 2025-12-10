extends Node3D

@export var spawn_radius_outer: float = 20.0
@export var spawn_radius_inner: float = 8.0
@export var spawn_height_min: float = -3.0
@export var spawn_height_max: float = 8.0
@export var sprite_count: int = 30
@export var scale_min: float = 0.8
@export var scale_max: float = 3.5
@export var fade_in_duration: float = 2.0
@export var fade_out_duration: float = 2.0
@export var visible_duration_min: float = 3.0
@export var visible_duration_max: float = 8.0
@export var opacity_min: float = 0.2
@export var opacity_max: float = 0.6
@export var stains_folder_path: String = "res://assets/images/stains/"

var sprites_data := []
var stain_textures: Array[Texture2D] = []

func _ready() -> void:
	print("FloatingStainSpawner iniciado")
	load_stain_textures()
	
	if stain_textures.is_empty():
		push_error("No se encontraron texturas de manchas en: ", stains_folder_path)
		return
	
	print("✓ ", stain_textures.size(), " texturas cargadas")
	spawn_sprites()

func load_stain_textures() -> void:
	var dir = DirAccess.open(stains_folder_path)
	
	if !dir:
		push_error("No se pudo abrir la carpeta: ", stains_folder_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".png"):
			var texture_path = stains_folder_path + file_name
			var texture = load(texture_path) as Texture2D
			
			if texture:
				stain_textures.append(texture)
				print("  ✓ Cargada: ", file_name)
			else:
				push_warning("  ✗ Error cargando: ", file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func spawn_sprites() -> void:
	print("Spawneando ", sprite_count, " sprites...")
	
	for i in range(sprite_count):
		var sprite = Sprite3D.new()
		
		var random_texture = stain_textures.pick_random()
		
		sprite.texture = random_texture
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = false
		sprite.double_sided = true
		sprite.no_depth_test = false
		sprite.render_priority = -10
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sprite.modulate = Color(0.8, 0.8, 0.8, 0.0) 
		
		var angle = randf() * TAU
		var radius = randf_range(spawn_radius_inner, spawn_radius_outer)
		var height = randf_range(spawn_height_min, spawn_height_max)
		
		sprite.position = Vector3(
			cos(angle) * radius,
			height,
			sin(angle) * radius
		)
		
		var scale_val = randf_range(scale_min, scale_max)
		sprite.scale = Vector3.ONE * scale_val
		
		sprite.rotation.z = randf() * TAU
		
		add_child(sprite)
		
		var sprite_data = {
			"sprite": sprite,
			"state": "fading_in",
			"timer": randf() * fade_in_duration,
			"max_opacity": randf_range(opacity_min, opacity_max),
			"visible_duration": randf_range(visible_duration_min, visible_duration_max),
			"wait_before_respawn": randf_range(1.0, 4.0),
			"rotation_speed": randf_range(-0.1, 0.1),
			"initial_position": sprite.position,
			"drift_offset": Vector3.ZERO,
			"drift_direction": Vector3(
				randf_range(-0.3, 0.3),
				randf_range(-0.1, 0.1),
				randf_range(-0.3, 0.3)
			)
		}
		
		sprites_data.append(sprite_data)
	
	print("✓ ", sprites_data.size(), " sprites creados")

func _process(delta: float) -> void:
	for data in sprites_data:
		if !is_instance_valid(data.sprite):
			continue
		
		data.timer += delta
		
		match data.state:
			"fading_in":
				_handle_fade_in(data, delta)
			"visible":
				_handle_visible(data, delta)
			"fading_out":
				_handle_fade_out(data, delta)
			"waiting":
				_handle_waiting(data)

func _handle_fade_in(data: Dictionary, delta: float) -> void:
	var progress = clamp(data.timer / fade_in_duration, 0.0, 1.0)
	data.sprite.modulate.a = lerp(0.0, data.max_opacity, progress)
	
	data.drift_offset += data.drift_direction * delta * 0.2
	data.sprite.position = data.initial_position + data.drift_offset
	data.sprite.rotation.z += data.rotation_speed * delta
	
	if data.timer >= fade_in_duration:
		data.state = "visible"
		data.timer = 0.0

func _handle_visible(data: Dictionary, delta: float) -> void:
	data.sprite.modulate.a = data.max_opacity
	
	data.drift_offset += data.drift_direction * delta * 0.2
	data.sprite.position = data.initial_position + data.drift_offset
	data.sprite.rotation.z += data.rotation_speed * delta
	
	if data.timer >= data.visible_duration:
		data.state = "fading_out"
		data.timer = 0.0

func _handle_fade_out(data: Dictionary, delta: float) -> void:
	var progress = clamp(data.timer / fade_out_duration, 0.0, 1.0)
	data.sprite.modulate.a = lerp(data.max_opacity, 0.0, progress)
	
	data.drift_offset += data.drift_direction * delta * 0.2
	data.sprite.position = data.initial_position + data.drift_offset
	data.sprite.rotation.z += data.rotation_speed * delta
	
	if data.timer >= fade_out_duration:
		data.state = "waiting"
		data.timer = 0.0

func _handle_waiting(data: Dictionary) -> void:
	if data.timer >= data.wait_before_respawn:
		_respawn_sprite(data)

func _respawn_sprite(data: Dictionary) -> void:
	data.sprite.texture = stain_textures.pick_random()
	
	var angle = randf() * TAU
	var radius = randf_range(spawn_radius_inner, spawn_radius_outer)
	var height = randf_range(spawn_height_min, spawn_height_max)
	
	data.initial_position = Vector3(
		cos(angle) * radius,
		height,
		sin(angle) * radius
	)
	
	data.drift_offset = Vector3.ZERO
	data.sprite.position = data.initial_position
	
	var scale_val = randf_range(scale_min, scale_max)
	data.sprite.scale = Vector3.ONE * scale_val
	
	data.sprite.rotation.z = randf() * TAU
	
	data.max_opacity = randf_range(opacity_min, opacity_max)
	data.visible_duration = randf_range(visible_duration_min, visible_duration_max)
	data.wait_before_respawn = randf_range(1.0, 4.0)
	data.rotation_speed = randf_range(-0.1, 0.1)
	data.drift_direction = Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.1, 0.1),
		randf_range(-0.3, 0.3)
	)
	
	data.state = "fading_in"
	data.timer = 0.0
