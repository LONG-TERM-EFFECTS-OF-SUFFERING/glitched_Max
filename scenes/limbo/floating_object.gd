extends Node3D

@export var float_speed: float = 0.3
@export var rotation_speed: float = 0.2
@export var sway_amount: float = 1.0
@export var fade_distance: float = 30.0

var time: float = 0.0
var initial_position: Vector3
var random_offset: Vector3

func _ready() -> void:
	initial_position = global_position
	# Offset aleatorio para que no se muevan sincronizados
	random_offset = Vector3(
		randf() * TAU,
		randf() * TAU,
		randf() * TAU
	)
	
	# Transparencia inicial aleatoria
	modulate_transparency(randf_range(0.2, 0.6))

func _process(delta: float) -> void:
	time += delta
	
	# Movimiento flotante sinusoidal
	var offset = Vector3(
		sin(time * float_speed + random_offset.x) * sway_amount,
		cos(time * float_speed * 0.7 + random_offset.y) * sway_amount * 0.5,
		sin(time * float_speed * 0.5 + random_offset.z) * sway_amount
	)
	
	global_position = initial_position + offset
	
	# Rotación lenta
	rotation.y += rotation_speed * delta
	rotation.x += rotation_speed * 0.5 * delta
	
	# Fade por distancia (si hay cámara)
	var camera = get_viewport().get_camera_3d()
	if camera:
		var distance = global_position.distance_to(camera.global_position)
		var alpha = clamp(1.0 - (distance / fade_distance), 0.1, 0.6)
		modulate_transparency(alpha)

func modulate_transparency(alpha: float) -> void:
	# Aplicar transparencia a todos los MeshInstance3D hijos
	for child in get_children():
		if child is MeshInstance3D:
			var mat = child.get_active_material(0)
			if mat:
				mat = mat.duplicate()
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = alpha
				child.set_surface_override_material(0, mat)
