extends Node2D
class_name Main

@export var canvas_animation_player : AnimationPlayer
@export var player:Player

# 硬编码的资源路径列表
var style_paths = [
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_SpeakerTextbox/speaker_textbox_style.tres",
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_TextBubbles/textbubble_style.tres",
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_VN_Default/default_vn_style.tres"
	
]

func _ready() -> void:
	#return
	var cursor_scene = preload("res://scene/controller_cursor.tscn")
	var controller_cursor = cursor_scene.instantiate()
	add_child(controller_cursor)

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

func travel_fire():
	player.global_position = player.bonfire.check_point.global_position


# 根据节点路径和场景文件路径加载并添加场景
func reset(position_node_path: String, file_path: String):
	print("position_node_path")
	print(position_node_path)
	print(file_path)
	canvas_animation_player.play("blackscreen_intro")
	await  canvas_animation_player.animation_finished
	travel_fire()
	# 1. 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("场景文件不存在: " + file_path)
		return null
	
	# 2. 加载场景资源
	var scene_resource = load(file_path)
	if scene_resource == null:
		push_error("无法加载场景资源: " + file_path)
		return null
	
	# 3. 实例化场景
	var scene_instance:Place = scene_resource.instantiate()
	if scene_instance == null:
		push_error("无法实例化场景: " + file_path)
		return null
	
	# 4. 获取目标父节点
	var parent_node = get_node_or_null(position_node_path)

	if parent_node == null:
		push_error("目标节点不存在: " + position_node_path)
		scene_instance.queue_free()  # 清理实例
		return null
	parent_node.get_child(0).queue_free()
	# 5. 添加场景实例到目标节点
	parent_node.add_child(scene_instance)
	
	print("成功加载场景到节点: ", position_node_path)
	player.bonfire = scene_instance.bonfire
	scene_instance.bonfire.is_active = true
	canvas_animation_player.play("blackscreen_outro")
	return scene_instance
