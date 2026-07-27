## 指南针和兴趣点指示器
## 显示 Boss、撤离点等兴趣点的方向和距离
extends Control

# 配置
const ARROW_SIZE: float = 16.0
const INDICATOR_MARGIN: float = 40.0
const MAX_VISIBLE_DISTANCE: float = 2000.0  # 超过此距离不显示

# 颜色
const COLOR_BOSS: Color = Color(1.0, 0.3, 0.3)
const COLOR_EXTRACT: Color = Color(0.2, 0.8, 0.8)
const COLOR_NPC: Color = Color(0.9, 0.8, 0.3)
const COLOR_RESOURCE: Color = Color(0.3, 0.8, 0.3)

# 兴趣点数据
var _poi_data: Array[Dictionary] = []
var _player: Node2D = null

# 指示器节点
var _indicators: Array[Node2D] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## 初始化
func initialize(player: Node2D) -> void:
	_player = player

## 设置兴趣点数据
func set_poi_data(data: Array[Dictionary]) -> void:
	_poi_data = data
	_clear_indicators()
	_create_indicators()

## 清除所有指示器
func _clear_indicators() -> void:
	for indicator in _indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	_indicators.clear()

## 创建指示器
func _create_indicators() -> void:
	for poi in _poi_data:
		var indicator = _create_single_indicator(poi)
		add_child(indicator)
		_indicators.append(indicator)

## 创建单个指示器
func _create_single_indicator(poi: Dictionary) -> Node2D:
	var container = Node2D.new()
	container.name = "POI_" + poi.get("type", "unknown")

	# 箭头
	var arrow = ColorRect.new()
	arrow.name = "Arrow"
	arrow.size = Vector2(ARROW_SIZE, ARROW_SIZE)
	arrow.color = poi.get("color", Color.WHITE)
	container.add_child(arrow)

	# 距离标签
	var label = Label.new()
	label.name = "Distance"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", poi.get("color", Color.WHITE))
	label.position = Vector2(ARROW_SIZE + 4, 0)
	container.add_child(label)

	# 图标标签
	var icon = Label.new()
	icon.name = "Icon"
	icon.add_theme_font_size_override("font_size", 14)
	icon.position = Vector2(-2, -18)
	container.add_child(icon)

	# 设置图标
	match poi.get("type", ""):
		"boss":
			icon.text = "👹"
			icon.add_theme_color_override("font_color", COLOR_BOSS)
		"extract":
			icon.text = "🚪"
			icon.add_theme_color_override("font_color", COLOR_EXTRACT)
		"npc":
			icon.text = "👤"
			icon.add_theme_color_override("font_color", COLOR_NPC)
		"resource":
			icon.text = "💎"
			icon.add_theme_color_override("font_color", COLOR_RESOURCE)

	return container

func _process(_delta: float) -> void:
	if not _player:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2

	for i in range(_poi_data.size()):
		if i >= _indicators.size():
			continue

		var poi = _poi_data[i]
		var indicator = _indicators[i]

		if not is_instance_valid(indicator):
			continue

		var target_pos: Vector2 = poi.get("position", Vector2.ZERO)
		var dist = _player.global_position.distance_to(target_pos)

		# 超过最大距离则隐藏
		if dist > MAX_VISIBLE_DISTANCE:
			indicator.visible = false
			continue

		# 计算方向
		var dir = (target_pos - _player.global_position).normalized()

		# 计算屏幕位置
		var screen_pos = screen_center + dir * (viewport_size.x * 0.4)

		# 限制在屏幕边缘
		var margin = INDICATOR_MARGIN
		screen_pos.x = clampf(screen_pos.x, margin, viewport_size.x - margin)
		screen_pos.y = clampf(screen_pos.y, margin, viewport_size.y - margin)

		# 检查是否在屏幕内（如果目标在屏幕内则隐藏指示器）
		var target_screen_pos = target_pos - _player.global_position + screen_center
		if target_screen_pos.x > 0 and target_screen_pos.x < viewport_size.x \
			and target_screen_pos.y > 0 and target_screen_pos.y < viewport_size.y:
			indicator.visible = false
			continue

		# 更新指示器位置
		indicator.position = screen_pos
		indicator.visible = true

		# 更新距离文本
		var label = indicator.get_node_or_null("Distance")
		if label:
			if dist < 100:
				label.text = "就在附近!"
			elif dist < 500:
				label.text = "%dm" % int(dist / 10)
			else:
				label.text = "%dm" % int(dist / 10)

		# 更新箭头旋转
		var arrow = indicator.get_node_or_null("Arrow")
		if arrow:
			arrow.rotation = dir.angle()
