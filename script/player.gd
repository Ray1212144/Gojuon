extends CharacterBody2D
class_name Player

# 移动速度（像素/秒）
var speed :float
@export var animation_player: AnimationPlayer
@export var bonfire : Bonfire
@export var default_speed : float = 600


# 动画名称常量
const ANIM_WALK_DOWN = "walk_down"
const ANIM_WALK_UP = "walk_up"
const ANIM_WALK_LEFT = "walk_left"
const ANIM_WALK_RIGHT = "walk_right"

# 当前朝向
var current_direction = Vector2.DOWN
var last_direction = Vector2.DOWN

func _ready() -> void:
	speed =  default_speed


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
	
	# 应用移动
	move_and_slide()
	
	# 更新动画
	update_animation()


# 动画名称常量
const ANIM_IDLE_DOWN = "idle_down"   # 你需要创建这些待机动画
const ANIM_IDLE_UP = "idle_up"
const ANIM_IDLE_LEFT = "idle_left"
const ANIM_IDLE_RIGHT = "idle_right"


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
		# !!! 关键修改：停止时，根据最后的方向获取待机动画
		anim_name = get_idle_animation_name()
	
	# 播放动画（如果动画存在且不是当前动画）
	if anim_name != "" and animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

# 获取行走动画名称 (你原有的函数可以保留)
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

# !!! 新增函数：获取待机动画名称
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
