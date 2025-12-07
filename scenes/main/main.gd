extends Node3D

@export var levels: Array[PackedScene]

var _actual_level := 1
var _actual_level_instance: Node3D


func _ready() -> void:
	if GameController.level > 1 or GameController.collected_coins:
		_load_level()
	else:
		_create_level(_actual_level)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
			GameController.save_game()


func _create_level(level: int) -> void:
	_actual_level_instance = levels[level - 1].instantiate()
	add_child(_actual_level_instance)

	var children = _actual_level_instance.find_children("*", "Node", true, false)
	var player_found := false
	var coin_container_found := false
	var checkpoint_found := false
	for child in children:
		if player_found and coin_container_found and checkpoint_found:
			break

		if child is Player:
			player_found = true
			child.dead.connect(_restart_level)
		elif child is CoinsContainer:
			coin_container_found = true
			child.level_completed.connect(next_level)
		elif child is Checkpoint:
			checkpoint_found = true
			child.pressed.connect(set_checkpoint)

func set_checkpoint() -> void:
	GameController.save_game()

func _delete_actual_level() -> void:
	_actual_level_instance.queue_free()

func _restart_level() -> void:
	GameController.decrement_lives()

	if GameController.lives > 0:
		_delete_actual_level()
		_create_level.call_deferred(_actual_level)
	else:
		print("the player has died") # Go to the Game Over screen

func next_level() -> void:
	_actual_level += 1
	GameController.increment_level()
	_delete_actual_level()
	_create_level.call_deferred(_actual_level)

func _load_level() -> void:
	_actual_level = GameController.level
	_create_level.call_deferred(_actual_level)
