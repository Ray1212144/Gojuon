extends CharacterBody2D
class_name Player

# 移动速度（像素/秒）
@export var speed: float = 600
@export var animation_player: AnimationPlayer


# 动画名称常量
const ANIM_WALK_DOWN = "walk_down"
const ANIM_WALK_UP = "walk_up"
const ANIM_WALK_LEFT = "walk_left"
const ANIM_WALK_RIGHT = "walk_right"

# 当前朝向
var current_direction = Vector2.DOWN
var last_direction = Vector2.DOWN

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

# 更新角色动画
func update_animation():
	if not animation_player:
		return
	
	# 确定动画名称
	var anim_name = ""
	
	if velocity.length() > 0:
		# 移动动画
		anim_name = get_walk_animation_name()
	else:
		# 停止时的动画（如果有需要可以添加站立动画）
		pass
	
	# 播放动画（如果动画存在且不是当前动画）
	if anim_name != "" and animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)
	
	# 更新最后的方向
	if velocity.length() > 0:
		last_direction = current_direction

# 获取行走动画名称
func get_walk_animation_name() -> String:
	# 确定主要方向（优先水平方向）
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

func _on_reset_pressed() -> void:
	get_tree().reload_current_scene()
