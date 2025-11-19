extends Area2D


func _on_body_entered(body) -> void:
	if body.bonfire == null:
		return
	if body is Player:
		body.bonfire.place_position.has_pass = true
