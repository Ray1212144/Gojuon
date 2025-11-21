extends TextureRect

@export var player :Player


func _on_texture_rect_pressed() -> void:
	if player.bonfire != null:

		player.bonfire.main = player.get_parent()
		player.bonfire.call_reset()
