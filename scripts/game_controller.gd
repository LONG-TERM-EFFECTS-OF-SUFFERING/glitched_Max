extends Node

var game: Data
var _path: String = "res://savegame.tres"
var level: int = 1


func _ready() -> void:
		game = Data.new()


func increment_level() -> void:
	level += 1

func save_game() -> void:
	game.level = level

	ResourceSaver.save(game, _path)

func load_game() -> void:
	if ResourceLoader.exists(_path):
		game = load(_path)

		level = game.level
