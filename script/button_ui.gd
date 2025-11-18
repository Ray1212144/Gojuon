extends AnimatedSprite2D
class_name ButtonUi

@export var buttons :Array[KanaAreaButton]


func _ready() -> void:
	for i in buttons:
		i.button_hovered.connect(on_button_hovered)
		i.button_exited.connect(on_button_exited)
		
		
func on_button_hovered(node:KanaAreaButton):
	$Timer.stop()
	var fra = 1
	for i in buttons:
		if i == node:
			self.frame = fra
		else:
			fra += 1

func on_button_exited():
	return
	$Timer.start()

func _on_timer_timeout() -> void:
	self.frame = 0
