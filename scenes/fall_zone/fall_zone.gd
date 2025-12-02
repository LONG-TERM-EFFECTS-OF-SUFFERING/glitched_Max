extends Area3D


func _on_body_entered(body: Node3D) -> void: # It is only listening to the "player" layer
		body.die()
