extends Place



func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_text_signal)
	success_area.has_pass.connect(on_pass)


func _on_dialogic_text_signal(argument:String):
	if argument == "c1_l1":
		Dialogic.start("c1_l1")
		
func on_pass():
	pass
