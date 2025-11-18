extends Node2D
class_name Main

@export var canvas_animation_player : AnimationPlayer

# 硬编码的资源路径列表
var style_paths = [
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_SpeakerTextbox/speaker_textbox_style.tres",
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_TextBubbles/textbubble_style.tres",
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_VN_Default/default_vn_style.tres"
	
]

func _ready() -> void:
	return
	load_style()
	Dialogic.signal_event.connect(_on_dialogic_text_signal)
	Dialogic.start("intro_1")

func _on_dialogic_text_signal(argument:String):
	if argument == "blackout" and canvas_animation_player:
		canvas_animation_player.play("black_out")

func load_style():
	for path in style_paths:
		var resource = load(path)
		if resource:
			print("加载资源: ", path, " 类型: ", resource.get_class())
			
			# 检查资源是否有 prepare 方法
			if resource.has_method("prepare"):
				resource.prepare()
				print("已准备资源: ", path)
			else:
				print("警告: 资源没有 prepare 方法: ", path)
		else:
			print("错误: 无法加载资源: ", path)
