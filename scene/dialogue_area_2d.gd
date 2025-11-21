extends Area2D
class_name DialogueArea

signal dialogue(dialogue_name)
@export var dialogue_name: String

func _on_body_entered(body) -> void:
	if body is Player:
		Dialogic.start(dialogue_name)
