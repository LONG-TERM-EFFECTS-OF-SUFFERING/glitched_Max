extends Node3D


@onready var _kate: Node3D = $KateSkin
@onready var _anim_player: AnimationPlayer = _kate.get_node("AnimationPlayer")


func _ready() -> void:
	# Play the "die" animation when the Game Over screen loads
	_anim_player.play("fall")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
