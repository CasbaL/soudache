## 小地图（大地图版本）
## 显示整个大地图缩略图，标记玩家、Boss、撤离点、区域
extends Control

# 配置
@export var map_size: Vector2 = Vector2(160, 160)

# 世界大小（会在initialize时更新）
var world_size: Vector2 = Vector2(3000, 3000)

# 绘制颜色
const BG_COLOR = Color(0.1, 0.1, 0.1, 0.8)
const BORDER_COLOR = Color(0.5, 0.45, 0.4)
const PLAYER_COLOR = Color(0.2, 0.8, 1.0)   # 青色
const BOSS_COLOR = Color(1.0, 0.2, 0.2)      # 红色
const EXTRACT_COLOR = Color(0.2, 0.8, 0.8)   # 青色
const ZONE_COLOR = Color(0.3, 0.5, 0.3, 0.6) # 绿色
const NPC_COLOR = Color(0.8, 0.7, 0.2)       # 金色

# 区域类型枚举值（与MapZone.ZoneType对应）
const ZONE_TYPE_SPAWN = 0
const ZONE_TYPE_COMBAT = 1
const ZONE_TYPE_RESOURCE = 2
const ZONE_TYPE_ELITE = 3
const ZONE_TYPE_BOSS = 4
const ZONE_TYPE_EXTRACT = 5
const ZONE_TYPE_NPC = 6
const ZONE_TYPE_HAZARD = 7

# 区域颜色（按类型）
var zone_type_colors: Dictionary = {}

# 缩放比例
var _scale: Vector2

# 数据
var _zones: Dictionary = {}
var _boss_position: Vector2 = Vector2.ZERO
var _extract_positions: Array[Vector2] = []
var _initialized: bool = false

func _ready() -> void:
	custom_minimum_size = map_size
	size = map_size

	# 设置区域颜色
	zone_type_colors = {
		ZONE_TYPE_SPAWN: Color(0.2, 0.6, 0.2, 0.5),
		ZONE_TYPE_COMBAT: Color(0.5, 0.3, 0.2, 0.4),
		ZONE_TYPE_RESOURCE: Color(0.2, 0.5, 0.3, 0.4),
		ZONE_TYPE_ELITE: Color(0.6, 0.2, 0.2, 0.5),
		ZONE_TYPE_BOSS: Color(0.8, 0.1, 0.1, 0.6),
		ZONE_TYPE_EXTRACT: Color(0.2, 0.6, 0.8, 0.5),
		ZONE_TYPE_NPC: Color(0.6, 0.5, 0.2, 0.4),
		ZONE_TYPE_HAZARD: Color(0.5, 0.1, 0.5, 0.4),
	}

## 初始化小地图
func initialize(zones: Dictionary, map_size_world: Vector2i, boss_pos: Vector2, extract_pos: Array) -> void:
	_zones = zones
	world_size = Vector2(map_size_world)
	_boss_position = boss_pos
	_extract_positions.assign(extract_pos)
	_scale = map_size / world_size
	_initialized = true
	queue_redraw()

func _draw() -> void:
	if not _initialized:
		return

	# 背景
	draw_rect(Rect2(Vector2.ZERO, map_size), BG_COLOR)

	# 边框
	draw_rect(Rect2(Vector2.ZERO, map_size), BORDER_COLOR, false, 2.0)

	# 绘制区域
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if not zone.has_method("get"):
			continue
		var center: Vector2 = zone.get("center")
		var radius: float = zone.get("radius")
		var zone_type: int = zone.get("type")

		var screen_pos = center * _scale
		var screen_radius = radius * _scale.x

		var color = zone_type_colors.get(zone_type, ZONE_COLOR)
		draw_circle(screen_pos, screen_radius, color)

	# 绘制撤离点
	for extract_pos in _extract_positions:
		var screen_pos = extract_pos * _scale
		draw_circle(screen_pos, 4.0, EXTRACT_COLOR)

	# 绘制Boss位置
	if _boss_position != Vector2.ZERO:
		var screen_pos = _boss_position * _scale
		draw_circle(screen_pos, 5.0, BOSS_COLOR)
		draw_arc(screen_pos, 7.0, 0, TAU, 8, BOSS_COLOR, 1.5)

	# 绘制玩家（最后绘制，确保在最上层）
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var screen_pos = player.global_position * _scale

		# 限制在小地图范围内
		screen_pos.x = clampf(screen_pos.x, 5, map_size.x - 5)
		screen_pos.y = clampf(screen_pos.y, 5, map_size.y - 5)

		draw_circle(screen_pos, 4.0, PLAYER_COLOR)
		draw_arc(screen_pos, 6.0, 0, TAU, 12, Color.WHITE, 1.0)

func _process(_delta: float) -> void:
	# 每帧重绘（追踪玩家位置）
	queue_redraw()
