extends Area2D
class_name SucessArea

signal has_pass

func _on_body_entered(body) -> void:

	if body is Player:
		if body.bonfire == null:
			return
		body.bonfire.place_position.has_pass = true
		has_pass.emit()
