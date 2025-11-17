extends Node2D
class_name Main

@export var canvas_animation_player : AnimationPlayer


func _ready() -> void:
	#return
	Dialogic.signal_event.connect(_on_dialogic_text_signal)
	Dialogic.start("intro_1")
	

func _on_dialogic_text_signal(argument:String):
	if argument == "blackout":
		canvas_animation_player.play("black_out")
		
		
#func start_dialog():
	#Dialogic.timeline_ended.connect(_on_timeline_ended)
	#Dialogic.start("my_timeline")
#
#func _on_timeline_ended():
	#Dialogic.timeline_ended.disconnect(_on_timeline_ended)
