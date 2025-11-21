# 相机脚本中的平滑跟随
extends Camera2D

@export var target: Node2D
@export var smooth_speed: float = 5.0

func _process(delta):
	if target:
		global_position = global_position.lerp(target.global_position, smooth_speed * delta)
