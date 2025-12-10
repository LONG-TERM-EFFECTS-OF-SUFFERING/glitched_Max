extends Node3D

@export var spawn_radius_outer: float = 15.0 
@export var spawn_radius_inner: float = 5.0   
@export var spawn_height_min: float = -5.0
@export var spawn_height_max: float = 5.0
@export var object_count: int = 60
@export var rotation_speed_min: float = 0.1
@export var rotation_speed_max: float = 0.2
@export var scale_min: float = 0.5
@export var scale_max: float = 3.0
@export var object_opacity: float = 0.3
@export var object_color: Color = Color(0.8, 0.8, 0.8, 1.0)


var models_paths := [
	"res://assets/environment/models/block-grass-low.glb",
	"res://assets/environment/models/fence-low-broken.glb",
	"res://assets/environment/models/crate.glb",
	"res://assets/environment/models/barrel.glb",
	"res://assets/environment/models/rocks.glb",
	"res://assets/environment/models/poles.glb",
	"res://assets/environment/models/block-grass-hexagon.glb",
	"res://assets/environment/models/platform.glb",
	"res://assets/environment/models/crate-strong.glb",
	"res://assets/environment/models/spike-block.glb",
	"res://assets/environment/models/tree-pine.glb",
]


var objects_data := []

func _ready() -> void:
	spawn_objects()

func spawn_objects() -> void:
	for i in range(object_count):
		var model_path = models_paths.pick_random()
		var scene = load(model_path)
		if !scene:
			print("Error cargando: ", model_path)
			continue
			
		var obj = scene.instantiate()
		
		var angle = randf() * TAU
		var radius = randf_range(spawn_radius_inner, spawn_radius_outer)
		var height = randf_range(spawn_height_min, spawn_height_max)
		
		obj.position = Vector3(
			cos(angle) * radius,  # X
			height,               # Y 
			sin(angle) * radius   # Z
		)
		
		obj.rotation = Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		)
		
		# Escala aleatoria
		var scale_val = randf_range(scale_min, scale_max)
		obj.scale = Vector3.ONE * scale_val
		
		add_child(obj)
		apply_ghost_material(obj)
		
		var rotation_data = {
			"node": obj,
			"rotation_axis": _random_rotation_axis(),
			"rotation_speed": randf_range(rotation_speed_min, rotation_speed_max)
		}
		objects_data.append(rotation_data)

func apply_ghost_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		
		var mat := StandardMaterial3D.new()
		mat.albedo_color = object_color
		mat.albedo_color.a = object_opacity
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  
		mat.disable_receive_shadows = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED  
		
		for i in range(mesh_instance.get_surface_override_material_count()):
			mesh_instance.set_surface_override_material(i, mat)
	
	for child in node.get_children():
		apply_ghost_material(child)

func _process(delta: float) -> void:
	for data in objects_data:
		if is_instance_valid(data.node):
			data.node.rotate(data.rotation_axis, data.rotation_speed * delta)

func _random_rotation_axis() -> Vector3:
	var axes = [
		Vector3.UP,           # Solo Y
		Vector3.RIGHT,        # Solo X
		Vector3.FORWARD,      # Solo Z
		Vector3(1, 1, 0).normalized(),  
		Vector3(1, 0, 1).normalized(),  
		Vector3(0, 1, 1).normalized(),    
		Vector3(1, 1, 1).normalized()   
	]
	return axes.pick_random()
