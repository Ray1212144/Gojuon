class_name ModulateTileLayer
extends TileMapLayer

@export var visible_tiles: Dictionary[Vector2i, bool]
@export var fade_speed: float = 4.0

var cell_alphas: Dictionary[Vector2i, float] = {}

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	# 检查瓦片是否在可见列表中
	if coords in visible_tiles:
		# 如果在可见列表中，设置alpha为1
		cell_alphas[coords] = 1.0
	else:
		# 如果不在可见列表中，检查是否已经有alpha值
		if coords in cell_alphas:
			# 有alpha值，逐渐减少
			var delta = get_process_delta_time()
			cell_alphas[coords] = max(0.0, cell_alphas[coords] - delta * fade_speed)
		else:
			# 没有alpha值，初始化为0
			cell_alphas[coords] = 0.0
	
	# 设置TileData的alpha值
	tile_data.modulate.a = cell_alphas[coords]
