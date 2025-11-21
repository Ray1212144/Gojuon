extends CanvasLayer

# 光标移动速度
@export var cursor_speed: float = 500.0
# 光标是否限制在屏幕内
@export var clamp_to_screen: bool = true
# 控制器死区（避免摇杆轻微移动导致光标抖动）
@export var deadzone: float = 0.2
# 光标尺寸
@export var cursor_size: Vector2 = Vector2(20, 20)
# 光标颜色
@export var cursor_color: Color = Color(1, 0, 0, 1)  # 红色

# 吸附功能设置
@export var snap_enabled: bool = true  # 是否启用吸附功能
@export var snap_distance: float = 150.0  # 吸附距离（像素）
@export var snap_strength: float = 0.8  # 吸附强度（0-1，越大吸附越强）
@export var highlight_snapped_control: bool = true  # 是否高亮被吸附的控件
@export var highlight_color: Color = Color(0, 1, 0, 0.3)  # 高亮颜色
@export var snap_group: String = "snapable"  # 可吸附对象的组名
@export var snap_point_node_name: String = "SnapPoint"  # 吸附点子节点的名称（如果为空则使用节点本身）

# 调试设置
@export var show_debug_info: bool = false
@export var show_snap_radius: bool = false

# 内部变量
var is_pressed = false
var is_active = true
var last_input_vector = Vector2.ZERO
var tween: Tween
var viewport_size: Vector2
var debug_frame_count = 0
var cursor: ColorRect

# 吸附相关变量
var current_snapped_node: Node = null
var is_snapping: bool = false
var snap_target_position: Vector2 = Vector2.ZERO
var highlight_rect: ColorRect
var snap_candidates: Array = []

# 信号
signal cursor_moved(position)
signal cursor_clicked(position)
signal cursor_pressed(position)
signal cursor_released(position)
signal control_snapped(node)  # 当光标吸附到节点时发出
signal control_unsnapped()  # 当光标解除吸附时发出

func _ready():
	print("=== 控制器光标初始化开始 (CanvasLayer方案) ===")
	
	# 基本设置
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 设置CanvasLayer层级，确保在最前面
	layer = 100
	
	# 等待一帧确保视口已准备好
	await get_tree().process_frame
	
	# 获取视口大小
	viewport_size = get_viewport().get_visible_rect().size
	print("视口大小: ", viewport_size)
	
	# 创建光标
	_create_cursor()
	
	# 创建高亮矩形（用于显示吸附状态）
	_create_highlight_rect()
	
	# 初始位置设为屏幕中心
	cursor.position = viewport_size / 2 - cursor_size / 2
	print("光标初始位置: ", cursor.position)
	print("光标尺寸: ", cursor_size)
	
	print("=== 控制器光标初始化完成 ===")

func _create_cursor():
	# 创建一个简单的颜色矩形作为光标
	cursor = ColorRect.new()
	cursor.color = cursor_color
	cursor.size = cursor_size
	cursor.name = "ControllerCursor"
	
	# 添加到CanvasLayer
	add_child(cursor)
	
	print("创建光标，尺寸: ", cursor.size)

func _create_highlight_rect():
	# 创建高亮矩形用于显示吸附状态
	highlight_rect = ColorRect.new()
	highlight_rect.color = highlight_color
	highlight_rect.size = Vector2(10, 10)  # 初始大小，会在吸附时调整
	highlight_rect.visible = false
	highlight_rect.name = "SnapHighlight"
	add_child(highlight_rect)

func _process(delta):
	debug_frame_count += 1
	
	# 每60帧输出一次调试信息
	if debug_frame_count % 60 == 0 and show_debug_info:
		print("光标状态 - 帧: ", debug_frame_count, ", 位置: ", cursor.position, ", 吸附: ", is_snapping, ", 激活: ", is_active, ", 可见: ", visible)
		if current_snapped_node:
			print("当前吸附节点: ", current_snapped_node.name, " 吸附点: ", _get_snap_point_position(current_snapped_node))
	
	if not is_active:
		return
		
	# 获取控制器输入
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("controller_left", "controller_right")
	input_vector.y = Input.get_axis("controller_up", "controller_down")
	
	# 调试输入
	if input_vector != Vector2.ZERO and debug_frame_count % 30 == 0 and show_debug_info:
		print("控制器输入向量: ", input_vector)
	
	# 应用死区
	if input_vector.length() < deadzone:
		input_vector = Vector2.ZERO
	else:
		# 重新映射输入值，使移动更平滑
		input_vector = input_vector.normalized() * ((input_vector.length() - deadzone) / (1.0 - deadzone))
	
	# 处理吸附逻辑
	_handle_snap_logic(input_vector, delta)
	
	# 处理点击输入
	var click_just_pressed = Input.is_action_just_pressed("controller_click")
	var click_just_released = Input.is_action_just_released("controller_click")
	
	if click_just_pressed and show_debug_info:
		print("控制器点击按钮按下")
	
	# 点击开始
	if click_just_pressed and not is_pressed:
		is_pressed = true
		_on_click_start()
	
	# 点击结束
	if click_just_released and is_pressed:
		is_pressed = false
		_on_click_end()

func _handle_snap_logic(input_vector: Vector2, delta: float):
	if not snap_enabled:
		# 吸附功能禁用，正常移动光标
		if input_vector != Vector2.ZERO:
			_move_cursor_normal(input_vector, delta)
		return
	
	# 始终查找吸附候选
	_find_snap_candidates()
	
	# 如果有输入
	if input_vector != Vector2.ZERO and input_vector.length() > deadzone * 1.2:
		if is_snapping:
			# 更严格的解除吸附条件：需要明显反向输入
			var to_snap_dir = (snap_target_position - get_cursor_position()).normalized()
			var dot_product = input_vector.normalized().dot(to_snap_dir)
			
			# 只有当输入方向与吸附点方向明显相反时才解除（角度大于135度）
			if dot_product < -0.7:
				_unsnap_from_node()
				_move_cursor_normal(input_vector, delta)
			else:
				# 在吸附状态下，允许移动但有限制
				_move_cursor_while_snapped(input_vector, delta)
		else:
			# 没有吸附时，移动并检查是否可以吸附
			_move_cursor_and_check_snap(input_vector, delta)
	else:
		# 输入很小或没有输入时，加强吸附
		if not is_snapping and not snap_candidates.is_empty():
			_try_snap_to_nearest_node()
		elif is_snapping:
			_maintain_snap()

func _move_cursor_normal(input_vector: Vector2, delta: float):
	# 正常移动光标
	var old_position = cursor.position
	cursor.position += input_vector * cursor_speed * delta
	last_input_vector = input_vector
	
	# 限制光标在屏幕内
	if clamp_to_screen:
		viewport_size = get_viewport().get_visible_rect().size
		cursor.position.x = clamp(cursor.position.x, 0, viewport_size.x - cursor_size.x)
		cursor.position.y = clamp(cursor.position.y, 0, viewport_size.y - cursor_size.y)
	
	# 发出光标移动信号
	emit_signal("cursor_moved", cursor.position + cursor_size/2)
	
	# 调试：显示移动距离
	if debug_frame_count % 30 == 0 and old_position != cursor.position and show_debug_info:
		print("光标移动: ", old_position, " -> ", cursor.position)

func _move_cursor_and_check_snap(input_vector: Vector2, delta: float):
	# 保存移动前的位置
	var old_position = cursor.position
	
	# 正常移动
	_move_cursor_normal(input_vector, delta)
	
	# 检查移动后是否有可吸附的节点
	if not snap_candidates.is_empty():
		# 找到最近的候选节点
		var nearest_candidate = _get_nearest_snap_candidate()
		if nearest_candidate:
			var snap_point = _get_snap_point_position(nearest_candidate)
			var distance = get_cursor_position().distance_to(snap_point)
			
			# 更宽松的吸附条件：只要有候选节点且距离在范围内就尝试吸附
			if distance < snap_distance * 1.5:  # 扩大吸附检测范围
				_snap_to_node(nearest_candidate)

func _move_cursor_while_snapped(input_vector: Vector2, delta: float):
	if not is_snapping or not current_snapped_node:
		return
	
	# 在吸附状态下允许小范围移动
	var movement = input_vector * cursor_speed * delta * 0.3  # 降低移动速度
	var new_position = cursor.position + movement
	
	# 计算与吸附点的距离
	var distance_to_snap = new_position.distance_to(snap_target_position - cursor_size / 2)
	var max_distance = snap_distance * 0.5  # 最大允许移动距离
	
	if distance_to_snap > max_distance:
		# 如果移动太远，限制在最大距离内
		var direction_from_snap = (new_position - (snap_target_position - cursor_size / 2)).normalized()
		new_position = (snap_target_position - cursor_size / 2) + direction_from_snap * max_distance
	
	cursor.position = new_position
	emit_signal("cursor_moved", cursor.position + cursor_size/2)

func _try_snap_to_nearest_node():
	if not snap_candidates.is_empty():
		var nearest_candidate = _get_nearest_snap_candidate()
		if nearest_candidate:
			var snap_point = _get_snap_point_position(nearest_candidate)
			var distance = get_cursor_position().distance_to(snap_point)
			if distance < snap_distance:
				_snap_to_node(nearest_candidate)

func _find_snap_candidates():
	snap_candidates.clear()
	
	# 获取所有属于吸附组的节点
	var snapable_nodes = get_tree().get_nodes_in_group(snap_group)
	var cursor_pos = get_cursor_position()
	
	for node in snapable_nodes:
		if _is_node_valid_for_snap(node):
			var snap_point = _get_snap_point_position(node)
			var distance = cursor_pos.distance_to(snap_point)
			
			if distance < snap_distance:
				snap_candidates.append({
					"node": node,
					"distance": distance,
					"position": snap_point
				})

# 改进的节点有效性检查
func _is_node_valid_for_snap(node: Node) -> bool:
	if not is_instance_valid(node):
		return false
	
	if not node.is_inside_tree():
		return false
	
	# 检查可见性
	if node is CanvasItem and not node.visible:
		return false
	
	# 检查是否禁用
	if node is Control and node.disabled:
		return false
	
	return true

# 改进的吸附点获取函数
func _get_snap_point_position(node: Node) -> Vector2:
	# 优先查找指定的吸附点子节点
	if snap_point_node_name and not snap_point_node_name.is_empty():
		var snap_point_node = _find_child_by_name(node, snap_point_node_name)
		if snap_point_node and snap_point_node is Node2D:
			return snap_point_node.global_position
	
	# 对于Control节点，使用更准确的中心计算
	if node is Control:
		var control = node as Control
		var global_rect = control.get_global_rect()
		return global_rect.get_center()
	
	# 对于Node2D节点，直接使用全局位置
	elif node is Node2D:
		return node.global_position
	
	# 对于其他节点，尝试获取全局边界框
	elif node.has_method("get_global_rect"):
		var rect = node.get_global_rect()
		return rect.get_center()
	
	# 最后手段：使用变换后的位置
	else:
		return _get_node_global_position(node)

func _find_child_by_name(node: Node, name: String) -> Node:
	# 递归查找指定名称的子节点
	if node.get_name() == name:
		return node
	
	for child in node.get_children():
		var result = _find_child_by_name(child, name)
		if result:
			return result
	
	return null

func _get_node_global_position(node: Node) -> Vector2:
	# 获取节点的全局位置
	if node is CanvasItem:
		return node.global_position
	elif node.has_method("get_global_position"):
		return node.get_global_position()
	else:
		# 对于其他类型的节点，尝试获取位置
		if node.has_method("get_position"):
			# 如果只有局部位置，尝试转换为全局位置
			var parent_pos = Vector2.ZERO
			if node.get_parent() and node.get_parent().has_method("get_global_position"):
				parent_pos = node.get_parent().get_global_position()
			return parent_pos + node.get_position()
		else:
			# 最后手段，返回零向量
			if show_debug_info:
				print("警告: 无法获取节点 ", node.name, " 的全局位置")
			return Vector2.ZERO

func _get_nearest_snap_candidate():
	if snap_candidates.is_empty():
		return null
	
	# 按距离排序并返回最近的
	snap_candidates.sort_custom(func(a, b): return a.distance < b.distance)
	return snap_candidates[0].node

func _snap_to_node(node: Node):
	if is_snapping and current_snapped_node == node:
		return
	
	if show_debug_info:
		print("吸附到节点: ", node.name, " 吸附点位置: ", _get_snap_point_position(node))
	
	is_snapping = true
	current_snapped_node = node
	snap_target_position = _get_snap_point_position(node)
	
	# 确保吸附点在屏幕内
	if not _is_point_in_screen(snap_target_position):
		if show_debug_info:
			print("吸附点不在屏幕内，调整到屏幕内")
		snap_target_position = _clamp_point_to_screen(snap_target_position)
	
	# 平滑移动到吸附点
	if tween:
		tween.kill()
	tween = create_tween()
	
	# 根据吸附强度调整动画时间
	var snap_duration = 0.15 * (2.0 - snap_strength)  # 强度越大，时间越短
	
	tween.tween_property(cursor, "position", snap_target_position - cursor_size / 2, snap_duration)
	tween.tween_callback(_on_snap_complete)
	
	# 显示高亮
	if highlight_snapped_control:
		_highlight_node(node)
	
	emit_signal("control_snapped", node)

# 检查点是否在屏幕内
func _is_point_in_screen(point: Vector2) -> bool:
	return point.x >= 0 and point.x <= viewport_size.x and point.y >= 0 and point.y <= viewport_size.y

# 将点限制在屏幕内
func _clamp_point_to_screen(point: Vector2) -> Vector2:
	return Vector2(
		clamp(point.x, 0, viewport_size.x),
		clamp(point.y, 0, viewport_size.y)
	)

func _on_snap_complete():
	if show_debug_info:
		print("吸附完成，光标位置: ", cursor.position, " 目标位置: ", snap_target_position)

func _unsnap_from_node():
	if not is_snapping:
		return
	
	if show_debug_info:
		print("解除吸附")
	is_snapping = false
	
	# 隐藏高亮
	highlight_rect.visible = false
	
	if current_snapped_node:
		emit_signal("control_unsnapped")
		current_snapped_node = null

func _maintain_snap():
	if not is_snapping or not current_snapped_node:
		_unsnap_from_node()
		return
	
	# 确保节点仍然存在且可见
	if not is_instance_valid(current_snapped_node) or not _is_node_valid_for_snap(current_snapped_node):
		_unsnap_from_node()
		return
	
	# 更新吸附目标位置（防止节点移动）
	snap_target_position = _get_snap_point_position(current_snapped_node)
	
	# 确保吸附点在屏幕内
	if not _is_point_in_screen(snap_target_position):
		snap_target_position = _clamp_point_to_screen(snap_target_position)
	
	# 根据吸附强度决定如何保持位置
	if snap_strength >= 0.9:
		# 高强度吸附，直接设置位置
		cursor.position = snap_target_position - cursor_size / 2
	else:
		# 低强度吸附，使用插值
		var target_pos = snap_target_position - cursor_size / 2
		cursor.position = cursor.position.lerp(target_pos, snap_strength * 0.1)
	
	# 更新高亮
	if highlight_snapped_control:
		_highlight_node(current_snapped_node)

func _highlight_node(node: Node):
	if not highlight_rect:
		return
	
	highlight_rect.visible = true
	
	# 获取吸附点位置
	var snap_point = _get_snap_point_position(node)
	
	# 确保高亮显示在屏幕内
	snap_point = _clamp_point_to_screen(snap_point)
	
	# 设置高亮矩形大小和位置
	highlight_rect.size = Vector2(30, 30)  # 固定大小
	highlight_rect.global_position = snap_point - highlight_rect.size / 2  # 以吸附点为中心

func _on_click_start():
	if show_debug_info:
		print("点击开始")
	
	# 点击开始时的逻辑
	cursor.color = Color(0.7, 0, 0, 1)  # 变暗表示按下
	
	# 检测UI点击
	var click_position = cursor.position + cursor_size/2
	_check_ui_click(click_position)
	
	# 发出信号
	emit_signal("cursor_pressed", click_position)

func _on_click_end():
	if show_debug_info:
		print("点击结束")
	
	# 点击结束时的逻辑
	cursor.color = Color(1, 0, 0, 1)  # 恢复红色
	
	# 发出信号
	emit_signal("cursor_released", cursor.position + cursor_size/2)
	emit_signal("cursor_clicked", cursor.position + cursor_size/2)

func _check_ui_click(click_position: Vector2):
	# 使用多种方法检测UI点击
	_direct_ui_click_detection(click_position)
	_manual_control_detection(click_position)

# 直接UI点击检测方法
func _direct_ui_click_detection(click_position: Vector2):
	# 使用 Godot 的输入系统模拟鼠标点击
	# 首先发送鼠标移动事件，确保鼠标位置正确
	var mouse_motion_event = InputEventMouseMotion.new()
	mouse_motion_event.position = click_position
	mouse_motion_event.global_position = click_position
	mouse_motion_event.relative = Vector2.ZERO
	Input.parse_input_event(mouse_motion_event)
	
	# 发送鼠标按下事件
	var mouse_button_press = InputEventMouseButton.new()
	mouse_button_press.position = click_position
	mouse_button_press.global_position = click_position
	mouse_button_press.button_index = MOUSE_BUTTON_LEFT
	mouse_button_press.pressed = true
	mouse_button_press.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse_button_press.device = -1  # 使用默认设备
	
	Input.parse_input_event(mouse_button_press)
	
	# 短暂延迟后发送释放事件
	await get_tree().create_timer(0.05).timeout
	
	# 发送鼠标释放事件
	var mouse_button_release = InputEventMouseButton.new()
	mouse_button_release.position = click_position
	mouse_button_release.global_position = click_position
	mouse_button_release.button_index = MOUSE_BUTTON_LEFT
	mouse_button_release.pressed = false
	mouse_button_release.button_mask = 0
	mouse_button_release.device = -1
	
	Input.parse_input_event(mouse_button_release)
	
	if show_debug_info:
		print("直接UI点击检测完成，位置: ", click_position)

# 手动检测控件的方法
func _manual_control_detection(click_position: Vector2):
	# 如果有吸附的节点，优先处理它
	if is_snapping and current_snapped_node and current_snapped_node is Control:
		if show_debug_info:
			print("点击吸附的控件: ", current_snapped_node.name)
		_send_click_to_control(current_snapped_node, click_position)
		return
	
	# 获取所有控件
	var controls = _get_all_interactable_controls(get_tree().root)
	
	# 移除光标自身，避免向自己发送点击事件
	controls.erase(cursor)
	
	# 按z_index排序（从高到低）
	controls.sort_custom(_sort_controls_by_z_index)
	
	for control in controls:
		# 检查点击位置是否在控件内
		var control_rect = Rect2(control.global_position, control.size)
		if control_rect.has_point(click_position):
			if show_debug_info:
				print("点击控件: ", control.name)
			# 发送鼠标事件到控件
			_send_click_to_control(control, click_position)
			break

func _get_all_interactable_controls(node: Node) -> Array:
	var controls = []
	
	if node is Control:
		var control = node as Control
		if control.visible and control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			controls.append(control)
	
	for child in node.get_children():
		controls.append_array(_get_all_interactable_controls(child))
	
	return controls

# 排序控件函数
func _sort_controls_by_z_index(a, b):
	return a.z_index > b.z_index

# 发送点击事件到特定控件
func _send_click_to_control(control: Control, position: Vector2):
	# 首先确保鼠标位置正确
	var mouse_motion_event = InputEventMouseMotion.new()
	mouse_motion_event.position = control.get_local_mouse_position()
	mouse_motion_event.global_position = position
	mouse_motion_event.relative = Vector2.ZERO
	mouse_motion_event.device = -1
	
	if control.has_method("_input"):
		control._input(mouse_motion_event)
	elif control.has_method("_gui_input"):
		control._gui_input(mouse_motion_event)
	
	# 创建鼠标按下事件
	var press_event = InputEventMouseButton.new()
	press_event.position = control.get_local_mouse_position()
	press_event.global_position = position
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	press_event.device = -1
	
	# 发送事件到控件
	if control.has_method("_input"):
		control._input(press_event)
	elif control.has_method("_gui_input"):
		control._gui_input(press_event)
	
	# 短暂延迟
	await get_tree().create_timer(0.05).timeout
	
	# 创建鼠标释放事件
	var release_event = InputEventMouseButton.new()
	release_event.position = control.get_local_mouse_position()
	release_event.global_position = position
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.button_mask = 0
	release_event.device = -1
	
	# 发送释放事件
	if control.has_method("_input"):
		control._input(release_event)
	elif control.has_method("_gui_input"):
		control._gui_input(release_event)
	
	# 如果是按钮，触发按下信号
	if control is BaseButton:
		control.emit_signal("pressed")
		if show_debug_info:
			print("触发按钮按下信号: ", control.name)

# 公共方法
func set_active(active: bool):
	is_active = active
	visible = active
	if not active:
		_unsnap_from_node()

func get_cursor_position() -> Vector2:
	return cursor.position + cursor_size/2

func set_cursor_position(position: Vector2):
	cursor.position = position - cursor_size/2
	
	# 限制在屏幕内
	if clamp_to_screen:
		# 确保视口大小已更新
		viewport_size = get_viewport().get_visible_rect().size
		cursor.position.x = clamp(cursor.position.x, 0, viewport_size.x - cursor_size.x)
		cursor.position.y = clamp(cursor.position.y, 0, viewport_size.y - cursor_size.y)
	
	# 检查新位置是否有可吸附的节点
	if snap_enabled:
		_try_snap_to_nearest_node()

func set_cursor_color(color: Color):
	cursor.color = color

func set_cursor_size(new_size: Vector2):
	cursor_size = new_size
	cursor.size = new_size

# 吸附功能相关方法
func set_snap_enabled(enabled: bool):
	snap_enabled = enabled
	if not enabled:
		_unsnap_from_node()

func set_snap_distance(distance: float):
	snap_distance = distance

func set_snap_strength(strength: float):
	snap_strength = clamp(strength, 0.0, 1.0)

func get_current_snapped_node() -> Node:
	return current_snapped_node

func is_cursor_snapped() -> bool:
	return is_snapping

# 强制吸附到特定节点
func snap_to_node(node: Node):
	if node and is_instance_valid(node) and _is_node_valid_for_snap(node):
		_snap_to_node(node)

# 强制解除吸附
func unsnap():
	_unsnap_from_node()

# 设置吸附点子节点名称
func set_snap_point_node_name(name: String):
	snap_point_node_name = name

# 输入映射检查
func _input(event):
	# 检测输入设备变化，自动切换激活状态
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		set_active(true)
	elif event is InputEventMouse or event is InputEventKey:
		set_active(false)
