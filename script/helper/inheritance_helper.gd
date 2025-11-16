# set_inheritance_complete.gd
@tool
extends EditorScript

func _run():
	print("=== 开始批量设置五十音场景继承关系 ===")
	
	# 基础场景路径
	var base_scene_path = "res://scene/brick.tscn"
	
	# 检查基础场景是否存在
	if not ResourceLoader.exists(base_scene_path):
		push_error("基础场景不存在: " + base_scene_path)
		return
	
	print("基础场景存在: " + base_scene_path)
	
	# 获取基础场景的 UID (返回 int 类型)
	var base_uid = ResourceLoader.get_resource_uid(base_scene_path)
	if base_uid == -1:
		push_error("无法获取基础场景 UID: " + base_scene_path)
		return
	
	print("基础场景 UID: " + str(base_uid))
	
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
	
	var kana_bricks_dir = "res://scene/kana_bricks/"
	
	print("开始处理 " + str(kana_symbols.size()) + " 个五十音场景...")
	
	var processed_count = 0
	var skipped_count = 0
	var error_count = 0
	
	for kana_symbol in kana_symbols:
		var scene_path = kana_bricks_dir + "brick_" + kana_symbol + ".tscn"
		
		if ResourceLoader.exists(scene_path):
			print("处理场景 [" + str(processed_count + 1) + "/" + str(kana_symbols.size()) + "]: " + kana_symbol)
			
			# 设置继承关系
			if _set_inheritance_direct(scene_path, base_scene_path, base_uid):
				processed_count += 1
				print("✓ 成功设置继承关系: " + kana_symbol)
			else:
				error_count += 1
				print("✗ 设置继承关系失败: " + kana_symbol)
		else:
			skipped_count += 1
			print("⚠ 场景不存在: " + scene_path)
	
	print("=== 处理完成! ===")
	print("成功处理: " + str(processed_count) + " 个场景")
	print("跳过/不存在: " + str(skipped_count) + " 个场景")
	print("错误: " + str(error_count) + " 个场景")
	
	# 刷新资源管理器
	get_editor_interface().get_resource_filesystem().scan()
	print("资源管理器已刷新")

# 直接设置继承关系 - 通过修改场景文件内容
func _set_inheritance_direct(scene_path: String, base_scene_path: String, base_uid: int) -> bool:
	# 使用 FileAccess 读取场景文件
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		push_error("无法打开场景文件: " + scene_path)
		return false
	
	var content = file.get_as_text()
	file.close()
	
	# 检查是否已经有继承关系
	if "instance=ExtResource" in content:
		print("场景已有继承关系: " + scene_path)
		return true
	
	# 解析场景文件内容
	var lines = content.split("\n")
	var new_content = ""
	var has_ext_resource = false
	var has_base_resource = false
	
	# 首先检查是否已经有基础场景的引用
	for line in lines:
		if line.begins_with("[ext_resource"):
			has_ext_resource = true
			if base_scene_path in line:
				has_base_resource = true
				break
	
	# 构建新的场景文件内容
	new_content = ""
	
	# 1. 添加基础场景的 ext_resource（如果不存在）
	if not has_base_resource:
		new_content += "[ext_resource type=\"PackedScene\" path=\"" + base_scene_path + "\" id=" + str(base_uid) + "]\n"
	
	# 2. 复制原有的 ext_resource 部分
	for line in lines:
		if line.begins_with("[ext_resource"):
			new_content += line + "\n"
	
	# 3. 处理节点部分，添加继承关系
	var in_node_section = false
	var root_node_processed = false
	
	for line in lines:
		if line.begins_with("[node"):
			in_node_section = true
			
			# 找到根节点并添加继承关系
			if not root_node_processed and not "instance=" in line:
				line += " instance=ExtResource(" + str(base_uid) + ")"
				root_node_processed = true
		
		new_content += line + "\n"
	
	# 写入修改后的内容
	file = FileAccess.open(scene_path, FileAccess.WRITE)
	if not file:
		push_error("无法写入场景文件: " + scene_path)
		return false
	
	file.store_string(new_content)
	file.close()
	
	return true
