extends CharacterBody2D
class_name Player

# 移动速度（像素/秒）
@export var speed: float = 600

func _physics_process(_delta: float) -> void:
	# 获取输入方向
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	
	# 标准化方向向量（防止斜向移动更快）
	if input_direction.length() > 0:
		velocity = input_direction.normalized() * speed
	else:
		velocity = Vector2.ZERO  # 停止移动
	
	# 应用移动
	move_and_slide()





func _on_reset_pressed() -> void:
	get_tree().reload_current_scene()
