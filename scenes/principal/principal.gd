extends Node3D

@export var levels: Array[PackedScene]

var _actual_level = 1
var _actual_level_instance: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameController.level > 1:
		_load_level()
	else:
		_create_level(_actual_level)


func _create_level(level: int) -> void:
	_actual_level_instance = levels[level - 1].instantiate()
	add_child(_actual_level_instance)

func _delete_actual_level() -> void:
	_actual_level_instance.queue_free()

func _restart_level() -> void:
	_delete_actual_level()
	_create_level.call_deferred(_actual_level)
	
	var children = _actual_level_instance.find_children("*", "Node", true, false)
	
	for child in children:
		if child.is_in_group("player"):
			child.dead.connect(_restart_level)
			break
	GameController.save_game()

func next_level() -> void:
	_actual_level += 1
	GameController.increment_level()
	_delete_actual_level()
	_create_level.call_deferred(_actual_level)

func _load_level() -> void:
	_actual_level = GameController.level
	_create_level.call_deferred(_actual_level)
