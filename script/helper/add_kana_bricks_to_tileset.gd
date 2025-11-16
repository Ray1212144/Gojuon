# add_kana_bricks_correct.gd
@tool
extends EditorScript

func _run():
	print("=== 使用正确 API 添加五十音 Brick 场景到 TileSet ===")
	
	# 直接加载 TileSet
	var tileset_path = "res://scene/bricks.tres"
	var tile_set = load(tileset_path)
	
	if not tile_set:
		push_error("无法加载 TileSet: " + tileset_path)
		return
	
	print("成功加载 TileSet: " + tileset_path)
	
	# 完整的五十音符号数组
	var kana_symbols = [
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
	
	# 找到或创建场景集合源
	var scenes_source = null
	var source_id = -1
	
	# 尝试找到现有的场景集合源
	for i in range(tile_set.get_source_count()):
		var source = tile_set.get_source(i)
		if source is TileSetScenesCollectionSource:
			scenes_source = source
			source_id = i
			print("找到现有的场景集合源 (ID: " + str(source_id) + ")")
			break
	
	# 如果没有找到，创建一个新的
	if not scenes_source:
		scenes_source = TileSetScenesCollectionSource.new()
		source_id = tile_set.get_source_count()
		tile_set.add_source(scenes_source, source_id)
		print("创建新的场景集合源 (ID: " + str(source_id) + ")")
	
	# 添加每个五十音场景到 TileSet
	var added_count = 0
	var skipped_count = 0
	
	for i in range(kana_symbols.size()):
		var kana_symbol = kana_symbols[i]
		var scene_path = "res://scene/kana_bricks/brick_" + kana_symbol + ".tscn"
		
		# 检查场景文件是否存在
		if not ResourceLoader.exists(scene_path):
			print("⚠ 场景文件不存在: " + scene_path)
			skipped_count += 1
			continue
		
		# 加载场景资源
		var scene_resource = load(scene_path)
		if not scene_resource:
			print("⚠ 无法加载场景: " + scene_path)
			skipped_count += 1
			continue
		
		# 检查是否已经添加（避免重复添加）
		var already_exists = false
		for j in range(scenes_source.get_scene_tiles_count()):
			var tile_id = scenes_source.get_scene_tile_id(j)
			var existing_scene = scenes_source.get_scene_tile_scene(tile_id)
			if existing_scene and existing_scene.resource_path == scene_path:
				already_exists = true
				break
		
		if already_exists:
			print("✓ 场景已存在: " + kana_symbol)
			skipped_count += 1
			continue
		
		# 创建新的场景图块
		var new_tile_id = scenes_source.create_scene_tile(scene_resource)
		
		# 设置图块名称（通过设置占位符显示名称）
		scenes_source.set_scene_tile_display_placeholder(new_tile_id, false)
		
		print("✓ 添加五十音图块: " + kana_symbol + " (ID: " + str(new_tile_id) + ")")
		added_count += 1
	
	print("=== 完成! ===")
	print("成功添加: " + str(added_count) + "个五十音图块")
	print("跳过/已存在: " + str(skipped_count) + "个")
	print("总计: " + str(added_count + skipped_count) + "/" + str(kana_symbols.size()) + "个五十音")
	
	# 保存 TileSet
	if tile_set.resource_path:
		var error = ResourceSaver.save(tile_set, tile_set.resource_path)
		if error == OK:
			print("TileSet 已保存: " + tile_set.resource_path)
		else:
			push_error("保存 TileSet 失败，错误代码: " + str(error))
	
	# 刷新编辑器
	get_editor_interface().get_resource_filesystem().scan()
	print("资源管理器已刷新")
