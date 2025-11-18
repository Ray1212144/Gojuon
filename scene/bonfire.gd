extends Sprite2D
class_name Bonfire

# 获取检查点节点（用于确定玩家复活位置）
@export var check_point: Node2D 
var main : Main
@export var place : Node2D
@export var file_path:String
var player_entered : bool
var place_position : PlacePostion
# 标识此篝火是否为当前激活的复活点
var is_active: bool = false
var has_pass : bool = false

func _ready() -> void:
	place_position = place.get_parent()
	has_pass = place_position.has_pass
	


func call_reset():
	if has_pass:
		main.travel_fire()
		return
	main.reset(main.get_path_to(place.get_parent()),file_path)



func _process(delta: float) -> void:
	if is_active:
		self_modulate = Color.ORANGE
	else:
		self_modulate = Color.WHITE


func _on_button_pressed() -> void:
	if not player_entered:
		return
	var player :Player = get_tree().get_first_node_in_group("player")
	player.bonfire = self
	var fire = get_tree().get_nodes_in_group("bonfire")
	for i:Bonfire in fire:
		i.is_active = false 
	is_active = true


func _on_area_2d_body_entered(body: Player) -> void:
	if body is Player:
		player_entered = true


func _on_area_2d_body_exited(body: Player) -> void:
	if body is Player:
		player_entered = false
