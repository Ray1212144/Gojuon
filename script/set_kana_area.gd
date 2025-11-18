@tool
extends Area2D
class_name KanaAreaButton

# 五十音数据数组
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

# 罗马字映射
const ROMAJI_MAP = [
	"a", "i", "u", "e", "o",
	"ka", "ki", "ku", "ke", "ko",
	"sa", "shi", "su", "se", "so",
	"ta", "chi", "tsu", "te", "to",
	"na", "ni", "nu", "ne", "no",
	"ha", "hi", "fu", "he", "ho",
	"ma", "mi", "mu", "me", "mo",
	"ya", "yu", "yo",
	"ra", "ri", "ru", "re", "ro",
	"wa", "wo", "n"
]

# 内部变量
var _kana_selection: int = 0
var is_hovered = false
var is_pressed = false

# 信号定义
signal pressed
signal button_hovered(node)
signal button_exited


func _ready():
	# 确保可点击
	input_pickable = true

	# 连接信号
	if not Engine.is_editor_hint():

		connect("input_event", _on_input_event)
		connect("mouse_entered", _on_mouse_entered)
		connect("mouse_exited", _on_mouse_exited)

	# 初始化显示
	update_display()


# 属性设置器
func set_kana_selection(value: int):
	_kana_selection = clamp(value, 0, KANA_SYMBOLS.size() - 1)
	update_display()


func get_kana_selection() -> int:
	return _kana_selection

# 更新显示 - 由于没有Label，这里可以添加自定义绘制
func update_display():
	# 触发重绘
	queue_redraw()




# 获取当前显示的五十音符号
func get_symbol() -> String:
	if _kana_selection < KANA_SYMBOLS.size():
		return KANA_SYMBOLS[_kana_selection]
	return "？"

# 获取罗马字
func get_romaji() -> String:
	if _kana_selection < ROMAJI_MAP.size():
		return ROMAJI_MAP[_kana_selection]
	return ""

# 输入事件处理
func _on_input_event(viewport, event, shape_idx):

	
	if event is InputEventMouseButton:
		print("KanaAreaButton: 鼠标按钮事件 - 按下: ", event.pressed, " 按钮: ", event.button_index)
		
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_pressed = true
			modulate = Color(0.8, 0.8, 0.8)
			print("KanaAreaButton: 鼠标按下")
			
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_pressed:
			is_pressed = false
			modulate = Color(1, 1, 1)
			
			if is_hovered:
				print("KanaAreaButton: 触发pressed信号")
				pressed.emit()
				print("五十音按钮按下:", get_symbol())
			else:
				print("KanaAreaButton: 鼠标不在按钮上，不触发信号")

# 鼠标进入区域
func _on_mouse_entered():

	is_hovered = true
	button_hovered.emit(self)
	modulate = Color(1.1, 1.1, 1.1)

# 鼠标离开区域
func _on_mouse_exited():

	is_hovered = false
	button_exited.emit()
	modulate = Color(1, 1, 1)

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
		"name": "kana_selection",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": kana_hint_string
	})
	
	return properties

# 获取属性值
func _get(property):
	match property:
		"kana_selection":
			return get_kana_selection()
	
	return null

# 设置属性值
func _set(property, value):
	match property:
		"kana_selection":
			set_kana_selection(value)
			return true
	
	return false
