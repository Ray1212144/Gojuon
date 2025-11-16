extends StaticBody2D
class_name Fill

@export var label : Label
@export var button_container : Container

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
		if child is Button:
			# 如果按钮还没有连接信号，则连接
			if not child.pressed.is_connected(_on_kana_button_pressed):
				child.pressed.connect(_on_kana_button_pressed.bind(child))

func set_kana(selection: int):
	kana_selection = selection
	# 更新 Fill 的显示
	update_display()

func update_display():
	if kana_selection != -1 and kana_selection < KANA_SYMBOLS.size():
		# 在 Label 上显示对应的五十音
		label.text = KANA_SYMBOLS[kana_selection]
	else:
		# 如果没有选择，显示问号或其他默认值
		label.text = ""

func _on_kana_button_pressed(button: Button):
	# 获取按钮的 kana 值并设置给 Fill
	if button.has_method("get_kana_selection"):
		var button_kana = button.get_kana_selection()
		set_kana(button_kana)
		print("Fill 的五十音设置为: ", KANA_SYMBOLS[button_kana])
	# 隐藏按钮容器
	button_container.hide()
	check_explode()
func _on_button_pressed() -> void:
	# 处理点击逻辑
	button_container.show()

func check_explode():
	var areas : Array[Node] =  get_tree().get_nodes_in_group("ExplodeArea2D")
	for i:ExplodeArea2D in areas:
		i.check_explode()
