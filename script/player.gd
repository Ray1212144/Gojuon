extends CharacterBody2D
class_name Player

# 移动速度（像素/秒）
var speed :float
@export var animation_player: AnimationPlayer
@export var bonfire : Bonfire
@export var default_speed : float = 600
@onready var camera = $Camera2D 

# 灯光相关属性
@export var light_radius: float = 200.0  # 灯光半径
<<<<<<< Updated upstream
@export var light_area: Area2D  # 引用Area2D节点

# 可见性系统相关
=======
>>>>>>> Stashed changes
@export var _main_node: Main  # 引用Main节点

# 动画名称常量
const ANIM_WALK_DOWN = "walk_down"
const ANIM_WALK_UP = "walk_up"
const ANIM_WALK_LEFT = "walk_left"
const ANIM_WALK_RIGHT = "walk_right"
const ANIM_IDLE_DOWN = "idle_down"
const ANIM_IDLE_UP = "idle_up"
const ANIM_IDLE_LEFT = "idle_left"
const ANIM_IDLE_RIGHT = "idle_right"

# 当前朝向
var current_direction = Vector2.DOWN
var last_direction = Vector2.DOWN

func _ready() -> void:
	speed = default_speed
<<<<<<< Updated upstream
	# 设置灯光Area2D的形状大小
	if light_area:
		# 假设light_area下有一个CollisionShape2D，形状是CircleShape2D
		var shape = light_area.get_child(0)
		if shape is CollisionShape2D:
			var circle_shape = shape.shape as CircleShape2D
			if circle_shape:
				circle_shape.radius = light_radius
		# 连接信号
		light_area.body_entered.connect(_on_light_body_entered)
		light_area.body_exited.connect(_on_light_body_exited)

func _on_light_body_entered(body: Node2D):
	print("物体进入灯光范围: ", body)

func _on_light_body_exited(body: Node2D):
	print("物体离开灯光范围: ", body)
=======
	print("玩家速度: ", speed)
	print("灯光半径: ", light_radius)
	print("主节点引用: ", _main_node != null)
>>>>>>> Stashed changes

func _physics_process(delta: float) -> void:
	# 获取输入方向
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	
	# 如果有输入，更新当前方向
	if input_direction.length() > 0:
		current_direction = input_direction.normalized()
	
	# 标准化方向向量（防止斜向移动更快）
	if input_direction.length() > 0:
		velocity = input_direction.normalized() * speed
	else:
		velocity = Vector2.ZERO  # 停止移动
	
<<<<<<< Updated upstream
	# 更新可见性系统 - 使用圆形视野
	if _main_node and _main_node.has_method("update_player_vision"):
		_main_node.update_player_vision(global_position, light_radius)
	
	# 更新相机中的战争迷雾
	if camera and camera.has_method("update_player_position"):
		camera.update_player_position(global_position)
	
=======
	# 更新可见性系统
	if _main_node and _main_node.has_method("update_player_vision"):
		_main_node.update_player_vision(global_position, light_radius)
	
>>>>>>> Stashed changes
	# 应用移动
	move_and_slide()
	
	# 更新动画
	update_animation()

# 更新角色动画
func update_animation():
	if not animation_player:
		return
	
	var anim_name = ""
	var is_moving = velocity.length() > 0
	
	if is_moving:
		# 移动时，根据当前方向获取移动动画
		anim_name = get_walk_animation_name()
		# 更新最后记录的有效方向
		last_direction = current_direction
	else:
		# 停止时，根据最后的方向获取待机动画
		anim_name = get_idle_animation_name()
	
	# 播放动画（如果动画存在且不是当前动画）
	if anim_name != "" and animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

# 获取行走动画名称
func get_walk_animation_name() -> String:
	if abs(current_direction.x) >= abs(current_direction.y):
		if current_direction.x > 0:
			return ANIM_WALK_RIGHT
		else:
			return ANIM_WALK_LEFT
	else:
		if current_direction.y > 0:
			return ANIM_WALK_DOWN
		else:
			return ANIM_WALK_UP

# 获取待机动画名称
func get_idle_animation_name() -> String:
	# 基于最后移动的方向来决定停止时面朝何方
	if abs(last_direction.x) >= abs(last_direction.y):
		if last_direction.x > 0:
			return ANIM_IDLE_RIGHT
		else:
			return ANIM_IDLE_LEFT
	else:
		if last_direction.y > 0:
			return ANIM_IDLE_DOWN
		else:
			return ANIM_IDLE_UP
