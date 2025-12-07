extends Control

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

@onready var collected_coins_label: Label = $CoinsContainer/CollectedCoins
@onready var missing_coins_label: Label = $CoinsContainer/MissingCoins
@onready var hearts_container: HBoxContainer = $HeartsContainer


func _ready() -> void:
	GameController.update_coins_labels.connect(update_coins_labels)
	GameController.lives_changed.connect(update_lives)
	collected_coins_label.text = "0" + str(GameController.collected_coins_number)
	missing_coins_label.text = "0" + str(GameController.missing_coins_number)
	update_lives()


func update_coins_labels():
	collected_coins_label.text = "0" + str(GameController.collected_coins_number)
	missing_coins_label.text = "0" + str(GameController.missing_coins_number)

func update_lives() -> void:
	# Clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()

	# Add full hearts
	for i in range(GameController.lives):
		var heart = TextureRect.new()
		heart.texture = full_heart
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(heart)

	# Add empty hearts
	for i in range(3 - GameController.lives):
		var heart = TextureRect.new()
		heart.texture = empty_heart
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(heart)
