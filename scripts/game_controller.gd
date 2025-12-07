extends Node

# Signals to notify other parts of the game about events
signal update_coins_labels
signal lives_changed

var game: Data
var _path: String = "res://savegame.tres"
var level: int = 1
var lives: int = 3
var collected_coins_number = 0
# Stores unique IDs of collected coins to prevent re-collection
var collected_coins: Array[String] = []
var missing_coins_number = 0


func _ready() -> void:
		# Initialize data container
		game = Data.new()


func collect_coin(coin_id: String) -> void:
	# Only collect if not already collected
	if not coin_id in collected_coins:
		collected_coins_number += 1
		missing_coins_number -= 1
		update_coins_labels.emit()
		collected_coins.append(coin_id)


func is_coin_collected(coin_id: String) -> bool:
	return coin_id in collected_coins

func increment_level() -> void:
	level += 1

func decrement_lives() -> void:
	lives -= 1
	lives_changed.emit()

func save_game() -> void:
	# Update data object with current state
	game.level = level
	game.lives = game.lives
	game.collected_coins = collected_coins

	# Write to disk
	ResourceSaver.save(game, _path)

func load_game() -> void:
	if ResourceLoader.exists(_path):
		game = load(_path)

		# Restore state from loaded data
		level = game.level
		lives = game.lives
		collected_coins = game.collected_coins

func reset_game_data() -> void:
	level = 1
	lives = 3
	# For a hard reset (New Game), we DO want to clear coins
	collected_coins = []
	collected_coins_number = 0
	missing_coins_number = 0
