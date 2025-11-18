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

# 导出变量，允许在场景中预设五十音
@export var preset_kana_selection: int = 0:
	set(value):
		preset_kana_selection = value
		# 在编辑器中，如果还没有文件名，使用预设值
		if Engine.is_editor_hint():
			if not _has_valid_filename():
				kana_selection = value
				update_display()

# 实际使用的 kana_selection
var kana_selection: int = 0

@onready var label = $Label



func _ready():
	# 确保有标签节点
	if not has_node("Label"):
		create_label()
	
	# 在编辑器和运行时都根据文件名设置 kana_selection
	_set_kana_selection_from_filename()
	
	# 更新显示
	update_display()

# 在编辑器中实时更新显示
func _process(_delta):
	if Engine.is_editor_hint():
		# 检查文件名是否发生变化
		if _has_filename_changed():
			_set_kana_selection_from_filename()
			update_display()
		
		# 确保显示正确
		if label and label.text != get_symbol():
			update_display()

# 检查是否有有效的文件名
func _has_valid_filename() -> bool:
	var scene_file_path = get_scene_file_path()
	return scene_file_path and scene_file_path != "" and scene_file_path.get_file().begins_with("brick_")

# 检查文件名是否发生变化
var _last_filename = ""
func _has_filename_changed() -> bool:
	var current_filename = ""
	var scene_file_path = get_scene_file_path()
	if scene_file_path and scene_file_path != "":
		current_filename = scene_file_path.get_file()
	
	if current_filename != _last_filename:
		_last_filename = current_filename
		return true
	return false

# 根据文件名自动设置 kana_selection
func _set_kana_selection_from_filename():
	var scene_file_path = get_scene_file_path()
	if scene_file_path and scene_file_path != "":
		var file_name = scene_file_path.get_file().get_basename()
		
		# 提取假名部分（假设文件名格式为 "brick_あ"）
		if file_name.begins_with("brick_"):
			var kana_symbol = file_name.substr(6)  # 去掉 "brick_" 前缀
			
			# 在五十音数组中查找对应的索引
			var index = KANA_SYMBOLS.find(kana_symbol)
			if index != -1:
				kana_selection = index
				if Engine.is_editor_hint():
					print("根据文件名设置假名: " + kana_symbol + " (索引: " + str(index) + ")")
			else:
				# 如果文件名中的假名无效，使用预设值
				kana_selection = preset_kana_selection
				if Engine.is_editor_hint():
					push_error("无法从文件名识别假名: " + kana_symbol + "，使用预设值: " + str(preset_kana_selection))
		else:
			# 文件名格式不符合，使用预设值
			kana_selection = preset_kana_selection
			if Engine.is_editor_hint():
				print("文件名格式不符合预期: " + file_name + "，使用预设值: " + str(preset_kana_selection))
	else:
		# 无法获取文件路径，使用预设值
		kana_selection = preset_kana_selection
		if Engine.is_editor_hint():
			print("无法获取场景文件路径，使用预设值: " + str(preset_kana_selection))

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
	if kana_selection < ROMAJI_MAP.size():
		return ROMAJI_MAP[kana_selection]
	return ""

# 设置五十音选择（主要用于编辑器）
func set_kana_selection(selection: int):
	kana_selection = selection
	update_display()
