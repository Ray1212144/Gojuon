# resizable_area_2d.gd
@tool
extends Area2D
class_name ExplodeArea2D

# 导出变量，只在 _get_property_list() 中定义，避免重复
var size: Vector2 = Vector2(100, 100):
	set(value):
		size = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_update_collision_shape()

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

# 目标五十音选择
var target_kana_selection: int = 0:
	set(value):
		target_kana_selection = value
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

func _ready():
	# 只在运行时创建碰撞形状
	if not Engine.is_editor_hint():
		_create_collision_shape()
	
	# 确保在编辑器中正确显示
	if Engine.is_editor_hint():
		queue_redraw()

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
		shape.size = size

# 绘制函数 - 只绘制基本形状，不绘制文本
func _draw():
	if not Engine.is_editor_hint():
		return
	
	# 绘制填充矩形
	draw_rect(Rect2(-size/2, size), color, true)
	
	# 绘制边框
	draw_rect(Rect2(-size/2, size), border_color, false, border_width)
	
	# 绘制控制点
	var half_handle = handle_size / 2
	var handles = [
		Vector2(-size.x/2, -size.y/2),  # 左上
		Vector2(size.x/2, -size.y/2),   # 右上
		Vector2(-size.x/2, size.y/2),   # 左下
		Vector2(size.x/2, size.y/2)     # 右下
	]
	
	for handle_pos in handles:
		draw_rect(
			Rect2(handle_pos - Vector2(half_handle, half_handle), Vector2(handle_size, handle_size)),
			border_color, true
		)

# 获取目标五十音符号
func get_target_kana_symbol() -> String:
	if target_kana_selection < KANA_SYMBOLS.size():
		return KANA_SYMBOLS[target_kana_selection]
	return "？"

# 获取控制点的矩形区域
func _get_handle_rect(handle_index: int) -> Rect2:
	var half_handle = handle_size / 2
	var handles = [
		Vector2(-size.x/2, -size.y/2),  # 左上
		Vector2(size.x/2, -size.y/2),   # 右上
		Vector2(-size.x/2, size.y/2),   # 左下
		Vector2(size.x/2, size.y/2)     # 右下
	]
	
	if handle_index >= 0 and handle_index < handles.size():
		return Rect2(handles[handle_index] - Vector2(half_handle, half_handle), 
					Vector2(handle_size, handle_size))
	return Rect2()

# 检查点是否在控制点上
func _get_handle_at_position(position: Vector2) -> int:
	for i in range(4):  # 4个控制点
		var handle_rect = _get_handle_rect(i)
		if handle_rect.has_point(position):
			return i
	
	# 检查是否在区域内（用于整体移动）
	var area_rect = Rect2(-size/2, size)
	if area_rect.has_point(position):
		return 4  # 整体移动
	
	return -1  # 不在任何控制点上

# 输入处理 - 仅在编辑器中有效
func _input(event):
	if not Engine.is_editor_hint():
		return
	
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
							Vector2(-size.x/2, -size.y/2),
							Vector2(size.x/2, -size.y/2),
							Vector2(-size.x/2, size.y/2),
							Vector2(size.x/2, size.y/2)
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
			# 根据拖动的控制点调整大小
			var new_size = size
			
			match dragging_handle:
				0:  # 左上
					new_size.x = max(10, size.x + (drag_offset.x - mouse_pos.x) * 2)
					new_size.y = max(10, size.y + (drag_offset.y - mouse_pos.y) * 2)
				1:  # 右上
					new_size.x = max(10, size.x + (mouse_pos.x - drag_offset.x) * 2)
					new_size.y = max(10, size.y + (drag_offset.y - mouse_pos.y) * 2)
				2:  # 左下
					new_size.x = max(10, size.x + (drag_offset.x - mouse_pos.x) * 2)
					new_size.y = max(10, size.y + (mouse_pos.y - drag_offset.y) * 2)
				3:  # 右下
					new_size.x = max(10, size.x + (mouse_pos.x - drag_offset.x) * 2)
					new_size.y = max(10, size.y + (mouse_pos.y - drag_offset.y) * 2)
			
			size = new_size
			queue_redraw()
		
		elif dragging_handle == 4:  # 整体移动
			position += mouse_pos - drag_offset
			queue_redraw()
		
		get_viewport().set_input_as_handled()


# 设置目标五十音
func set_target_kana(selection: int):
	target_kana_selection = selection
	if Engine.is_editor_hint():
		queue_redraw()

# 序列化/反序列化支持 - 只在这里定义属性，避免重复
func _get_property_list():
	var properties = []
	
	# 添加自定义属性
	properties.append({
		"name": "size",
		"type": TYPE_VECTOR2,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_NONE
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
	
	# 添加目标五十音选择属性
	var kana_hint_string = ""
	for i in range(KANA_SYMBOLS.size()):
		if i > 0:
			kana_hint_string += ","
		kana_hint_string += KANA_SYMBOLS[i] + ":" + str(i)
	
	properties.append({
		"name": "target_kana_selection",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": kana_hint_string
	})
	
	return properties

# 获取属性值
func _get(property):
	match property:
		"size":
			return size
		"color":
			return color
		"border_color":
			return border_color
		"border_width":
			return border_width
		"handle_size":
			return handle_size
		"target_kana_selection":
			return target_kana_selection
	
	return null

# 设置属性值
func _set(property, value):
	match property:
		"size":
			size = value
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
		"target_kana_selection":
			target_kana_selection = value
			return true
	
	return false


# 爆炸功能
func check_explode():

	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		# 检查是否是 Brick 类型
		if body is Fill:
			# 检查五十音是否匹配
			if body.kana_selection == target_kana_selection:
				# 引爆 Brick
				explode()
func explode():
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		# 检查是否是 Brick 类型
		if body is Fill or body is Brick:
			body.queue_free()
