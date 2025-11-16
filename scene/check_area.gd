# check_area_2d.gd
@tool
extends Area2D
class_name CheckArea2D

# 导出变量
var size: Vector2 = Vector2(50, 50):
	set(value):
		size = value
		if Engine.is_editor_hint():
			queue_redraw()
		else:
			_update_collision_shape()  # 添加这行

var color: Color = Color(1.0, 0.8, 0.5, 0.3):
	set(value):
		color = value
		if Engine.is_editor_hint():
			queue_redraw()

var border_color: Color = Color(1.0, 0.6, 0.2, 0.8):
	set(value):
		border_color = value
		if Engine.is_editor_hint():
			queue_redraw()

var border_width: float = 2.0:
	set(value):
		border_width = value
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
var collision_shape: CollisionShape2D
var shape: RectangleShape2D

func _ready():
	# 只在运行时创建碰撞形状
	if not Engine.is_editor_hint():
		_create_collision_shape()
		# 添加到组中
		add_to_group("CheckArea2D")
	
	# 确保在编辑器中正确显示
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		_update_collision_shape()

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

# 绘制函数 - 在编辑器中显示
func _draw():
	if not Engine.is_editor_hint():
		return
	
	# 绘制填充矩形
	draw_rect(Rect2(-size/2, size), color, true)
	
	# 绘制边框
	draw_rect(Rect2(-size/2, size), border_color, false, border_width)
	
	# 在编辑器中显示目标五十音
	var font = ThemeDB.fallback_font
	var font_size = 12
	var kana_symbol = get_target_kana_symbol()
	draw_string(font, Vector2(-size.x/2 + 5, -size.y/2 + font_size + 5), 
			   kana_symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

# 获取目标五十音符号
func get_target_kana_symbol() -> String:
	if target_kana_selection < KANA_SYMBOLS.size():
		return KANA_SYMBOLS[target_kana_selection]
	return "？"

# 当 Fill 更新时被调用
func on_fill_updated(fill: Fill):
	print("CheckArea2D 收到 Fill 更新通知: ", fill.get_kana_symbol())
	
	# 检查条件是否满足
	if is_condition_met():
		print("条件满足，通知父 ExplodeArea2D")
		# 通知父 ExplodeArea2D 检查所有条件
		var parent = get_parent()
		if parent is ExplodeArea2D:
			parent.check_explode_conditions()

# 检查条件是否满足
func is_condition_met() -> bool:
	# 获取范围内的所有物体
	var overlapping_bodies = get_overlapping_bodies()
	
	print("检查区域 ", get_target_kana_symbol(), " 中的物体数量: ", overlapping_bodies.size())
	
	for body in overlapping_bodies:
		# 检查是否是 Fill 类型
		if body is Fill:
			print("找到 Fill: ", body.get_kana_symbol(), " 匹配目标: ", get_target_kana_symbol())
			# 检查五十音是否匹配
			if body.get_kana_selection() == target_kana_selection:
				print("条件满足!")
				return true
	
	print("条件未满足")
	return false



signal condition_changed(is_met: bool)

# 跟踪当前是否满足条件
var current_condition_met: bool = false


# 当有物体进入区域时
func _on_body_entered(body: Node):
	if body is Fill:
		print("物体进入 CheckArea2D: ", body.name, " 五十音: ", body.get_kana_symbol())
		# 检查条件并通知父节点
		_check_and_notify()

# 当有物体退出区域时
func _on_body_exited(body: Node):
	if body is Fill:
		print("物体退出 CheckArea2D: ", body.name, " 五十音: ", body.get_kana_symbol())
		# 检查条件并通知父节点
		_check_and_notify()

# 检查条件并通知父节点
func _check_and_notify():
	var was_met = current_condition_met
	current_condition_met = is_condition_met()
	
	# 如果条件状态改变，发出信号
	if was_met != current_condition_met:
		print("CheckArea2D 条件状态改变: ", current_condition_met)
		condition_changed.emit(current_condition_met)
		
		# 通知父 ExplodeArea2D 检查所有条件
		var parent = get_parent()
		if parent is ExplodeArea2D:
			parent.check_explode_conditions()


# 序列化/反序列化支持
func _get_property_list():
	var properties = []
	
	# 生成五十音枚举提示字符串
	var kana_hint_string = ""
	for i in range(KANA_SYMBOLS.size()):
		if i > 0:
			kana_hint_string += ","
		kana_hint_string += KANA_SYMBOLS[i] + ":" + str(i)
	
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
		"target_kana_selection":
			target_kana_selection = value
			return true
	
	return false
# 在 CheckArea2D 类中添加以下方法

# 检查条件是否满足
