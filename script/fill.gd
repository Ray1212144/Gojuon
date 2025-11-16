extends StaticBody2D

@export var explode_area : Area2D



func explode():
	queue_free()
