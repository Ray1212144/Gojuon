@tool
extends Button

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
var _size: Vector2 = Vector2(100, 50)

func _ready():
	# 初始化按钮文本
	update_display()
	
	# 设置按钮大小
	custom_minimum_size = _size
	
	# 连接按下信号
	pressed.connect(_on_button_pressed)

# 属性设置器
func set_kana_selection(value: int):
	_kana_selection = clamp(value, 0, KANA_SYMBOLS.size() - 1)
	update_display()

func get_kana_selection() -> int:
	return _kana_selection



# 更新按钮显示
func update_display():
	text = get_symbol()

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

# 按钮按下时的处理
func _on_button_pressed():
	# 这里可以添加按钮按下时的逻辑
	print("按钮按下:", get_symbol())
	
	# 通知父节点（如果有的话）这个按钮被按下了
	# 父节点可以通过信号或直接调用来获取这个按钮的 kana 值
	if get_parent() and get_parent().has_method("_on_kana_button_pressed"):
		get_parent()._on_kana_button_pressed(self)

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
		"size":
			return get_size()
		"kana_selection":
			return get_kana_selection()
	
	return null

# 设置属性值
func _set(property, value):
	match property:
		"size":
			set_size(value)
			return true
		"kana_selection":
			set_kana_selection(value)
			return true
	
	return false

# 验证属性
func _validate_property(property):
	# 隐藏 Button 原有的 text 属性，因为我们通过 kana_selection 来控制文本
	if property.name == "text":
		property.usage = PROPERTY_USAGE_NO_EDITOR

# 确保在编辑器中正确显示
func _get_configuration_warnings():
	return ""
