extends Node3D

@export var levels: Array[PackedScene]
@export var game_over: PackedScene

var _actual_level := 1
var _actual_level_instance: Node3D


func _ready() -> void:
	if GameController.level > 1 or GameController.collected_coins:
		_load_level()
	else:
		_create_level(_actual_level)


func _create_level(level: int) -> void:
	_actual_level_instance = levels[level - 1].instantiate()
	add_child(_actual_level_instance)

	# Find the Player
	var players = _actual_level_instance.find_children("*", "Player", true, false)
	if players:
		players[0].dead.connect(_restart_level)

	# Find the CoinsContainer
	var coin_containers = _actual_level_instance.find_children("*", "CoinsContainer", true, false)
	if coin_containers:
		coin_containers[0].level_completed.connect(_next_level)

	# Find the Checkpoint
	var checkpoints = _actual_level_instance.find_children("*", "Checkpoint", true, false)
	if checkpoints:
		checkpoints[0].pressed.connect(_set_checkpoint)

func _set_checkpoint() -> void:
	GameController.save_game()

func _delete_actual_level() -> void:
	_actual_level_instance.queue_free()

func _restart_level() -> void:
	GameController.decrement_lives()

	if GameController.lives > 0:
		_delete_actual_level()
		_create_level.call_deferred(_actual_level)
	else:
		get_tree().change_scene_to_packed(game_over)

func _next_level() -> void:
	_actual_level += 1
	GameController.increment_level()
	GameController.reset_level_data()
	_delete_actual_level()
	_create_level.call_deferred(_actual_level)

func _load_level() -> void:
	_actual_level = GameController.level
	_create_level.call_deferred(_actual_level)
