# generate_all_kana_bricks_fixed.gd
@tool
extends EditorScript

func _run():
	print("=== 开始生成完整的五十音 Brick 场景（修复版） ===")
	
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
		"さ", "極", "す", "せ", "そ",
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
		if brick_instance.has_method("set_kana_selection"):
			brick_instance.call("set_kana_selection", i)
		elif brick_instance.has_property("preset_kana_selection"):
			brick_instance.set("preset_kana_selection", i)
		else:
			push_error("场景实例没有预设五十音选择属性或方法")
			brick_instance.queue_free()
			continue
		
		# 设置场景名称
		brick_instance.set_name("Brick_" + kana_symbol)
		
		# 打包场景
		var new_scene = PackedScene.new()
		var error = new_scene.pack(brick_instance)
		
		if error == OK:
			# 保存场景
			error = ResourceSaver.save(new_scene, scene_path)
			
			if error == OK:
				print("✓ 创建场景: " + scene_path)
				
				# 尝试设置继承关系
				_set_scene_inheritance(scene_path, base_brick_path)
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

# 设置场景继承关系
func _set_scene_inheritance(scene_path: String, base_scene_path: String) -> bool:
	# 在 Godot 中设置场景继承关系需要修改场景文件的内容
	# 由于 Godot 的 API 限制，我们需要直接修改场景文件
	
	# 读取场景文件内容
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		push_error("无法打开场景文件: " + scene_path)
		return false
	
	var content = file.get_as_text()
	file.close()
	
	# 查找并替换继承关系
	var lines = content.split("\n")
	var new_content = ""
	var found_inheritance = false
	
	for line in lines:
		if line.begins_with("[ext_resource"):
			# 检查是否已经有继承关系
			if "type=\"PackedScene\"" in line and "uid=" in line:
				# 这可能是基础场景的引用，我们需要添加继承关系
				var uid = line.get_slice("uid=\"", 1).get_slice("\"", 0)
				if uid.is_valid_int():
					# 添加继承属性
					line += " instance=ExtResource(" + uid + ")"
					found_inheritance = true
		new_content += line + "\n"
	
	# 如果没有找到继承关系，尝试添加
	if not found_inheritance:
		# 我们需要找到基础场景的 UID
		var base_uid = _get_resource_uid(base_scene_path)
		if base_uid != "":
			# 在文件开头添加继承关系
			var new_lines = new_content.split("\n")
			new_content = ""
			
			for i in range(new_lines.size()):
				if i == 1:  # 在 [ext_resource] 部分之后添加
					new_content += "[ext_resource type=\"PackedScene\" path=\"" + base_scene_path + "\" id=" + base_uid + "]\n"
				new_content += new_lines[i] + "\n"
	
	# 写入修改后的内容
	file = FileAccess.open(scene_path, FileAccess.WRITE)
	if not file:
		push_error("无法写入场景文件: " + scene_path)
		return false
	
	file.store_string(new_content)
	file.close()
	
	print("✓ 设置场景继承关系: " + scene_path + " -> " + base_scene_path)
	return true

# 修复后的 _get_resource_uid 函数
func _get_resource_uid(resource_path: String) -> String:
	# 这个方法尝试获取资源的 UID
	# 在 Godot 4.x 中，ResourceLoader.get_resource_uid() 返回 int 类型
	if ResourceLoader.has_cached(resource_path):
		var uid = ResourceLoader.get_resource_uid(resource_path)
		if uid != -1:
			return str(uid)  # 将 int 转换为 String
		else:
			return ""
	
	# 如果资源没有加载，尝试加载它
	var resource = load(resource_path)
	if resource:
		var uid = ResourceLoader.get_resource_uid(resource_path)
		if uid != -1:
			return str(uid)  # 将 int 转换为 String
		else:
			return ""
	
	return ""
