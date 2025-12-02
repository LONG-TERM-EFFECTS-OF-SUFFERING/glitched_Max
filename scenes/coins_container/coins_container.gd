class_name CoinsContainer extends Node3D

signal level_completed

var _total_coins: int
var _collected_coins: int = 0


func _ready() -> void:
	var coins := get_children()
	_total_coins = coins.size()

	for coin in coins:
		coin.coins_container = self


func collect_coin() -> void:
	_collected_coins += 1

	if _collected_coins == _total_coins:
		level_completed.emit()
