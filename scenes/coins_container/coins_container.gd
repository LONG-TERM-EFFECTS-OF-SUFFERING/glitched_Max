class_name CoinsContainer extends Node3D

signal level_completed

var total_coins: int
var _collected_coins: int = 0


func _ready() -> void:
	# Get all children nodes, which are expected to be coins
	var coins := get_children()
	total_coins = coins.size()

	# Calculate how many coins are missing based on global game state
	_collected_coins = GameController.collected_coins.size()
	GameController.missing_coins_number = total_coins - _collected_coins

	# Assign this container reference to each coin so they can report back when collected
	for coin in coins:
		coin.coins_container = self


func collect_coin() -> void:
	# Increment local counter
	_collected_coins += 1

	# Check if all coins in this container have been collected
	if _collected_coins == total_coins:
		level_completed.emit()
