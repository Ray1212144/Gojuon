extends Area2D


func _on_body_entered(body) -> void:
	if body is Player:
		body.bonfire.place_position.has_pass = true
