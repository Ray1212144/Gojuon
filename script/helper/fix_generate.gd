# remove_duplicate_nodes_fixed.gd
@tool
extends EditorScript

func _run():
	print("=== 开始批量删除重复节点（修正版） ===")
	
	var kana_bricks_dir = "res://scene/kana_bricks/"
	print("目标目录: " + kana_bricks_dir)
	
	# 获取所有场景文件
	var scene_files = _get_scene_files(kana_bricks_dir)
	print("找到场景文件数量: " + str(scene_files.size()))
	
	if scene_files.size() == 0:
		print("没有找到场景文件")
		return
	
	var editor_interface = get_editor_interface()
	var edited_scene_root = editor_interface.get_edited_scene_root()
	
	# 保存当前场景路径
	var current_scene_path = ""
	if edited_scene_root and edited_scene_root.scene_file_path:
		current_scene_path = edited_scene_root.scene_file_path
	
	var processed_count = 0
	var fixed_count = 0
	
	# 处理每个场景
	for scene_path in scene_files:
		print("处理场景: " + scene_path.get_file())
		
		# 打开场景
		editor_interface.open_scene_from_path(scene_path)
		
		# 等待一小段时间让场景加载
		_short_delay()
		
		# 获取当前场景根节点
		var scene_root = editor_interface.get_edited_scene_root()
		if not scene_root:
			print("⚠ 无法获取场景根节点: " + scene_path.get_file())
			processed_count += 1
			continue
		
		# 删除重复节点
		if _remove_duplicate_nodes_in_editor(scene_root):
			# 保存场景
			var error = editor_interface.save_scene()
			if error == OK:
				fixed_count += 1
				print("✓ 修复完成: " + scene_path.get_file())
			else:
				print("⚠ 保存场景失败: " + scene_path.get_file())
		else:
			print("⚠ 无需修复: " + scene_path.get_file())
		
		processed_count += 1
	
	# 恢复原始场景
	if current_scene_path and ResourceLoader.exists(current_scene_path):
		editor_interface.open_scene_from_path(current_scene_path)
	
	print("=== 批量删除完成 ===")
	print("处理场景总数: " + str(processed_count))
	print("修复场景数量: " + str(fixed_count))
	
	# 刷新资源管理器
	editor_interface.get_resource_filesystem().scan()
	print("资源管理器已刷新")

# 简单的延迟函数
func _short_delay():
	# 使用循环来模拟延迟
	var start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time < 100:
		pass  # 空循环，等待100毫秒

# 获取指定目录下的所有场景文件
func _get_scene_files(directory_path: String) -> Array:
	var files = []
	var dir = DirAccess.open(directory_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				files.append(directory_path + file_name)
			file_name = dir.get_next()
	
	return files

# 在编辑器中删除重复节点
func _remove_duplicate_nodes_in_editor(root_node: Node) -> bool:
	var duplicate_nodes = []
	
	# 查找所有重复节点（名称以数字结尾的节点）
	for child in root_node.get_children():
		var child_name = child.name
		# 检查是否是重复节点（名称以数字结尾）
		if child_name.length() > 1 and _ends_with_digit(child_name):
			# 检查基础名称是否已存在
			var base_name = _remove_trailing_digits(child_name)
			for sibling in root_node.get_children():
				if sibling != child and sibling.name == base_name:
					duplicate_nodes.append(child)
					break
	
	# 如果没有找到重复节点，返回false
	if duplicate_nodes.size() == 0:
		return false
	
	# 删除重复节点
	for node in duplicate_nodes:
		print("删除重复节点: " + node.name)
		root_node.remove_child(node)
		node.queue_free()
	
	return true

# 检查字符串是否以数字结尾
func _ends_with_digit(s: String) -> bool:
	if s.length() == 0:
		return false
	var last_char = s[s.length() - 1]
	return last_char >= '0' and last_char <= '9'

# 移除结尾的数字
func _remove_trailing_digits(s: String) -> String:
	var result = s
	while result.length() > 0 and _ends_with_digit(result):
		result = result.substr(0, result.length() - 1)
	return result
