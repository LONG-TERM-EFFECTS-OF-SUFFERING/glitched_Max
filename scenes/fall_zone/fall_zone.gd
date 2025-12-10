extends Area3D


func _on_body_entered(body: Node3D) -> void: # It just listen to the player layer
	body.die_falling()
