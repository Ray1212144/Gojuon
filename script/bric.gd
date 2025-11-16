# brick.gd
@tool
extends StaticBody2D
class_name Brick

# 五十音数据数组
const KANA_SYMBOLS = [
	"あ", "い", "う", "え", "お",
	"か", "き", "く", "け", "こ",
	"さ", "し", "す", "せ", "そ",
	"た", "ち", "つ", "て", "と",
	"な", "に", "ぬ", "ね", "ノ",
	"は", "ひ", "ふ", "へ", "ほ",
	"ま", "み", "む", "め", "も",
	"や", "ゆ", "よ",
	"ら", "り", "る", "れ", "ろ",
	"わ", "を", "ん"
]

# 导出变量，允许在场景中预设五十音
@export var preset_kana_selection: int = 0:
	set(value):
		preset_kana_selection = value
		kana_selection = value
		if Engine.is_editor_hint():
			update_display()

# 实际使用的 kana_selection
var kana_selection: int = 0

@onready var label = $Label

func _ready():
	# 确保有标签节点
	if not has_node("Label"):
		create_label()
	
	# 使用预设值
	kana_selection = preset_kana_selection
	
	# 更新显示
	update_display()

# 在编辑器中实时更新显示
func _process(_delta):
	if Engine.is_editor_hint():
		if label and label.text != get_symbol():
			update_display()

# 获取当前显示的符号
func get_symbol() -> String:
	if kana_selection < KANA_SYMBOLS.size():
		return KANA_SYMBOLS[kana_selection]
	return "？"

# 更新显示
func update_display():
	if has_node("Label"):
		if not label:
			label = $Label
		label.text = get_symbol()
		
		if label is Label:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.visible_ratio = 1.0

# 创建标签节点
func create_label():
	var new_label = Label.new()
	new_label.name = "Label"
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	new_label.size = Vector2(50, 50)
	new_label.add_theme_font_size_override("font_size", 24)
	add_child(new_label)
	label = new_label

# 获取罗马字
func get_romaji() -> String:
	var romaji_map = [
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
	
	if kana_selection < romaji_map.size():
		return romaji_map[kana_selection]
	return ""

# 设置五十音选择
func set_kana_selection(selection: int):
	kana_selection = selection
	if Engine.is_editor_hint():
		update_display()
