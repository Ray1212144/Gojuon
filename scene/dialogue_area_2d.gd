extends Area2D
class_name DialogueArea

signal dialogue(dialogue_name)
@export var dialogue_name: String

func _on_body_entered(body) -> void:
	if body is Player:
		if body.bonfire == null:
			return
		body.bonfire.place_position.has_pass = true
		dialogue.emit(dialogue_name)
