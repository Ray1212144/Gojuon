# FogOfWar.gd
extends CanvasLayer

# 配置参数
@export var view_radius: float = 300.0
@export var walls_collision_mask: int = 2
@export var ray_count: int = 120
@export var update_frequency: int = 2

# 内部变量
var player_position: Vector2
var player_camera: Camera2D
var update_counter: int = 0
var fog_overlay: ColorRect
var debug_polygon: Polygon2D

func _ready():
	# 创建战争迷雾覆盖层
	create_fog_overlay()
	
	# 监听视口大小变化
	get_viewport().connect("size_changed", _on_viewport_size_changed)

func _on_viewport_size_changed():
	# 当视口大小改变时，更新覆盖层大小
	if fog_overlay:
		var viewport_size = get_viewport().get_visible_rect().size
		fog_overlay.size = viewport_size
		
		# 更新着色器参数
		if fog_overlay.material:
			fog_overlay.material.set_shader_parameter("viewport_size", viewport_size)

func create_fog_overlay():
	# 创建ColorRect作为战争迷雾覆盖层
	fog_overlay = ColorRect.new()
	fog_overlay.name = "FogOverlay"
	fog_overlay.anchor_right = 1.0
	fog_overlay.anchor_bottom = 1.0
	fog_overlay.offset_right = 0.0
	fog_overlay.offset_bottom = 0.0
	
	# 获取视口大小
	var viewport_size = get_viewport().get_visible_rect().size
	fog_overlay.size = viewport_size
	
	# 创建着色器材质
	var material = ShaderMaterial.new()
	
	# 修复后的着色器代码 - 不再使用VIEWPORT_SIZE
	var shader_code = """
	shader_type canvas_item;

	uniform vec2 player_screen_pos;
	uniform float view_radius = 300.0;
	uniform vec2 viewport_size;

	void fragment() {
		// 将UV坐标转换为屏幕像素坐标
		vec2 screen_pos = UV * viewport_size;
		
		// 计算当前像素到玩家的距离
		float dist = distance(screen_pos, player_screen_pos);
		
		// 如果距离在视野范围内，显示透明；否则显示黑色
		if (dist < view_radius) {
			COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		} else {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		}
	}
	"""
	
	var shader = Shader.new()
	shader.code = shader_code
	material.shader = shader
	
	# 设置初始参数值
	material.set_shader_parameter("viewport_size", viewport_size)
	material.set_shader_parameter("view_radius", view_radius)
	material.set_shader_parameter("player_screen_pos", Vector2(viewport_size.x/2, viewport_size.y/2))
	
	fog_overlay.material = material
	fog_overlay.color = Color(0, 0, 0, 1)  # 黑色背景
	
	# 添加到CanvasLayer
	add_child(fog_overlay)
	
	# 创建调试多边形（可选）
	debug_polygon = Polygon2D.new()
	debug_polygon.name = "DebugPolygon"
	debug_polygon.color = Color(1, 0, 0, 0.3)  # 半透明红色
	add_child(debug_polygon)

func _process(delta):
	# 控制更新频率
	update_counter += 1
	if update_counter >= update_frequency:
		update_counter = 0
		update_visible_area()

func set_player_camera(camera: Camera2D):
	player_camera = camera

func update_player_position(pos: Vector2):
	player_position = pos

func update_visible_area():
	if player_position == Vector2.ZERO or player_camera == null:
		return
	
	# 计算玩家在屏幕上的位置
	var viewport_size = get_viewport().get_visible_rect().size
	
	# 关键修复：正确计算玩家在屏幕上的位置
	# 使用相机将世界坐标转换为屏幕坐标
	var player_screen_pos = player_camera.to_global(player_position)
	player_screen_pos = player_screen_pos - player_camera.global_position + viewport_size/2
	
	# 更新着色器参数
	if fog_overlay and fog_overlay.material:
		fog_overlay.material.set_shader_parameter("player_screen_pos", player_screen_pos)
	
	# 计算墙壁遮挡（可选）
	calculate_wall_occlusion()

func calculate_wall_occlusion():
	# 获取物理空间状态
	var space_state = get_world_2d().direct_space_state
	
	# 创建可见区域的多边形顶点数组
	var visible_polygon = PackedVector2Array()
	
	# 计算玩家在屏幕上的位置（用于调试多边形）
	var viewport_size = get_viewport().get_visible_rect().size
	var player_screen_pos = player_camera.to_global(player_position)
	player_screen_pos = player_screen_pos - player_camera.global_position + viewport_size/2
	
	visible_polygon.append(player_screen_pos)  # 多边形的起点是玩家位置
	
	# 向各个方向发射射线检测墙壁
	for i in range(ray_count):
		var angle = i * 2 * PI / ray_count
		var direction = Vector2(cos(angle), sin(angle))
		
		# 创建射线查询
		var query = PhysicsRayQueryParameters2D.create(
			player_position, 
			player_position + direction * view_radius,
			walls_collision_mask
		)
		
		# 执行射线检测
		var result = space_state.intersect_ray(query)
		
		# 确定射线的终点
		var end_point: Vector2
		if result:
			end_point = result.position  # 如果碰到墙壁，终点是碰撞点
		else:
			end_point = player_position + direction * view_radius
		
		# 将世界坐标转换为屏幕坐标
		var end_screen_pos = player_camera.to_global(end_point)
		end_screen_pos = end_screen_pos - player_camera.global_position + viewport_size/2
		
		visible_polygon.append(end_screen_pos)
	
	# 闭合多边形
	if visible_polygon.size() > 1:
		visible_polygon.append(visible_polygon[1])
	
	# 更新调试多边形
	debug_polygon.polygon = visible_polygon
