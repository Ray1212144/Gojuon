# generate_all_kana_bricks_with_inheritance_fixed.gd
@tool
extends EditorScript

func _run():
	print("=== 开始生成完整的五十音 Brick 场景（带继承功能）- 修复版 ===")
	
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
	
	print("开始生成完整的五十音场景（带继承功能）...")
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
		
		# 修复：清理重复节点
		_clean_duplicate_nodes(brick_instance)
		
		# 设置预设的五十音选择
		if brick_instance.has_method("set_kana_selection"):
			brick_instance.call("set_kana_selection", i)
		elif brick_instance.has_property("preset_kana_selection"):
			brick_instance.set("preset_kana_selection", i)
		else:
			print("场景实例没有预设五十音选择属性或方法，跳过设置")
		
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
				
				# 设置继承关系
				if _set_scene_inheritance_simple(scene_path, base_brick_path):
					print("✓ 设置继承关系: " + scene_path + " -> " + base_brick_path)
				else:
					push_error("设置继承关系失败: " + scene_path)
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

# 清理重复节点
func _clean_duplicate_nodes(root_node: Node):
	# 获取所有子节点
	var children = root_node.get_children()
	
	# 如果节点数量超过3个（原场景只有3个子节点），则清理重复节点
	if children.size() > 3:
		print("检测到重复节点，开始清理...")
		
		# 保留前3个节点（Sprite2D, CollisionShape2D, Label）
		var nodes_to_keep = []
		for i in range(min(3, children.size())):
			nodes_to_keep.append(children[i])
			print("保留节点: " + children[i].name)
		
		# 移除多余的节点
		for child in children:
			if not child in nodes_to_keep:
				root_node.remove_child(child)
				child.queue_free()
				print("移除重复节点: " + child.name)
		
		print("节点清理完成，剩余节点数: " + str(root_node.get_child_count()))

# 生成简单的UID（用于ext_resource）
func _generate_uid() -> String:
	var random = RandomNumberGenerator.new()
	random.randomize()
	return str(random.randi() % 1000000000)

func _set_scene_inheritance_simple(scene_path: String, base_scene_path: String) -> bool:
	# 读文件
	var f = FileAccess.open(scene_path, FileAccess.READ)
	if not f:
		push_error("无法打开场景文件: " + scene_path)
		return false
	var content: String = f.get_as_text()
	f.close()

	# 把 split 的结果转换成普通 Array，方便使用 insert/append 等
	var raw_lines = content.split("\n")
	var lines: Array = []
	for i in range(raw_lines.size()):
		lines.append(raw_lines[i])

	# 找到 [gd_scene] header
	var header_index := -1
	for i in range(lines.size()):
		if lines[i].begins_with("[gd_scene"):
			header_index = i
			break
	# 如果没有 header，就插入一个默认 header
	if header_index == -1:
		lines.insert(0, '[gd_scene load_steps=1 format=2]')
		header_index = 0

	# 扫描已有 ext_resource，找出最大的 id 和最后一个 ext_resource 的位置
	var max_id := 0
	var last_ext_idx := header_index
	for i in range(header_index + 1, lines.size()):
		var l := str(lines[i]).strip_edges()
		if l.begins_with("[ext_resource"):
			last_ext_idx = i
			var id_pos := l.find("id=")
			if id_pos != -1:
				var j := id_pos + 3
				var num := ""
				while j < l.length():
					var c := l.substr(j, 1)
					# 用简单的范围比较判断数字字符
					if c >= "0" and c <= "9":
						num += c
					else:
						break
					j += 1
				if num != "":
					var n := int(num)
					if n > max_id:
						max_id = n
		# 一旦遇到第一个 [node 开头，就可以停止寻找 ext_resource 区块
		elif l.begins_with("[node"):
			break

	var new_id := max_id + 1
	var ext_line := '[ext_resource path="' + base_scene_path + '" type="PackedScene" id=' + str(new_id) + ']'

	# 插入新的 ext_resource（放在现有 ext_resource 之后）
	lines.insert(last_ext_idx + 1, ext_line)

	# 为每个 [node ...] 行添加 instance=ExtResource(N)（如果尚未存在 instance=）
	for i in range(lines.size()):
		var ln := str(lines[i])
		if ln.begins_with("[node"):
			if "instance=" in ln:
				continue
			var rb := ln.rfind("]")
			if rb != -1:
				var left := ln.substr(0, rb)
				lines[i] = left + " instance=ExtResource(" + str(new_id) + ")]"
			else:
				# 极端情况：没有 ]，就追加一行 instance
				lines[i] = ln
				lines.insert(i + 1, "instance=ExtResource(" + str(new_id) + ")")

	# 把 lines 拼回字符串
	var new_content: String = ""
	for i in range(lines.size()):
		new_content += str(lines[i])
		# 不在最后一行也添加换行，保证文件格式正确
		if i < lines.size():
			new_content += "\n"

	# 写回文件
	var wf = FileAccess.open(scene_path, FileAccess.WRITE)
	if not wf:
		push_error("无法写入场景文件: " + scene_path)
		return false
	wf.store_string(new_content)
	wf.close()
	return true
