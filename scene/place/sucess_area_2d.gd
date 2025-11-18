extends Area2D


func _on_body_entered(body:Player) -> void:
	body.bonfire.place_position.has_pass = true
