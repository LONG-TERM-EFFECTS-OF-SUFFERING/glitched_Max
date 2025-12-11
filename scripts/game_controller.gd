extends Node

# Signals to notify other parts of the game about events
signal update_coins_labels
signal lives_changed
signal display_dialog(image: Texture2D, text: String)
signal interaction_hint(is_visible: bool)
signal update_stamina(current: float, maximum: float)   # Used in player.gd & hud.gd

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
		
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("add_stamina"):
			player.add_stamina(20.0)

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
		collected_coins_number = collected_coins.size()

func reset_level_data() -> void:
	lives = 3
	collected_coins = []
	collected_coins_number = 0
	missing_coins_number = 0

func reset_level() -> void:
	level = 1

func  reset_game_data() -> void:
	reset_level()
	reset_level_data()
	save_game()

func show_dialog(image: Texture2D, text: String) -> void:
	display_dialog.emit(image, text)
	
func toggle_interaction_hint(is_visible: bool) -> void:
	interaction_hint.emit(is_visible)
