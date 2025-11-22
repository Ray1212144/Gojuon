
extends TileMapLayer

# 视野系统信号
signal visibility_updated(visible_cells: Array[Vector2i])

# 配置参数
@export_category("Visibility Settings")
@export var fov_radius: int = 8
@export var update_interval: float = 0.1

# 需要应用黑色覆盖的组
@export_category("Fog Groups")
@export var fog_groups: Array[String] = ["brick", "chests", "items", "npcs"]

# 内部变量
var _player_position: Vector2
var _visible_cells: Dictionary[Vector2i, bool] = {}
var _time_since_last_update: float = 0.0
var _obstacle_cells: Dictionary[Vector2i, bool] = {}
var _fog_overlays: Dictionary[Node, Sprite2D] = {}  # 存储每个节点的黑色覆盖层
var _screen_rect: Rect2  # 当前屏幕区域

func _ready() -> void:
	# 延迟一帧确保完全加载
	await get_tree().process_frame
	
	# 扫描障碍物
	_scan_obstacle_cells()
	
	# 添加到组
	add_to_group("wall_layer")
	
	# 初始化所有需要覆盖的节点
	_init_fog_overlays()
	
	print("WallLayer 初始化完成，障碍物数量: ", _obstacle_cells.size())

# 初始化所有需要覆盖的节点的黑色覆盖层
func _init_fog_overlays() -> void:
	# 清除现有的覆盖层
	_clear_fog_overlays()
	
	# 为每个组的节点创建覆盖层
	for group in fog_groups:
		for node in get_tree().get_nodes_in_group(group):
			_add_fog_overlay_to_node(node)

# 为单个节点添加黑色覆盖层
func _add_fog_overlay_to_node(node: Node) -> void:
	if _fog_overlays.has(node):
		return  # 已经存在覆盖层
	
	# 创建黑色覆盖层
	var fog_overlay = Sprite2D.new()
	fog_overlay.texture = _create_black_texture()
	fog_overlay.modulate = Color.BLACK
	fog_overlay.centered = true
	fog_overlay.z_index = node.z_index + 1  # 确保在节点上方
	
	# 添加到节点
	node.add_child(fog_overlay)
	
	# 存储引用
	_fog_overlays[node] = fog_overlay
	
	# 初始状态：根据可见性设置
	_update_node_visibility(node)

# 创建黑色纹理
func _create_black_texture() -> Texture2D:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	return ImageTexture.create_from_image(image)

# 清除所有覆盖层
func _clear_fog_overlays() -> void:
	for node in _fog_overlays:
		var overlay = _fog_overlays[node]
		if is_instance_valid(overlay) and overlay.get_parent():
			overlay.get_parent().remove_child(overlay)
			overlay.queue_free()
	
	_fog_overlays.clear()

# 更新节点的可见性
func _update_node_visibility(node: Node) -> void:
	if not _fog_overlays.has(node):
		return
	
	var overlay = _fog_overlays[node]
	var node_cell = local_to_map(node.global_position)
	
	# 如果节点在可见单元格中，隐藏覆盖层；否则显示
	if is_cell_visible(node_cell):
		overlay.hide()
	else:
		overlay.show()

# 扫描障碍物瓦片
func _scan_obstacle_cells() -> void:
	_obstacle_cells.clear()
	
	# 获取所有使用的单元格
	var used_cells: Array[Vector2i] = get_used_cells()
	
	for cell in used_cells:
		# 检查瓦片是否有碰撞
		if _has_collision(cell):
			_obstacle_cells[cell] = true

# 检查单元格是否有碰撞
func _has_collision(cell: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(cell)
	if not tile_data:
		return false
	
	# 方法1: 检查碰撞多边形
	if tile_data.get_collision_polygons_count(0) > 0:
		return true
	
	# 方法2: 检查物理层
	for layer in range(32):
		if tile_data.physics_layer_peek_bit(layer):
			return true
	
	return false

func set_player_position(position: Vector2) -> void:
	_player_position = position

func _process(delta: float) -> void:
	_time_since_last_update += delta
	if _time_since_last_update >= update_interval:
		_update_visibility()
		_time_since_last_update = 0

func _update_visibility() -> void:
	var old_visible_cells = _visible_cells.duplicate()
	_visible_cells.clear()
	
	# 计算视野
	_calculate_field_of_view()
	
	# 更新所有节点的可见性
	_update_all_nodes_visibility()
	
	# 发射信号
	visibility_updated.emit(_visible_cells.keys())

# 更新所有节点的可见性
func _update_all_nodes_visibility() -> void:
	for node in _fog_overlays:
		_update_node_visibility(node)

# 计算视野
func _calculate_field_of_view() -> void:
	var player_cell = local_to_map(_player_position)
	_visible_cells[player_cell] = true
	
	# 使用八方向射线算法
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
	]
	
	for direction in directions:
		_cast_directional_ray(player_cell, direction)

# 方向性射线投射
func _cast_directional_ray(origin: Vector2i, direction: Vector2i) -> void:
	var current = origin
	
	for distance in range(1, fov_radius + 1):
		current = origin + direction * distance
		
		# 检查是否在地图范围内
		if not _is_cell_in_map(current):
			break
		
		# 标记为可见
		_visible_cells[current] = true
		
		# 如果遇到障碍物，停止这个方向
		if _obstacle_cells.has(current):
			break

# 检查单元格是否在地图范围内
func _is_cell_in_map(cell: Vector2i) -> bool:
	var used_rect = get_used_rect()
	return used_rect.has_point(cell)

# 公共接口
func is_cell_visible(cell: Vector2i) -> bool:
	return _visible_cells.has(cell)

func get_visible_cells() -> Array[Vector2i]:
	return _visible_cells.keys()

func get_obstacle_cells() -> Array[Vector2i]:
	return _obstacle_cells.keys()

# 添加节点到覆盖系统
func add_node_to_fog_system(node: Node) -> void:
	if not fog_groups.has(node.get_groups()):
		return
	
	_add_fog_overlay_to_node(node)

# 从覆盖系统移除节点
func remove_node_from_fog_system(node: Node) -> void:
	if not _fog_overlays.has(node):
		return
	
	var overlay = _fog_overlays[node]
	if is_instance_valid(overlay) and overlay.get_parent():
		overlay.get_parent().remove_child(overlay)
		overlay.queue_free()
	
	_fog_overlays.erase(node)

# 重置战争迷雾
func reset_fog() -> void:
	_visible_cells.clear()
	
	# 重置所有覆盖层
	for overlay in _fog_overlays.values():
		if is_instance_valid(overlay):
			overlay.show()

# 强制更新障碍物地图
func update_obstacle_map() -> void:
	_scan_obstacle_cells()

# 当节点退出场景树时清理
func _exit_tree() -> void:
	_clear_fog_overlays()
