extends AnimatedSprite2D
class_name ButtonUi

@export var buttons :Array[KanaAreaButton]

func _ready() -> void:
	for i in buttons:
		i.button_hovered.connect(on_button_hovered)
		
		
func on_button_hovered(node:KanaAreaButton):
	var fra = 1
	for i in buttons:
		if i == node:
			self.frame = fra
		else:
			fra += 1
