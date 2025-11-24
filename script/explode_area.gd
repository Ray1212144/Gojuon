# resizable_area_2d.gd
@tool
extends Area2D
class_name ExplodeArea2D
# 检查是否满足爆炸条件



# 分别控制 X 和 Y 轴的缩放
var scale_x: int = 1:
	set(value):
		scale_x = max(1, value)  # 确保至少为1
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_update_collision_shape()

var scale_y: int = 1:
	set(value):
		scale_y = max(1, value)  # 确保至少为1
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_update_collision_shape()

# 基础大小（缩放前的尺寸）
var base_size: Vector2 = Vector2(24, 24):
	set(value):
		base_size = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_update_collision_shape()

# 计算实际大小（应用缩放后的尺寸）
func get_actual_size() -> Vector2:
	return Vector2(base_size.x * scale_x, base_size.y * scale_y)

var color: Color = Color(0.5, 0.8, 1.0, 0.3):
	set(value):
		color = value
		if Engine.is_editor_hint():
			queue_redraw()

var border_color: Color = Color(0.2, 0.6, 1.0, 0.8):
	set(value):
		border_color = value
		if Engine.is_editor_hint():
			queue_redraw()

var border_width: float = 2.0:
	set(value):
		border_width = value
		if Engine.is_editor_hint():
			queue_redraw()

var handle_size: float = 8.0:
	set(value):
		handle_size = value
		if Engine.is_editor_hint():
			queue_redraw()

# 使用与 Brick 类相同的五十音数据
const KANA_SYMBOLS = [
	"あ", "い", "う", "え", "お",
	"か", "き", "く", "け", "こ",
	"さ", "し", "す", "せ", "そ",
	"た", "ち", "つ", "て", "と",
	"な", "に", "ぬ", "ね", "の",
	"は", "ひ", "ふ", "へ", "ほ",
	"ま", "み", "む", "め", "も",
	"や", "ゆ", "よ",
	"ら", "り", "る", "れ", "ろ",
	"わ", "を", "ん"
]

# 节点引用
var collision_shape: CollisionShape2D
var shape: RectangleShape2D

# 控制点状态
var dragging_handle: int = -1
var drag_offset: Vector2 = Vector2.ZERO

# 判定区域数组
var check_areas: Array = []
func _ready():
	# 只在运行时创建碰撞形状
	if not Engine.is_editor_hint():
		_create_collision_shape()
		
	# 确保在编辑器中正确显示
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		# 运行时收集所有判定区域
		_collect_check_areas()
		# 连接到所有 CheckArea2D 的条件改变信号
		_connect_check_area_signals()

# 连接到所有 CheckArea2D 的条件改变信号
func _connect_check_area_signals():
	for check_area in check_areas:
		if not check_area.condition_changed.is_connected(_on_check_area_condition_changed):
			check_area.condition_changed.connect(_on_check_area_condition_changed)

# 检查是否满足爆炸条件
func check_explode_conditions() -> bool:
	print("检查爆炸区域条件...")
	
	# 检查所有判定区域是否满足条件
	for check_area in check_areas:
		if not check_area.is_condition_met():
			print("条件不满足，无法爆炸")
			return false
	
	print("所有条件满足，触发爆炸!")
	# 所有条件满足，触发爆炸
	explode()
	return true

# 爆炸功能
func explode():
	print("开始执行爆炸!")
	
	# 获取爆炸范围内的所有Brick和Fill
	var overlapping_bodies = get_overlapping_bodies()
	print("爆炸范围内的物体数量: ", overlapping_bodies.size())
	
	for body in overlapping_bodies:
		print("检查物体: ", body.name, " 类型: ", body.get_class())
		if body is Fill:
			print("删除 Fill: ", body.get_kana_symbol())
			body.queue_free()
		elif body is Brick:
			print("删除 Brick: ", body.get_symbol())
			body.queue_free()
		else:
			print("跳过非目标物体: ", body.name)
	
	print("爆炸执行完成!")

# 获取判定区域数组
func get_check_areas() -> Array:
	return check_areas
# 当 CheckArea2D 条件改变时
func _on_check_area_condition_changed(is_met: bool):
	print("CheckArea2D 条件改变，重新检查爆炸条件")
	check_explode_conditions()



# 收集所有判定区域
func _collect_check_areas():
	check_areas.clear()
	
	# 查找所有判定区域子节点
	for child in get_children():
		if child is CheckArea2D:
			check_areas.append(child)

# 在运行时创建碰撞形状
func _create_collision_shape():
	if collision_shape:
		return
	
	# 创建碰撞形状节点
	collision_shape = CollisionShape2D.new()
	shape = RectangleShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# 更新碰撞形状
	_update_collision_shape()

# 更新碰撞形状
func _update_collision_shape():
	if collision_shape and shape:
		shape.size = get_actual_size()

# 绘制函数 - 只绘制基本形状，不绘制文本
func _draw():
	if not Engine.is_editor_hint():
		return
	z_index = 1000
	var actual_size = get_actual_size()
	
	# 绘制填充矩形
	draw_rect(Rect2(-actual_size/2, actual_size), color, true)
	
	# 绘制边框
	draw_rect(Rect2(-actual_size/2, actual_size), border_color, false, border_width)
	
	# 绘制控制点
	var half_handle = handle_size / 2
	var handles = [
		Vector2(-actual_size.x/2, -actual_size.y/2),  # 左上
		Vector2(actual_size.x/2, -actual_size.y/2),   # 右上
		Vector2(-actual_size.x/2, actual_size.y/2),   # 左下
		Vector2(actual_size.x/2, actual_size.y/2)     # 右下
	]
	
	for handle_pos in handles:
		draw_rect(
			Rect2(handle_pos - Vector2(half_handle, half_handle), Vector2(handle_size, handle_size)),
			border_color, true
		)
	
	# 在编辑器中显示缩放信息
	var font = ThemeDB.fallback_font
	var font_size = 12


# 获取控制点的矩形区域
func _get_handle_rect(handle_index: int) -> Rect2:
	var actual_size = get_actual_size()
	var half_handle = handle_size / 2
	var handles = [
		Vector2(-actual_size.x/2, -actual_size.y/2),  # 左上
		Vector2(actual_size.x/2, -actual_size.y/2),   # 右上
		Vector2(-actual_size.x/2, actual_size.y/2),   # 左下
		Vector2(actual_size.x/2, actual_size.y/2)     # 右下
	]
	
	if handle_index >= 0 and handle_index < handles.size():
		return Rect2(handles[handle_index] - Vector2(half_handle, half_handle), 
					Vector2(handle_size, handle_size))
	return Rect2()

# 检查点是否在控制点上
func _get_handle_at_position(position: Vector2) -> int:
	var actual_size = get_actual_size()
	
	for i in range(4):  # 4个控制点
		var handle_rect = _get_handle_rect(i)
		if handle_rect.has_point(position):
			return i
	
	# 检查是否在区域内（用于整体移动）
	var area_rect = Rect2(-actual_size/2, actual_size)
	if area_rect.has_point(position):
		return 4  # 整体移动
	
	return -1  # 不在任何控制点上

# 输入处理 - 仅在编辑器中有效
func _input(event):
	if not Engine.is_editor_hint():
		return
	
	var actual_size = get_actual_size()
	
	if event is InputEventMouseButton:
		var mouse_pos = get_local_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 鼠标按下
				dragging_handle = _get_handle_at_position(mouse_pos)
				if dragging_handle != -1:
					drag_offset = mouse_pos
					
					# 根据拖动的控制点计算偏移
					if dragging_handle < 4:  # 角落控制点
						var handles = [
							Vector2(-actual_size.x/2, -actual_size.y/2),
							Vector2(actual_size.x/2, -actual_size.y/2),
							Vector2(-actual_size.x/2, actual_size.y/2),
							Vector2(actual_size.x/2, actual_size.y/2)
						]
						drag_offset = mouse_pos - handles[dragging_handle]
					else:  # 整体移动
						drag_offset = mouse_pos
					
					get_viewport().set_input_as_handled()
			else:
				# 鼠标释放
				dragging_handle = -1
				get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseMotion and dragging_handle != -1:
		var mouse_pos = get_local_mouse_position()
		
		if dragging_handle < 4:  # 角落控制点
			# 根据拖动的控制点调整基础大小（不是实际大小）
			var new_base_size = base_size
			
			match dragging_handle:
				0:  # 左上
					new_base_size.x = max(10, base_size.x + (drag_offset.x - mouse_pos.x) * 2 / scale_x)
					new_base_size.y = max(10, base_size.y + (drag_offset.y - mouse_pos.y) * 2 / scale_y)
				1:  # 右上
					new_base_size.x = max(10, base_size.x + (mouse_pos.x - drag_offset.x) * 2 / scale_x)
					new_base_size.y = max(10, base_size.y + (drag_offset.y - mouse_pos.y) * 2 / scale_y)
				2:  # 左下
					new_base_size.x = max(10, base_size.x + (drag_offset.x - mouse_pos.x) * 2 / scale_x)
					new_base_size.y = max(10, base_size.y + (mouse_pos.y - drag_offset.y) * 2 / scale_y)
				3:  # 右下
					new_base_size.x = max(10, base_size.x + (mouse_pos.x - drag_offset.x) * 2 / scale_x)
					new_base_size.y = max(10, base_size.y + (mouse_pos.y - drag_offset.y) * 2 / scale_y)
			
			base_size = new_base_size
			queue_redraw()
		
		elif dragging_handle == 4:  # 整体移动
			position += mouse_pos - drag_offset
			queue_redraw()
		
		get_viewport().set_input_as_handled()

# 序列化/反序列化支持 - 只在这里定义属性，避免重复
func _get_property_list():
	var properties = []
	
	# 添加自定义属性
	properties.append({
		"name": "base_size",
		"type": TYPE_VECTOR2,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE
	})
	
	properties.append({
		"name": "scale_x",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,10,1"
	})
	
	properties.append({
		"name": "scale_y",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,10,1"
	})
	
	properties.append({
		"name": "color",
		"type": TYPE_COLOR,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE
	})
	
	properties.append({
		"name": "border_color",
		"type": TYPE_COLOR,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE
	})
	
	properties.append({
		"name": "border_width",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,10,0.1"
	})
	
	properties.append({
		"name": "handle_size",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "4,20,1"
	})
	
	return properties

# 获取属性值
func _get(property):
	match property:
		"base_size":
			return base_size
		"scale_x":
			return scale_x
		"scale_y":
			return scale_y
		"color":
			return color
		"border_color":
			return border_color
		"border_width":
			return border_width
		"handle_size":
			return handle_size
	
	return null

# 设置属性值
func _set(property, value):
	match property:
		"base_size":
			base_size = value
			return true
		"scale_x":
			scale_x = value
			return true
		"scale_y":
			scale_y = value
			return true
		"color":
			color = value
			return true
		"border_color":
			border_color = value
			return true
		"border_width":
			border_width = value
			return true
		"handle_size":
			handle_size = value
			return true
	
	return false
