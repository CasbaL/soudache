## 开放世界关卡
## 使用单一大地图，分散敌人、资源、NPC
extends Node2D

# ============================================================
# 场景引用
# ============================================================

@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var open_world_map: Node2D = $OpenWorldMap

# ============================================================
# 预加载脚本
# ============================================================

var _OpenWorldMapScript = preload("res://scripts/systems/open_world_map.gd")

# ============================================================
# 方向指示器
# ============================================================

var _extract_indicator: Control = null
var _extract_arrow: ColorRect = null
var _extract_label: Label = null

# 屏幕边距
const INDICATOR_MARGIN: float = 60.0

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print("[OpenWorldLevel] _ready 开始")
	
	# 初始化游戏
	GameManager.start_new_game()
	
	# 初始化地图
	_init_map()
	
	# 连接信号
	_connect_signals()
	
	# 初始化HUD
	if hud and player:
		hud.initialize(player)
	
	# 创建撤离点指示器
	_create_extract_indicator()
	
	# 放置玩家到出生点
	_place_player_at_spawn()
	
	print("[OpenWorldLevel] _ready 完成")

## 初始化地图
func _init_map() -> void:
	if open_world_map:
		print("[OpenWorldLevel] 地图初始化完成")

## 连接信号
func _connect_signals() -> void:
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

## 放置玩家到出生点
func _place_player_at_spawn() -> void:
	if player and open_world_map:
		# 出生点在左上角
		player.position = Vector2(300, 300)
		print("[OpenWorldLevel] 玩家放置到出生点: %s" % str(player.position))

## 创建撤离点方向指示器
func _create_extract_indicator() -> void:
	# 创建指示器容器
	_extract_indicator = Control.new()
	_extract_indicator.name = "ExtractIndicator"
	_extract_indicator.z_index = 100
	_extract_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_extract_indicator)
	
	# 创建箭头
	_extract_arrow = ColorRect.new()
	_extract_arrow.name = "Arrow"
	_extract_arrow.size = Vector2(20, 20)
	_extract_arrow.color = Color(0.2, 0.8, 0.8, 0.8)  # 青色
	_extract_indicator.add_child(_extract_arrow)
	
	# 创建距离标签
	_extract_label = Label.new()
	_extract_label.name = "DistanceLabel"
	_extract_label.text = "撤离点"
	_extract_label.add_theme_font_size_override("font_size", 12)
	_extract_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.8))
	_extract_indicator.add_child(_extract_label)
	
	print("[OpenWorldLevel] 撤离点指示器创建完成")

# ============================================================
# 信号回调
# ============================================================

func _on_player_health_changed(new_health: int) -> void:
	if hud and player:
		hud.update_health(new_health, player.max_health)

# ============================================================
# 物理更新
# ============================================================

func _physics_process(_delta: float) -> void:
	# 限制玩家在地图范围内
	if player and open_world_map:
		var map_size = open_world_map.get_map_size()
		player.position = player.position.clamp(Vector2.ZERO, map_size)
	
	# 更新撤离点指示器
	_update_extract_indicator()

## 更新撤离点方向指示器
func _update_extract_indicator() -> void:
	if not player or not open_world_map or not _extract_indicator:
		return
	
	# 获取最近的撤离点
	var extract_points = open_world_map.get_extract_points()
	if extract_points.is_empty():
		_extract_indicator.visible = false
		return
	
	# 找到最近的撤离点
	var nearest_extract = extract_points[0]
	var nearest_dist = player.position.distance_to(extract_points[0])
	for point in extract_points:
		var dist = player.position.distance_to(point)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_extract = point
	
	# 计算屏幕位置
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2
	
	# 检查撤离点是否在屏幕内
	var camera_pos = camera.global_position if camera else player.position
	var extract_screen_pos = nearest_extract - camera_pos + screen_center
	
	var is_on_screen = (
		extract_screen_pos.x > 0 and
		extract_screen_pos.x < viewport_size.x and
		extract_screen_pos.y > 0 and
		extract_screen_pos.y < viewport_size.y
	)
	
	if is_on_screen:
		# 在屏幕内，隐藏指示器
		_extract_indicator.visible = false
		return
	
	# 在屏幕外，显示指示器
	_extract_indicator.visible = true
	
	# 计算方向
	var direction = (nearest_extract - player.position).normalized()
	
	# 计算箭头位置（屏幕边缘）
	var arrow_pos = Vector2.ZERO
	arrow_pos.x = clamp(screen_center.x + direction.x * (screen_center.x - INDICATOR_MARGIN), INDICATOR_MARGIN, viewport_size.x - INDICATOR_MARGIN)
	arrow_pos.y = clamp(screen_center.y + direction.y * (screen_center.y - INDICATOR_MARGIN), INDICATOR_MARGIN, viewport_size.y - INDICATOR_MARGIN)
	
	# 设置箭头位置
	_extract_arrow.position = arrow_pos - Vector2(10, 10)
	
	# 设置箭头旋转
	_extract_arrow.rotation = direction.angle()
	
	# 设置标签位置
	_extract_label.position = arrow_pos + Vector2(15, -8)
	
	# 更新距离文本
	var dist_text = _format_distance(nearest_dist)
	_extract_label.text = "撤离 %s" % dist_text

## 格式化距离
func _format_distance(distance: float) -> String:
	if distance < 100:
		return "%dm" % int(distance)
	elif distance < 1000:
		var rounded = int(distance / 10) * 10
		return "%dm" % rounded
	else:
		return "%.1fkm" % (distance / 1000)
