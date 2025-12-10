extends Area3D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _sound_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var coins_container: CoinsContainer

func _ready() -> void:
	if GameController.is_coin_collected(str(get_path())):
		queue_free()


func _on_body_entered(_body: Node3D) -> void:  # It is only listening to the "player" layer
	coins_container.collect_coin()
	GameController.collect_coin(str(get_path()))

	set_deferred("monitoring", false)
	_sound_player.reparent(get_parent())
	_sound_player.play()
	_animation_player.play("bounce")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	# The only animation that can finish is "bounce"
	queue_free()
