extends Control

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

@onready var _collected_coins_label: Label = $CoinsContainer/CollectedCoins
@onready var _missing_coins_label: Label = $CoinsContainer/MissingCoins
@onready var _hearts_container: HBoxContainer = $HeartsContainer
@onready var _interaction_hint: Label = $InteractionHint
@onready var _pause_label: Label = $PauseLabel
@onready var _dialog_box: PanelContainer = $DialogBox
@onready var _dialog_label: Label = $DialogBox/HBoxContainer/Label
@onready var _dialog_face: TextureRect = $DialogBox/HBoxContainer/FaceImage
@onready var _stamina_bar: ProgressBar = $StaminaBar


func _ready() -> void:
	GameController.update_coins_labels.connect(_update_coins_labels)
	GameController.lives_changed.connect(_update_lives)
	GameController.update_stamina.connect(_on_stamina_changed)

	if _stamina_bar:
		_stamina_bar.max_value = 100.0
		_stamina_bar.value = 50.0
		_stamina_bar.show()

	GameController.interaction_hint.connect(_on_toggle_interaction_hint)
	GameController.display_dialog.connect(_show_dialog)
	_update_coins_labels()
	_update_lives()
	_dialog_box.hide()
	_interaction_hint.visible = false
	_pause_label.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		_pause_label.visible = get_tree().paused


func _update_coins_labels():
	if GameController.collected_coins_number > 9:
		_collected_coins_label.text = str(GameController.collected_coins_number)
	else:
		_collected_coins_label.text = "0" + str(GameController.collected_coins_number)
	if GameController.missing_coins_number > 9:
		_missing_coins_label.text = str(GameController.missing_coins_number)
	else: 
		_missing_coins_label.text = "0" + str(GameController.missing_coins_number)	

func _update_lives() -> void:
	# Clear existing hearts
	for child in _hearts_container.get_children():
		child.queue_free()

	# Add full hearts
	for i in range(GameController.lives):
		var heart = TextureRect.new()
		heart.texture = full_heart
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hearts_container.add_child(heart)

	# Add empty hearts
	for i in range(3 - GameController.lives):
		var heart = TextureRect.new()
		heart.texture = empty_heart
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hearts_container.add_child(heart)

func _on_toggle_interaction_hint(_is_visible: bool) -> void:
	_interaction_hint.visible = _is_visible

func _show_dialog(image: Texture2D, text: String) -> void:
	_dialog_label.text = text

	_dialog_face.texture = image
	_dialog_face.custom_minimum_size = Vector2(64, 64)
	_dialog_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialog_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialog_face.show()

	_dialog_box.show()

	await get_tree().create_timer(4.0).timeout
	_dialog_box.hide()

func _on_stamina_changed(current: float, maximum: float) -> void:
	if _stamina_bar:
		_stamina_bar.max_value = maximum
		_stamina_bar.value = current
