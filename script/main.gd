extends Node2D
class_name Main

@export var canvas_animation_player : AnimationPlayer
@export var player: Player
@export var intro : bool

# 可见性系统相关变量
@export var _bg_color: Color

# 分组名称
@export var visible_layers_group: String = "visible_layers"
@export var not_visible_layers_group: String = "not_visible_layers"

var _visible_layers: Array[ModulateTileLayer] = []   # 碰撞mask为1的可见图层
var _not_visible_layers: Array[TileMapLayer] = []   # 碰撞mask为2的不可见图层
var visible_tiles: Dictionary[Vector2i, bool] = {}

# 硬编码的资源路径列表
var style_paths = [
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_SpeakerTextbox/speaker_textbox_style.tres",
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_TextBubbles/textbubble_style.tres",
	"res://addons/dialogic/Modules/DefaultLayoutParts/Style_VN_Default/default_vn_style.tres"
]

func _ready() -> void:
	# 通过分组获取图层
	_get_layers_from_groups()
	# 初始化可见性系统
	_init_visibility_system()
	
	var cursor_scene = preload("res://scene/controller_cursor.tscn")
	var controller_cursor = cursor_scene.instantiate()
	add_child(controller_cursor)
	load_style()
	Dialogic.signal_event.connect(_on_dialogic_text_signal)
	if intro:
		Dialogic.start("intro_1")

# 通过分组名称获取所有相关图层
func _get_layers_from_groups():
	_visible_layers.clear()
	_not_visible_layers.clear()
	
	# 获取所有属于可见图层分组的节点
	var visible_nodes = get_tree().get_nodes_in_group(visible_layers_group)
	for node in visible_nodes:
		if node is ModulateTileLayer:
			_visible_layers.append(node)
		else:
			push_warning("节点 " + node.name + " 在分组 " + visible_layers_group + " 中但不是 ModulateTileLayer 类型")
	
	# 获取所有属于不可见图层分组的节点
	var not_visible_nodes = get_tree().get_nodes_in_group(not_visible_layers_group)
	for node in not_visible_nodes:
		if node is TileMapLayer:
			_not_visible_layers.append(node)
		else:
			push_warning("节点 " + node.name + " 在分组 " + not_visible_layers_group + " 中但不是 TileMapLayer 类型")
	
	print("找到 ", _visible_layers.size(), " 个可见图层")
	print("找到 ", _not_visible_layers.size(), " 个不可见图层")

func _init_visibility_system():
	# 隐藏基础图层，显示可见性图层
	for layer in _not_visible_layers:
		layer.visible = false
	for layer in _visible_layers:
		layer.visible = true
	RenderingServer.set_default_clear_color(_bg_color)

func _process(delta: float) -> void:
	# 更新可见性系统的淡出效果
	_update_visibility_fade()

func _update_visibility_fade():
	for visible_layer in _visible_layers:
		if not visible_layer.has_method("cell_alphas"):
			continue
			
		visible_layer.visible_tiles = visible_tiles
		for cell in visible_layer.cell_alphas:
			if visible_layer.cell_alphas[cell] <= 0:
				visible_layer.set_cell(cell, -1)
				visible_layer.cell_alphas.erase(cell)

# 设置可见瓦片
func set_visible_tiles(cells: Array[Vector2i]):
	visible_tiles.clear()
	for cell in cells:
		visible_tiles[cell] = true
		# 从不可见图层复制瓦片到可见图层
		for i in range(min(_visible_layers.size(), _not_visible_layers.size())):
			var source_layer = _not_visible_layers[i]
			var visible_layer = _visible_layers[i]
			
			var source_id = source_layer.get_cell_source_id(cell)
			if source_id != -1:  # 只在有瓦片的地方设置
				var atlas_coords = source_layer.get_cell_atlas_coords(cell)
				var alternative_tile = source_layer.get_cell_alternative_tile(cell)
				visible_layer.set_cell(cell, source_id, atlas_coords, alternative_tile)
				
				var tiledata = visible_layer.get_cell_tile_data(cell)
				if tiledata:
					tiledata.modulate.a = 1

# 检查指定位置是否有任何瓦片
func has_any_tile_at(cell: Vector2i) -> bool:
	for layer in _not_visible_layers:
		if layer.get_cell_source_id(cell) != -1:
			return true
	return false

# 光线投射（用于视野系统）- 圆形视野
func raycast_circular_vision(pos: Vector2, radius: float) -> Array[Vector2i]:
	var res_tiles: Dictionary[Vector2i, bool] = {}
	
	# 如果没有图层，返回空数组
	if _not_visible_layers.is_empty():
		return []
	
	var space = get_world_2d().direct_space_state
	var angle_divisions = 36  # 将圆形分为36个方向（每10度一个）
	
	for i in range(angle_divisions):
		var angle = 2 * PI * i / angle_divisions
		var params = PhysicsRayQueryParameters2D.create(pos, pos + Vector2.from_angle(angle) * radius)
		params.collision_mask = 1  # 只与可见图层碰撞
		var res = space.intersect_ray(params)
		
		if not res.is_empty():
			var raycast_pos: Vector2 = res["position"]
			# 从玩家位置到碰撞点之间采样
			var divisions = pos.distance_to(raycast_pos) / (_not_visible_layers[0].tile_set.tile_size.x / 2)
			for j in range(divisions + 1):
				var lerp_pos = lerp(pos, raycast_pos, float(j) / divisions)
				var test_pos = _not_visible_layers[0].local_to_map(lerp_pos)
				if has_any_tile_at(test_pos):
					res_tiles[test_pos] = true
		else:
			# 如果没有碰撞，则整个射线上的瓦片都可见
			var ray_end = pos + Vector2.from_angle(angle) * radius
			var divisions = radius / (_not_visible_layers[0].tile_set.tile_size.x / 2)
			for j in range(divisions + 1):
				var lerp_pos = lerp(pos, ray_end, float(j) / divisions)
				var test_pos = _not_visible_layers[0].local_to_map(lerp_pos)
				if has_any_tile_at(test_pos):
					res_tiles[test_pos] = true
	
	return res_tiles.keys()

# 更新玩家视野（圆形视野）
func update_player_vision(player_position: Vector2, radius: float = 200.0):
	# 如果没有图层，直接返回
	if _not_visible_layers.is_empty():
		return
	
	# 获取玩家所在的单元格
	var player_cell = _not_visible_layers[0].local_to_map(player_position)
	
	# 计算圆形视野内的所有单元格
	var visible_cells = []
	var radius_cells = ceil(radius / _not_visible_layers[0].tile_set.tile_size.x)
	
	for x in range(-radius_cells, radius_cells + 1):
		for y in range(-radius_cells, radius_cells + 1):
			var cell = player_cell + Vector2i(x, y)
			var cell_world_pos = _not_visible_layers[0].map_to_local(cell)
			if player_position.distance_to(cell_world_pos) <= radius:
				visible_cells.append(cell)
	
	# 使用光线投射确保视野不被墙壁阻挡
	var precise_visible_cells = raycast_circular_vision(player_position, radius)
	visible_cells.append_array(precise_visible_cells)
	
	set_visible_tiles(visible_cells)

func _on_dialogic_text_signal(argument:String):
	if argument == "blackout":
		canvas_animation_player.play("black_out")
	elif argument == "show_graph":
		$CanvasLayer/TextureRect.show()
	elif argument == "disable_player":
		player.speed = 0
	elif argument == "enable_player":
		player.speed = player.default_speed
	elif argument == "hide_graph":
		$CanvasLayer/TextureRect.hide()
		
func load_style():
	for path in style_paths:
		var resource = load(path)
		if resource:
			print("加载资源: ", path, " 类型: ", resource.get_class())
			
			if resource.has_method("prepare"):
				resource.prepare()
				print("已准备资源: ", path)
			else:
				print("警告: 资源没有 prepare 方法: ", path)
		else:
			print("错误: 无法加载资源: ", path)

func travel_fire():
	canvas_animation_player.play("blackscreen_intro")
	await  canvas_animation_player.animation_finished
	player.global_position = player.bonfire.check_point.global_position
	canvas_animation_player.play("blackscreen_outro")

func reset(position_node_path: String, file_path: String):
	print("position_node_path:", position_node_path)
	print("file_path:", file_path)
	canvas_animation_player.play("blackscreen_intro")
	await  canvas_animation_player.animation_finished
	player.global_position = player.bonfire.check_point.global_position
	
	if not FileAccess.file_exists(file_path):
		push_error("场景文件不存在: " + file_path)
		return null
	
	var scene_resource = load(file_path)
	if scene_resource == null:
		push_error("无法加载场景资源: " + file_path)
		return null
	
	var scene_instance:Place = scene_resource.instantiate()
	if scene_instance == null:
		push_error("无法实例化场景: " + file_path)
		return null
	
	var parent_node = get_node_or_null(position_node_path)
	if parent_node == null:
		push_error("目标节点不存在: " + position_node_path)
		scene_instance.queue_free()
		return null
	
	parent_node.get_child(0).queue_free()
	parent_node.add_child(scene_instance)
	
	# 新场景加载后，重新获取图层分组
	_get_layers_from_groups()
	_init_visibility_system()
	
	print("成功加载场景到节点: ", position_node_path)
	player.bonfire = scene_instance.bonfire
	scene_instance.bonfire.is_active = true
	canvas_animation_player.play("blackscreen_outro")
	return scene_instance
