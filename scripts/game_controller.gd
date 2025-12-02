extends Node

var game: Data
var _path: String = "res://savegame.tres"
var level: int = 1
var collected_coins: Array[String] = []


func _ready() -> void:
		game = Data.new()


func collect_coin(coin_id: String) -> void:
	if not coin_id in collected_coins:
		collected_coins.append(coin_id)

func is_coin_collected(coin_id: String) -> bool:
	return coin_id in collected_coins

func increment_level() -> void:
	level += 1

func save_game() -> void:
	game.level = level
	game.collected_coins = collected_coins

	ResourceSaver.save(game, _path)

func load_game() -> void:
	if ResourceLoader.exists(_path):
		game = load(_path)

		level = game.level
		collected_coins = game.collected_coins
