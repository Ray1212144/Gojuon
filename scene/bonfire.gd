extends Sprite2D
class_name Bonfire

# 获取检查点节点（用于确定玩家复活位置）
@export var check_point: Node2D 
var main : Main
@export var place : Node2D
@export var file_path:String

# 标识此篝火是否为当前激活的复活点
var is_active: bool = false

func call_reset():
	main.reset(main.get_path_to(place.get_parent()),file_path)
	place.queue_free()

func _process(delta: float) -> void:
	if is_active:
		self_modulate = Color.ORANGE
	else:
		self_modulate = Color.WHITE


func _on_button_pressed() -> void:
	var player :Player = get_tree().get_first_node_in_group("player")
	player.bonfire = self
	var fire = get_tree().get_nodes_in_group("bonfire")
	for i:Bonfire in fire:
		i.is_active = false 
	is_active = true
