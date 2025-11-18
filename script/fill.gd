@tool
extends StaticBody2D
class_name Fill

@export var label : Label
@export var button_container : Node2D  # 修改为Node2D，因为按钮现在是Area2D节点

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
var kana_selection: int = -1

func _ready() -> void:
	button_container.hide()
	# 连接所有按钮的按下信号
	_setup_buttons()
	# 初始化显示
	update_display()

func _setup_buttons():
	# 遍历所有按钮并连接信号
	for child in button_container.get_children():
		if child is Area2D and child.has_method("get_kana_selection"):
			# 如果按钮还没有连接信号，则连接
			if not child.pressed.is_connected(_on_kana_button_pressed):
				child.pressed.connect(_on_kana_button_pressed.bind(child))

func set_kana(selection: int):
	kana_selection = selection
	# 更新 Fill 的显示
	update_display()
	# 通知所有重叠的 CheckArea2D
	notify_overlapping_check_areas()

func update_display():
	if kana_selection != -1 and kana_selection < KANA_SYMBOLS.size():
		# 在 Label 上显示对应的五十音
		label.text = KANA_SYMBOLS[kana_selection]
	else:
		# 如果没有选择，显示问号或其他默认值
		label.text = ""

func _on_kana_button_pressed(button: Area2D):
	# 获取按钮的 kana 值并设置给 Fill
	if button.has_method("get_kana_selection"):
		var button_kana = button.get_kana_selection()
		set_kana(button_kana)
		print("Fill 的五十音设置为: ", KANA_SYMBOLS[button_kana])
	
	# 隐藏按钮容器
	button_container.hide()

func _on_button_pressed() -> void:
	if not button_container.visible:
		var buttons = get_tree().get_nodes_in_group("button_ui")
		for i in buttons:
			i.hide()
		button_container.show()
	else:
		button_container.hide()

# 通知所有重叠的 CheckArea2D
func notify_overlapping_check_areas():
	print("Fill 通知重叠的 CheckArea2D...")
	
	# 获取所有 CheckArea2D
	var all_check_areas = get_tree().get_nodes_in_group("CheckArea2D")
	var overlapping_check_areas = []
	
	# 找出所有与当前 Fill 重叠的 CheckArea2D
	for check_area in all_check_areas:
		if check_area.overlaps_body(self):
			print("Fill 与 CheckArea2D 重叠: ", check_area.name)
			overlapping_check_areas.append(check_area)
	
	print("找到 ", overlapping_check_areas.size(), " 个重叠的 CheckArea2D")
	
	# 通知每个重叠的 CheckArea2D
	for check_area in overlapping_check_areas:
		check_area.on_fill_updated(self)

# 获取五十音符号（供外部调用）
func get_kana_symbol() -> String:
	if kana_selection != -1 and kana_selection < KANA_SYMBOLS.size():
		return KANA_SYMBOLS[kana_selection]
	return "？"

# 获取五十音选择（供外部调用）
func get_kana_selection() -> int:
	return kana_selection
