@tool
extends Area3D

@export var speed: float = 2.0
@export var change_direction_interval: float = 1.0
@export var area_size: Vector2 = Vector2(4, 4):
	set(value):
		area_size = value
		if is_node_ready():
			_update_bounds_scale()

@onready var _bounds: MeshInstance3D = $Bounds
@onready var _skin: Node3D = $SkinPivot
@onready var _collision: CollisionShape3D = $CollisionShape3D

var _previous_direction: Vector3
var _direction: Vector3 = [Vector3.LEFT, Vector3.RIGHT].pick_random()
var _limit_x: float
var _limit_z: float
var _time_since_last_change: float = 0.0
var _tween: Tween


func _ready() -> void:
	# Update visuals immediately so it looks right in editor and game
	_update_bounds_scale()

	if not Engine.is_editor_hint():
		# Runtime logic only
		_limit_x = area_size.x / 2.0
		_limit_z = area_size.y / 2.0


func _physics_process(delta: float) -> void:
	# Do not run physics movement in the editor
	if Engine.is_editor_hint():
		return

	# Calculate the movement step based on direction and speed
	var step = _direction * speed * delta
	var next_pos = _skin.position + step
	var hit_wall = false

	# Check X limits to keep the saw within the defined area
	if next_pos.x > _limit_x:
		next_pos.x = _limit_x
		hit_wall = true
	elif next_pos.x < -_limit_x:
		next_pos.x = -_limit_x
		hit_wall = true

	# Check Z limits to keep the saw within the defined area
	if next_pos.z > _limit_z:
		next_pos.z = _limit_z
		hit_wall = true
	elif next_pos.z < -_limit_z:
		next_pos.z = -_limit_z
		hit_wall = true

	_update_positions(next_pos)

	# If we hit a wall, pick a new direction immediately
	if hit_wall:
		_pick_new_direction()
		_time_since_last_change = 0.0
	else:
		# Otherwise, change direction periodically based on the interval
		_time_since_last_change += delta
		if _time_since_last_change >= change_direction_interval:
			_pick_new_direction()
			_time_since_last_change = 0.0


func _update_bounds_scale() -> void:
	if _bounds and _bounds.mesh is PlaneMesh:
		var mesh_size = _bounds.mesh.size
		if mesh_size.x != 0 and mesh_size.y != 0:
			# Scale the mesh node to match the desired area_size
			_bounds.scale = Vector3(area_size.x / mesh_size.x, 1.0, area_size.y / mesh_size.y)

func _pick_new_direction() -> void:
	var current_pos = _skin.position
	var possible_dirs = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]

	# Filter out directions that would immediately push us out of bounds
	var valid_dirs = []
	for dir in possible_dirs:
		if not _is_blocked(current_pos, dir):
			valid_dirs.append(dir)

	if valid_dirs.size() > 0:
		_previous_direction = _direction
		# Pick a random valid direction to move in
		_direction = valid_dirs.pick_random()
		_rotate_skin()

func _is_blocked(pos: Vector3, dir: Vector3) -> bool:
	var epsilon = 0.01
	if dir.x > 0 and pos.x >= _limit_x - epsilon: return true
	if dir.x < 0 and pos.x <= -_limit_x + epsilon: return true
	if dir.z > 0 and pos.z >= _limit_z - epsilon: return true
	if dir.z < 0 and pos.z <= -_limit_z + epsilon: return true
	return false

func _update_positions(pos: Vector3) -> void:
	_skin.position = pos
	_collision.position = pos

func _rotate_skin() -> void:
	# If moving in the same axis (e.g. left <-> right or forward <-> back),
	# we do not need to rotate the skin visually, or we might want a different animation
	# The dot product is 1 or -1 for parallel vectors, so abs() > 0.9 catches both cases.
	if abs(_previous_direction.dot(_direction)) > 0.9:
		return

	if _tween:
		_tween.kill()
	_tween = create_tween()

	# Rotate the skin 90 degrees relative to its current rotation
	_tween.tween_property(_skin, "rotation:y", deg_to_rad(90.0), 2).as_relative()


func _on_body_entered(body: Node3D) -> void:  # It just listen to the player layer
	body.die()
	# Disable monitoring so this saw cannot kill the player again
	set_deferred("monitoring", false)
