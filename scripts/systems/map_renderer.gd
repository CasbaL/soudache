## 大地图渲染器
## 渲染连续大地图的地形、区域标记、装饰物
## 摄像机跟随玩家移动，只渲染可见范围
extends Node2D

# ============================================================
# 配置
# ============================================================

# 瓦片尺寸
const TILE_SIZE: int = 64

# 区域标记颜色（按类型）
var zone_colors: Dictionary = {}

# 地形基础颜色
var color_ground = Color(0.15, 0.2, 0.15)
var color_ground_alt = Color(0.12, 0.18, 0.12)

# 小地图颜色
var color_minimap_bg = Color(0.0, 0.0, 0.0, 0.7)
var color_minimap_player = Color(0.2, 0.9, 1.0)
var color_minimap_boss = Color(1.0, 0.2, 0.2)
var color_minimap_extract = Color(0.2, 0.8, 0.8)
var color_minimap_zone = Color(0.3, 0.5, 0.3, 0.6)

# ============================================================
# 节点引用
# ============================================================

@onready var terrain_container: Node2D = $TerrainContainer
@onready var zone_marker_container: Node2D = $ZoneMarkerContainer
@onready var decoration_container: Node2D = $DecorationContainer

# ============================================================
# 状态
# ============================================================

var _zones: Dictionary = {}  # { id }
var _map_size: Vector2i = Vector2i.ZERO
var _layer: int = 1
var _initialized: bool = false

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	pass

## 设置层主题颜色
func set_layer_theme(layer: int) -> void:
	_layer = layer
	var colors = _get_layer_theme_colors(layer)
	color_ground = colors.get("ground", color_ground)
	color_ground_alt = colors.get("ground_alt", color_ground_alt)

	# 设置区域颜色
	zone_colors = {
		0: Color(0.2, 0.6, 0.2, 0.3),
		1: Color(0.5, 0.3, 0.2, 0.2),
		2: Color(0.2, 0.5, 0.3, 0.2),
		3: Color(0.6, 0.2, 0.2, 0.3),
		4: Color(0.8, 0.1, 0.1, 0.4),
		5: Color(0.2, 0.6, 0.8, 0.3),
		6: Color(0.6, 0.5, 0.2, 0.2),
		7: Color(0.5, 0.1, 0.5, 0.3),
	}

## 初始化地图渲染
func initialize_map(zones: Dictionary, map_size: Vector2i) -> void:
	_zones = zones
	_map_size = map_size
	_clear_all()
	_render_terrain()
	_render_zone_markers()
	_render_decorations()
	_initialized = true

## 清空所有渲染
func _clear_all() -> void:
	if terrain_container:
		for child in terrain_container.get_children():
			child.queue_free()
	if zone_marker_container:
		for child in zone_marker_container.get_children():
			child.queue_free()
	if decoration_container:
		for child in decoration_container.get_children():
			child.queue_free()

# ============================================================
# 地形渲染
# ============================================================

func _render_terrain() -> void:
	if not terrain_container:
		return

	# 渲染地面背景
	var ground = ColorRect.new()
	ground.color = color_ground
	ground.position = Vector2.ZERO
	ground.size = Vector2(_map_size)
	terrain_container.add_child(ground)

	# 渲染网格线（辅助视觉）
	_render_grid_lines()

	# 渲染边界
	_render_border()

func _render_grid_lines() -> void:
	var grid_color = color_ground.lightened(0.03)
	grid_color.a = 0.3
	var grid_step = 200

	# 水平线
	for y in range(0, _map_size.y, grid_step):
		var line = Line2D.new()
		line.add_point(Vector2(0, y))
		line.add_point(Vector2(_map_size.x, y))
		line.default_color = grid_color
		line.width = 1.0
		terrain_container.add_child(line)

	# 垂直线
	for x in range(0, _map_size.x, grid_step):
		var line = Line2D.new()
		line.add_point(Vector2(x, 0))
		line.add_point(Vector2(x, _map_size.y))
		line.default_color = grid_color
		line.width = 1.0
		terrain_container.add_child(line)

func _render_border() -> void:
	var border_color = Color(0.4, 0.3, 0.2, 0.8)
	var border_width = 4.0

	# 上边
	var top = Line2D.new()
	top.add_point(Vector2(0, 0))
	top.add_point(Vector2(_map_size.x, 0))
	top.default_color = border_color
	top.width = border_width
	terrain_container.add_child(top)

	# 下边
	var bottom = Line2D.new()
	bottom.add_point(Vector2(0, _map_size.y))
	bottom.add_point(Vector2(_map_size.x, _map_size.y))
	bottom.default_color = border_color
	bottom.width = border_width
	terrain_container.add_child(bottom)

	# 左边
	var left = Line2D.new()
	left.add_point(Vector2(0, 0))
	left.add_point(Vector2(0, _map_size.y))
	left.default_color = border_color
	left.width = border_width
	terrain_container.add_child(left)

	# 右边
	var right = Line2D.new()
	right.add_point(Vector2(_map_size.x, 0))
	right.add_point(Vector2(_map_size.x, _map_size.y))
	right.default_color = border_color
	right.width = border_width
	terrain_container.add_child(right)

# ============================================================
# 区域标记渲染
# ============================================================

func _render_zone_markers() -> void:
	if not zone_marker_container:
		return

	for zone_id in _zones:
		var zone = _zones[zone_id]
		_render_single_zone(zone)

func _render_single_zone(zone) -> void:
	var color = zone_colors.get(zone.type, Color(0.3, 0.3, 0.3, 0.2))

	# 区域圆形标记
	var circle = _create_zone_circle(zone.center, zone.radius, color)
	zone_marker_container.add_child(circle)

	# 区域类型标记（特殊区域）
	match zone.type:
		4:
			_render_boss_marker(zone)
		5:
			_render_extract_marker(zone)
		6:
			_render_npc_marker(zone)
		0:
			_render_spawn_marker(zone)

func _create_zone_circle(center: Vector2, radius: float, color: Color) -> Node2D:
	var node = Node2D.new()
	node.position = center

	# 使用多个小矩形模拟圆形（像素风格）
	var steps = 24
	for i in range(steps):
		var angle = TAU * i / steps
		var next_angle = TAU * (i + 1) / steps
		var p1 = Vector2(cos(angle), sin(angle)) * radius
		var p2 = Vector2(cos(next_angle), sin(next_angle)) * radius

		var line = Line2D.new()
		line.add_point(p1)
		line.add_point(p2)
		line.default_color = color
		line.width = 3.0
		node.add_child(line)

	return node

func _render_boss_marker(zone) -> void:
	# Boss区域特殊标记：红色菱形
	var marker = Node2D.new()
	marker.position = zone.center

	var size = 30.0
	var points = [
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0),
	]

	var diamond = Line2D.new()
	for p in points:
		diamond.add_point(p)
	diamond.add_point(points[0])  # 闭合
	diamond.default_color = Color(1.0, 0.3, 0.3, 0.8)
	diamond.width = 3.0
	marker.add_child(diamond)

	# 中心标记
	var center_dot = ColorRect.new()
	center_dot.color = Color(1.0, 0.2, 0.2)
	center_dot.size = Vector2(8, 8)
	center_dot.position = Vector2(-4, -4)
	marker.add_child(center_dot)

	zone_marker_container.add_child(marker)

func _render_extract_marker(zone) -> void:
	# 撤离点标记：青色十字
	var marker = Node2D.new()
	marker.position = zone.center

	var size = 20.0
	# 横线
	var h_line = Line2D.new()
	h_line.add_point(Vector2(-size, 0))
	h_line.add_point(Vector2(size, 0))
	h_line.default_color = Color(0.2, 0.8, 0.8, 0.8)
	h_line.width = 3.0
	marker.add_child(h_line)

	# 竖线
	var v_line = Line2D.new()
	v_line.add_point(Vector2(0, -size))
	v_line.add_point(Vector2(0, size))
	v_line.default_color = Color(0.2, 0.8, 0.8, 0.8)
	v_line.width = 3.0
	marker.add_child(v_line)

	zone_marker_container.add_child(marker)

func _render_npc_marker(zone) -> void:
	# NPC标记：金色三角
	var marker = Node2D.new()
	marker.position = zone.center

	var size = 15.0
	var triangle = Line2D.new()
	triangle.add_point(Vector2(0, -size))
	triangle.add_point(Vector2(size, size * 0.6))
	triangle.add_point(Vector2(-size, size * 0.6))
	triangle.add_point(Vector2(0, -size))
	triangle.default_color = Color(0.8, 0.7, 0.2, 0.8)
	triangle.width = 2.0
	marker.add_child(triangle)

	zone_marker_container.add_child(marker)

func _render_spawn_marker(zone) -> void:
	# 出生点标记：绿色圆点
	var marker = Node2D.new()
	marker.position = zone.center

	var dot = ColorRect.new()
	dot.color = Color(0.2, 0.9, 0.3)
	dot.size = Vector2(12, 12)
	dot.position = Vector2(-6, -6)
	marker.add_child(dot)

	zone_marker_container.add_child(marker)

# ============================================================
# 装饰物渲染
# ============================================================

func _render_decorations() -> void:
	if not decoration_container:
		return

	# 根据层主题生成装饰物
	var decoration_count = int(_map_size.x * _map_size.y / 50000)  # 密度适中

	for i in range(decoration_count):
		var pos = Vector2(
			randf_range(50, _map_size.x - 50),
			randf_range(50, _map_size.y - 50)
		)

		# 不在区域内生成装饰物
		if _is_inside_any_zone(pos):
			continue

		var decoration = _create_decoration()
		decoration.position = pos
		decoration_container.add_child(decoration)

func _is_inside_any_zone(pos: Vector2) -> bool:
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if zone.contains_point(pos):
			return true
	return false

func _create_decoration() -> Node2D:
	var decoration = Node2D.new()

	# 根据层主题选择装饰类型
	match _layer:
		1:  # 幽竹林
			var type = randi() % 3
			match type:
				0:  # 竹子
					var trunk = ColorRect.new()
					trunk.color = Color(0.3, 0.5, 0.2)
					trunk.size = Vector2(4, 24)
					trunk.position = Vector2(-2, -24)
					decoration.add_child(trunk)
					var leaves = ColorRect.new()
					leaves.color = Color(0.2, 0.6, 0.2)
					leaves.size = Vector2(16, 16)
					leaves.position = Vector2(-8, -40)
					decoration.add_child(leaves)
				1:  # 岩石
					var rock = ColorRect.new()
					rock.color = Color(0.4, 0.45, 0.4)
					rock.size = Vector2(14, 10)
					rock.position = Vector2(-7, -10)
					decoration.add_child(rock)
				2:  # 灌木
					var bush = ColorRect.new()
					bush.color = Color(0.25, 0.5, 0.25)
					bush.size = Vector2(18, 12)
					bush.position = Vector2(-9, -12)
					decoration.add_child(bush)
		2:  # 火焰山
			var type = randi() % 2
			match type:
				0:  # 岩浆石
					var rock = ColorRect.new()
					rock.color = Color(0.5, 0.2, 0.1)
					rock.size = Vector2(12, 10)
					rock.position = Vector2(-6, -10)
					decoration.add_child(rock)
				1:  # 火焰草
					var grass = ColorRect.new()
					grass.color = Color(0.6, 0.3, 0.1)
					grass.size = Vector2(10, 8)
					grass.position = Vector2(-5, -8)
					decoration.add_child(grass)
		3:  # 天机阁
			var type = randi() % 2
			match type:
				0:  # 齿轮碎片
					var gear = ColorRect.new()
					gear.color = Color(0.5, 0.5, 0.6)
					gear.size = Vector2(10, 10)
					gear.position = Vector2(-5, -5)
					decoration.add_child(gear)
				1:  # 符文石
					var rune = ColorRect.new()
					rune.color = Color(0.4, 0.3, 0.6)
					rune.size = Vector2(8, 12)
					rune.position = Vector2(-4, -12)
					decoration.add_child(rune)

	return decoration

# ============================================================
# 层主题色彩
# ============================================================

func _get_layer_theme_colors(layer: int) -> Dictionary:
	match layer:
		1:
			return {
				"ground": Color(0.12, 0.18, 0.1),
				"ground_alt": Color(0.1, 0.16, 0.08),
			}
		2:
			return {
				"ground": Color(0.2, 0.1, 0.05),
				"ground_alt": Color(0.18, 0.08, 0.04),
			}
		3:
			return {
				"ground": Color(0.1, 0.1, 0.15),
				"ground_alt": Color(0.08, 0.08, 0.12),
			}
	return {
		"ground": Color(0.15, 0.15, 0.15),
		"ground_alt": Color(0.12, 0.12, 0.12),
	}

# ============================================================
# 公共查询
# ============================================================

func get_map_size() -> Vector2i:
	return _map_size

func is_initialized() -> bool:
	return _initialized
