## 地图渲染器
## 使用 ColorRect 和 Line2D 绘制房间、走廊、门标记
## 每个房间区域 = 720x1280 像素（与 viewport 一致）
extends Node2D

# ============================================================
# 配置
# ============================================================

# 房间尺寸（与 RoomData 一致）
const ROOM_WIDTH: int = 720
const ROOM_HEIGHT: int = 1280

# 墙壁厚度
const WALL_THICKNESS: int = 12

# 地板边距（距墙壁内侧）
const FLOOR_MARGIN: int = 48

# 门的宽度
const DOOR_WIDTH: int = 80
const DOOR_DEPTH: int = 20

# 颜色配置（会按层主题覆盖）
var color_floor = Color(0.15, 0.2, 0.15)
var color_wall = Color(0.35, 0.4, 0.35)
var color_wall_top = Color(0.45, 0.5, 0.45)
var color_door = Color(0.6, 0.5, 0.3)
var color_door_frame = Color(0.8, 0.7, 0.4)
var color_bg = Color(0.08, 0.1, 0.08)

# 小地图颜色
var color_room_explored = Color(0.3, 0.5, 0.3, 0.9)
var color_room_revealed = Color(0.3, 0.5, 0.3, 0.35)
var color_room_fogged = Color(0.15, 0.15, 0.15, 0.2)
var color_corridor = Color(0.25, 0.35, 0.25, 0.7)
var color_current_room = Color(0.2, 0.8, 0.4, 1.0)
var color_player_dot = Color(0.2, 0.9, 1.0)

# ============================================================
# 节点引用
# ============================================================

@onready var room_container: Node2D = $RoomContainer
@onready var corridor_container: Node2D = $CorridorContainer
@onready var door_container: Node2D = $DoorContainer
@onready var minimap_container: Control = $MinimapContainer

# ============================================================
# 状态
# ============================================================

var _rooms: Dictionary = {}  # { id: RoomData }
var _current_room_id: String = ""
var _rendered_room_nodes: Dictionary = {}  # { id: Node2D }

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	pass

## 设置层主题颜色
func set_layer_theme(layer: int) -> void:
	var colors = RoomTemplates.get_layer_theme_colors(layer)
	color_floor = colors.get("floor", color_floor)
	color_wall = colors.get("wall", color_wall)
	color_wall_top = color_wall.lightened(0.15)
	color_bg = colors.get("bg", color_bg)
	color_room_explored = colors.get("accent", color_room_explored).darkened(0.3)
	color_corridor = color_room_explored.darkened(0.2)

## 初始化地图渲染
func initialize_map(rooms: Dictionary) -> void:
	_rooms = rooms
	_clear_all()

## 清空所有渲染
func _clear_all() -> void:
	if room_container:
		for child in room_container.get_children():
			child.queue_free()
	if corridor_container:
		for child in corridor_container.get_children():
			child.queue_free()
	if door_container:
		for child in door_container.get_children():
			child.queue_free()
	_rendered_room_nodes.clear()

# ============================================================
# 房间渲染（全量）
# ============================================================

## 渲染单个房间（完整视图）
func render_room(room_id: String) -> void:
	if room_id not in _rooms:
		return

	_current_room_id = room_id
	var room: RoomData = _rooms[room_id]

	# 清空当前渲染
	if room_container:
		for child in room_container.get_children():
			child.queue_free()
	if door_container:
		for child in door_container.get_children():
			child.queue_free()

	# 背景
	_draw_background()

	# 地板
	_draw_floor(room)

	# 墙壁
	_draw_walls(room)

	# 门
	_draw_doors(room)

	# 房间类型标记
	_draw_room_type_marker(room)

## 绘制背景
func _draw_background() -> void:
	var bg = ColorRect.new()
	bg.color = color_bg
	bg.size = Vector2(ROOM_WIDTH, ROOM_HEIGHT)
	bg.position = Vector2.ZERO
	room_container.add_child(bg)

## 绘制地板
func _draw_floor(_room: RoomData) -> void:
	var floor_rect = ColorRect.new()
	floor_rect.color = color_floor
	floor_rect.position = Vector2(FLOOR_MARGIN, FLOOR_MARGIN)
	floor_rect.size = Vector2(
		ROOM_WIDTH - FLOOR_MARGIN * 2,
		ROOM_HEIGHT - FLOOR_MARGIN * 2
	)
	room_container.add_child(floor_rect)

	# 地板装饰线（格子纹理）
	var grid_color = color_floor.lightened(0.05)
	var grid_step = 60
	var floor_start = Vector2(FLOOR_MARGIN, FLOOR_MARGIN)
	var floor_end = Vector2(ROOM_WIDTH - FLOOR_MARGIN, ROOM_HEIGHT - FLOOR_MARGIN)

	# 水平线
	var y = floor_start.y
	while y < floor_end.y:
		var line = Line2D.new()
		line.add_point(Vector2(floor_start.x, y))
		line.add_point(Vector2(floor_end.x, y))
		line.default_color = grid_color
		line.width = 1.0
		room_container.add_child(line)
		y += grid_step

	# 垂直线
	var x = floor_start.x
	while x < floor_end.x:
		var line = Line2D.new()
		line.add_point(Vector2(x, floor_start.y))
		line.add_point(Vector2(x, floor_end.y))
		line.default_color = grid_color
		line.width = 1.0
		room_container.add_child(line)
		x += grid_step

## 绘制墙壁
func _draw_walls(_room: RoomData) -> void:
	var wall_positions = [
		# 上墙
		Rect2(0, 0, ROOM_WIDTH, WALL_THICKNESS),
		# 下墙
		Rect2(0, ROOM_HEIGHT - WALL_THICKNESS, ROOM_WIDTH, WALL_THICKNESS),
		# 左墙
		Rect2(0, 0, WALL_THICKNESS, ROOM_HEIGHT),
		# 右墙
		Rect2(ROOM_WIDTH - WALL_THICKNESS, 0, WALL_THICKNESS, ROOM_HEIGHT),
	]

	for wp in wall_positions:
		var wall = ColorRect.new()
		wall.color = color_wall
		wall.position = wp.position
		wall.size = wp.size
		room_container.add_child(wall)

	# 墙顶高光
	var top_highlight = ColorRect.new()
	top_highlight.color = color_wall_top
	top_highlight.position = Vector2(0, 0)
	top_highlight.size = Vector2(ROOM_WIDTH, 4)
	room_container.add_child(top_highlight)

	var left_highlight = ColorRect.new()
	left_highlight.color = color_wall_top
	left_highlight.position = Vector2(0, 0)
	left_highlight.size = Vector2(4, ROOM_HEIGHT)
	room_container.add_child(left_highlight)

## 绘制门
func _draw_doors(room: RoomData) -> void:
	for conn_id in room.connections:
		if conn_id not in _rooms:
			continue
		var other: RoomData = _rooms[conn_id]
		var dir = room.get_direction_to(other)
		_draw_door(dir)

## 绘制单个门
func _draw_door(direction: String) -> void:
	var door_center: Vector2
	var door_size: Vector2

	match direction:
		"north":
			door_center = Vector2(ROOM_WIDTH / 2.0, WALL_THICKNESS / 2.0)
			door_size = Vector2(DOOR_WIDTH, WALL_THICKNESS + DOOR_DEPTH)
		"south":
			door_center = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - WALL_THICKNESS / 2.0)
			door_size = Vector2(DOOR_WIDTH, WALL_THICKNESS + DOOR_DEPTH)
		"east":
			door_center = Vector2(ROOM_WIDTH - WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)
			door_size = Vector2(WALL_THICKNESS + DOOR_DEPTH, DOOR_WIDTH)
		"west":
			door_center = Vector2(WALL_THICKNESS / 2.0, ROOM_HEIGHT / 2.0)
			door_size = Vector2(WALL_THICKNESS + DOOR_DEPTH, DOOR_WIDTH)

	# 门框
	var frame = ColorRect.new()
	frame.color = color_door_frame
	frame.position = door_center - door_size / 2
	frame.size = door_size
	door_container.add_child(frame)

	# 门洞（深色）
	var opening = ColorRect.new()
	opening.color = color_bg.darkened(0.3)
	opening.position = door_center - door_size / 2 + Vector2(3, 3)
	opening.size = door_size - Vector2(6, 6)
	door_container.add_child(opening)

	# 发光指示
	var glow = ColorRect.new()
	glow.color = color_door.lightened(0.3)
	glow.position = door_center - Vector2(4, 4)
	glow.size = Vector2(8, 8)
	door_container.add_child(glow)

## 绘制房间类型标记
func _draw_room_type_marker(room: RoomData) -> void:
	var center = Vector2(ROOM_WIDTH / 2, ROOM_HEIGHT / 2)

	# Boss房间特殊背景
	if room.type == RoomData.RoomType.BOSS:
		var boss_bg = ColorRect.new()
		boss_bg.color = Color(0.3, 0.05, 0.05, 0.3)
		boss_bg.position = Vector2(FLOOR_MARGIN, FLOOR_MARGIN)
		boss_bg.size = Vector2(ROOM_WIDTH - FLOOR_MARGIN * 2, ROOM_HEIGHT - FLOOR_MARGIN * 2)
		room_container.add_child(boss_bg)

	# 撤离点标记
	if room.has_extraction_point:
		var extract_marker = ColorRect.new()
		extract_marker.color = Color(0.2, 0.8, 0.2, 0.5)
		extract_marker.position = center - Vector2(30, 30)
		extract_marker.size = Vector2(60, 60)
		door_container.add_child(extract_marker)

		# 十字标记
		var h_line = ColorRect.new()
		h_line.color = Color(0.1, 0.5, 0.1)
		h_line.position = center - Vector2(20, 3)
		h_line.size = Vector2(40, 6)
		door_container.add_child(h_line)

		var v_line = ColorRect.new()
		v_line.color = Color(0.1, 0.5, 0.1)
		v_line.position = center - Vector2(3, 20)
		v_line.size = Vector2(6, 40)
		door_container.add_child(v_line)

# ============================================================
# 小地图渲染
# ============================================================

## 绘制小地图（房间网络图）
## fog_states: { room_id: "explored"/"revealed"/"fogged" }
func render_minimap(current_room_id: String, fog_states: Dictionary) -> void:
	if not minimap_container:
		return

	# 清空旧小地图
	for child in minimap_container.get_children():
		child.queue_free()

	if _rooms.is_empty():
		return

	# 计算网格边界
	var min_pos = Vector2i(999, 999)
	var max_pos = Vector2i(-999, -999)
	for room_id in _rooms:
		var room: RoomData = _rooms[room_id]
		if room.grid_pos.x < min_pos.x:
			min_pos.x = room.grid_pos.x
		if room.grid_pos.y < min_pos.y:
			min_pos.y = room.grid_pos.y
		if room.grid_pos.x > max_pos.x:
			max_pos.x = room.grid_pos.x
		if room.grid_pos.y > max_pos.y:
			max_pos.y = room.grid_pos.y

	# 小地图参数
	var minimap_size = Vector2(160, 200)
	var grid_cells = max_pos - min_pos + Vector2i(1, 1)
	var cell_size = Vector2(
		minimap_size.x / (grid_cells.x + 1),
		minimap_size.y / (grid_cells.y + 1)
	)
	var cell_draw_size = cell_size * 0.7
	var offset = Vector2(10, 10)

	# 小地图背景
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.size = minimap_size
	bg.position = Vector2.ZERO
	minimap_container.add_child(bg)

	# 先画走廊连接线
	for room_id in _rooms:
		var room: RoomData = _rooms[room_id]
		var state = fog_states.get(room_id, "fogged")
		if state == "fogged":
			continue

		var room_screen_pos = _minimap_cell_pos(room.grid_pos, min_pos, cell_size, offset)

		for conn_id in room.connections:
			if conn_id <= room_id:
				continue  # 避免重复绘制
			var conn_state = fog_states.get(conn_id, "fogged")
			if conn_state == "fogged":
				continue
			if conn_id not in _rooms:
				continue
			var conn_room: RoomData = _rooms[conn_id]
			var conn_screen_pos = _minimap_cell_pos(conn_room.grid_pos, min_pos, cell_size, offset)

			var line = Line2D.new()
			line.add_point(room_screen_pos)
			line.add_point(conn_screen_pos)
			line.default_color = color_corridor
			line.width = 2.0
			minimap_container.add_child(line)

	# 再画房间方块
	for room_id in _rooms:
		var room: RoomData = _rooms[room_id]
		var state = fog_states.get(room_id, "fogged")

		if state == "fogged":
			continue

		var screen_pos = _minimap_cell_pos(room.grid_pos, min_pos, cell_size, offset)
		var rect_color: Color

		if room_id == current_room_id:
			rect_color = color_current_room
		elif state == "explored":
			rect_color = color_room_explored
		else:
			rect_color = color_room_revealed

		var rect = ColorRect.new()
		rect.color = rect_color
		rect.position = screen_pos - cell_draw_size / 2
		rect.size = cell_draw_size
		minimap_container.add_child(rect)

		# 当前房间额外标记
		if room_id == current_room_id:
			var marker = ColorRect.new()
			marker.color = color_player_dot
			marker.position = screen_pos - Vector2(3, 3)
			marker.size = Vector2(6, 6)
			minimap_container.add_child(marker)

## 计算小地图上房间的位置
func _minimap_cell_pos(grid_pos: Vector2i, min_pos: Vector2i, cell_size: Vector2, offset: Vector2) -> Vector2:
	var rel = Vector2(grid_pos - min_pos)
	return offset + rel * cell_size + cell_size / 2

# ============================================================
# 公共查询
# ============================================================

func get_current_room_id() -> String:
	return _current_room_id

func get_room(room_id: String) -> RoomData:
	return _rooms.get(room_id, null)
