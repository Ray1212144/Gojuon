# generate_all_kana_bricks.gd
@tool
extends EditorScript

func _run():
	print("=== 开始生成完整的五十音 Brick 场景 ===")
	
	# 检查基础场景
	var base_brick_path = "res://scene/brick.tscn"
	print("检查基础场景: " + base_brick_path)
	
	if not ResourceLoader.exists(base_brick_path):
		push_error("基础 Brick 场景不存在: " + base_brick_path)
		return
	
	print("基础场景存在")
	
	# 检查目录访问
	var dir = DirAccess.open("res://")
	if not dir:
		push_error("无法访问资源目录")
		return
	
	print("可以访问资源目录")
	
	var kana_bricks_dir = "res://scene/kana_bricks/"
	print("目标目录: " + kana_bricks_dir)
	
	# 创建目录
	if not dir.dir_exists(kana_bricks_dir):
		print("创建目录: " + kana_bricks_dir)
		var error = dir.make_dir_recursive(kana_bricks_dir)
		if error != OK:
			push_error("无法创建目录: " + kana_bricks_dir)
			return
		print("目录创建成功")
	else:
		print("目录已存在")
	
	# 完整的五十音符号数组（46个）
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
	
	print("开始生成完整的五十音场景...")
	print("总共需要生成: " + str(kana_symbols.size()) + "个场景")
	
	# 为每个五十音创建场景
	for i in range(kana_symbols.size()):
		var kana_symbol = kana_symbols[i]
		print("处理五十音 [" + str(i+1) + "/" + str(kana_symbols.size()) + "]: " + kana_symbol)
		
		# 检查是否已经存在（避免重复创建）
		var scene_path = kana_bricks_dir + "brick_" + kana_symbol + ".tscn"
		if ResourceLoader.exists(scene_path):
			print("✓ 场景已存在: " + scene_path)
			continue
		
		# 创建新场景实例
		var brick_scene = load(base_brick_path)
		if not brick_scene:
			push_error("无法加载基础场景: " + base_brick_path)
			continue
			
		var brick_instance = brick_scene.instantiate()
		if not brick_instance:
			push_error("无法实例化基础场景")
			continue
		
		# 设置预设的五十音选择
		brick_instance.set("preset_kana_selection", i)
		brick_instance.set_name("Brick_" + kana_symbol)
		
		# 打包场景
		var new_scene = PackedScene.new()
		var error = new_scene.pack(brick_instance)
		
		if error == OK:
			# 保存场景
			error = ResourceSaver.save(new_scene, scene_path)
			
			if error == OK:
				print("✓ 创建场景: " + scene_path)
			else:
				push_error("保存场景失败: " + scene_path + " (错误代码: " + str(error) + ")")
		else:
			push_error("打包场景失败: " + kana_symbol + " (错误代码: " + str(error) + ")")
		
		# 清理实例
		brick_instance.queue_free()
	
	print("=== 完成! 总共处理了" + str(kana_symbols.size()) + "个五十音场景 ===")
	
	# 刷新资源管理器
	get_editor_interface().get_resource_filesystem().scan()
	print("资源管理器已刷新")
