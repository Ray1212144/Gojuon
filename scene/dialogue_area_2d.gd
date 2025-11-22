extends Area2D
class_name DialogueArea

signal dialogue(dialogue_name)
@export var dialogue_name: String
@export var place : Place

func _on_body_entered(body) -> void:
	if body is Player:
		var pos:PlacePostion = place.get_parent()
		if pos.has_intro == false:
			Dialogic.start(dialogue_name)
			pos.has_intro = true
