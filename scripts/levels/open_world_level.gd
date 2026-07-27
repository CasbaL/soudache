## 开放世界关卡
## 使用房间制地图，通过门触发房间过渡
extends Node2D

# ============================================================
# 场景引用
# ============================================================

@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var map_renderer: Node2D = $MapRenderer

# ============================================================
# 预加载脚本
# ============================================================

var _MapGeneratorScript = preload("res://scripts/systems/map_generator.gd")

# ============================================================
# 地图状态
# ============================================================

var _map_generator = null
var _map_data: Dictionary = {}
var _rooms: Dictionary = {}  # { id: RoomData }
var _current_room_id: String = ""
var _door_triggers: Array[Area2D] = []
var _is_transitioning: bool = false

# ============================================================
# 方向指示器
# ============================================================

var _extract_indicator: Control = null
var _extract_arrow: ColorRect = null
var _extract_label: Label = null
const INDICATOR_MARGIN: float = 60.0

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print("[OpenWorldLevel] _ready 开始")

	# 初始化游戏
	GameManager.start_new_game()

	# 生成地图
	_generate_map()

	# 连接信号
	_connect_signals()

	# 初始化HUD
	if hud and player:
		hud.initialize(player)

	# 创建撤离点方向指示器
	_create_extract_indicator()

	print("[OpenWorldLevel] _ready 完成")

## 生成地图并渲染第一个房间
func _generate_map() -> void:
	_map_generator = _MapGeneratorScript.new()
	var layer = GameManager.current_layer
	_map_data = _map_generator.generate_layer(layer)
	_rooms = _map_data.rooms

	print("[OpenWorldLevel] 地图生成完成: %d 个房间" % _rooms.size())

	# 初始化迷雾系统
	FogSystem.initialize(_rooms, _map_data.start_room_id)

	# 初始化渲染器
	if map_renderer:
		map_renderer.set_layer_theme(layer)
		map_renderer.initialize_map(_rooms)

	# 进入起始房间
	_enter_room(_map_data.start_room_id, "")

## 连接信号
func _connect_signals() -> void:
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)

# ============================================================
# 房间过渡
# ============================================================

## 进入新房间
func _enter_room(room_id: String, from_direction: String) -> void:
	if room_id not in _rooms:
		push_error("房间不存在: %s" % room_id)
		return

	_is_transitioning = true
	_current_room_id = room_id
	var room: RoomData = _rooms[room_id]

	print("[OpenWorldLevel] 进入房间: %s (%s)" % [room_id, room.get_type_name()])

	# 更新迷雾
	FogSystem.enter_room(room_id)

	# 渲染房间
	if map_renderer:
		map_renderer.render_room(room_id)
		var fog_states = FogSystem.get_all_fog_states()
		map_renderer.render_minimap(room_id, fog_states)

	# 创建门触发器
	_create_door_triggers(room)

	# 生成房间内的敌人和资源
	_spawn_room_content(room)

	# 设置玩家位置
	if from_direction != "":
		player.position = RoomTransitionController.get_entry_position(from_direction)
	else:
		# 起始房间，玩家在中央
		player.position = Vector2(RoomData.ROOM_WIDTH / 2.0, RoomData.ROOM_HEIGHT / 2.0)

	# 重置摄像机
	if camera:
		camera.reset_smoothing()

	_is_transitioning = false

## 创建门触发器
func _create_door_triggers(room: RoomData) -> void:
	# 清除旧触发器
	for trigger in _door_triggers:
		if is_instance_valid(trigger):
			trigger.queue_free()
	_door_triggers.clear()

	# 为每个连接创建触发器
	for conn_id in room.connections:
		if conn_id not in _rooms:
			continue
		var other: RoomData = _rooms[conn_id]
		var direction = room.get_direction_to(other)
		_create_single_door_trigger(direction, conn_id)

## 创建单个门触发器
func _create_single_door_trigger(direction: String, target_room_id: String) -> void:
	var trigger = Area2D.new()
	trigger.name = "DoorTrigger_%s" % direction

	# 设置碰撞层（检测玩家）
	trigger.collision_layer = 0
	trigger.collision_mask = 1

	# 设置位置
	var rect = RoomTransitionController.get_door_trigger_rect(direction)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.position + rect.size / 2
	trigger.add_child(collision)

	# 连接信号
	trigger.body_entered.connect(_on_door_entered.bind(direction, target_room_id))

	add_child(trigger)
	_door_triggers.append(trigger)

## 玩家进入门触发器
func _on_door_entered(body: Node2D, direction: String, target_room_id: String) -> void:
	if _is_transitioning:
		return
	if not body is Player:
		return

	print("[OpenWorldLevel] 玩家进入门: %s -> %s" % [direction, target_room_id])

	# 淡出过渡
	_is_transitioning = true
	await SceneTransition._fade_out(0.2)

	# 进入新房间
	var entry_dir = RoomTransitionController.opposite_direction(direction)
	_enter_room(target_room_id, entry_dir)

	# 淡入
	await SceneTransition._fade_in(0.2)

# ============================================================
# 房间内容生成
# ============================================================

## 生成房间内的敌人和资源
func _spawn_room_content(room: RoomData) -> void:
	# 清除当前场景中的敌人
	_clear_enemies()

	# 如果房间已清除，不再生成
	if room.is_cleared:
		return

	# 生成敌人
	for enemy_config in room.enemies:
		var enemy_id = enemy_config.get("enemy_id", "")
		var count = enemy_config.get("count", 1)
		for i in range(count):
			var spawn_pos = _get_random_room_position()
			EnemySpawner.spawn_enemy(enemy_id, spawn_pos)

	# 生成资源
	for res_config in room.resources:
		var amount = res_config.get("amount", 1)
		for i in range(amount):
			var spawn_pos = _get_random_room_position()
			_create_resource_pickup(res_config, spawn_pos)

	# 如果是撤离点，生成撤离点实体
	if room.has_extraction_point:
		var center = Vector2(RoomData.ROOM_WIDTH / 2.0, RoomData.ROOM_HEIGHT / 2.0)
		_create_extraction_entity(center)

## 清除场景中的敌人
func _clear_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()

## 获取房间内的随机位置
func _get_random_room_position() -> Vector2:
	var margin = 80.0
	return Vector2(
		randf_range(margin, RoomData.ROOM_WIDTH - margin),
		randf_range(margin, RoomData.ROOM_HEIGHT - margin)
	)

## 创建资源拾取物
func _create_resource_pickup(res_config: Dictionary, pos: Vector2) -> void:
	var resource = Area2D.new()
	resource.position = pos
	resource.collision_layer = 4
	resource.collision_mask = 1

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	var res_id = res_config.get("resource_id", "")
	match res_id:
		"spirit_stone":
			sprite.color = Color(0.3, 0.6, 1.0)
		"herb":
			sprite.color = Color(0.2, 0.8, 0.2)
		"ore":
			sprite.color = Color(0.6, 0.4, 0.2)
		_:
			sprite.color = Color(0.5, 0.5, 0.5)
	resource.add_child(sprite)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	resource.add_child(collision)

	resource.set_meta("resource_id", res_id)
	resource.set_meta("resource_name", res_config.get("name", ""))
	resource.set_meta("amount", res_config.get("amount", 1))

	resource.body_entered.connect(_on_resource_collected.bind(resource))
	add_child(resource)

## 资源被收集
func _on_resource_collected(body: Node2D, resource: Node2D) -> void:
	if not body is Player:
		return
	var item = {
		"id": resource.get_meta("resource_id", ""),
		"name": resource.get_meta("resource_name", ""),
		"amount": resource.get_meta("amount", 1),
	}
	if GameManager.add_to_inventory(item):
		resource.queue_free()

## 创建撤离点实体
func _create_extraction_entity(pos: Vector2) -> void:
	var extract = Area2D.new()
	extract.position = pos
	extract.collision_layer = 8
	extract.collision_mask = 1

	var sprite = ColorRect.new()
	sprite.size = Vector2(40, 40)
	sprite.position = Vector2(-20, -40)
	sprite.color = Color(0.2, 0.8, 0.8)
	extract.add_child(sprite)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	collision.shape = shape
	extract.add_child(collision)

	var label = Label.new()
	label.text = "撤离点"
	label.position = Vector2(-20, -60)
	label.add_theme_font_size_override("font_size", 14)
	extract.add_child(label)

	extract.body_entered.connect(_on_extract_entered.bind(extract))
	add_child(extract)

## 撤离点交互
func _on_extract_entered(body: Node2D, _extract: Node2D) -> void:
	if body is Player:
		print("[OpenWorldLevel] 到达撤离点")
		GameManager.victory()

# ============================================================
# 信号回调
# ============================================================

func _on_player_health_changed(new_health: int) -> void:
	if hud and player:
		hud.update_health(new_health, player.max_health)

func _on_player_died() -> void:
	print("[OpenWorldLevel] 玩家死亡")

# ============================================================
# 物理更新
# ============================================================

func _physics_process(_delta: float) -> void:
	# 更新撤离点指示器
	_update_extract_indicator()

# ============================================================
# 撤离点方向指示器
# ============================================================

func _create_extract_indicator() -> void:
	_extract_indicator = Control.new()
	_extract_indicator.name = "ExtractIndicator"
	_extract_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_extract_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if hud:
		hud.add_child(_extract_indicator)
	else:
		add_child(_extract_indicator)

	_extract_arrow = ColorRect.new()
	_extract_arrow.name = "Arrow"
	_extract_arrow.size = Vector2(20, 20)
	_extract_arrow.color = Color(0.2, 0.8, 0.8, 0.8)
	_extract_indicator.add_child(_extract_arrow)

	_extract_label = Label.new()
	_extract_label.name = "DistanceLabel"
	_extract_label.text = "撤离点"
	_extract_label.add_theme_font_size_override("font_size", 14)
	_extract_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.8))
	_extract_indicator.add_child(_extract_label)

func _update_extract_indicator() -> void:
	if not _extract_indicator or not player:
		return

	# 查找当前房间的撤离点连接
	var room = _rooms.get(_current_room_id)
	if not room:
		_extract_indicator.visible = false
		return

	# 找到最近的撤离点房间
	var extract_room_id = _find_nearest_extract_room()
	if extract_room_id == "":
		_extract_indicator.visible = false
		return

	# 撤离点在屏幕内时不显示
	var extract_room: RoomData = _rooms[extract_room_id]
	var dir = room.get_direction_to(extract_room) if room.is_adjacent_to(extract_room) else ""
	if dir != "":
		# 相邻房间的撤离点，通过门方向指示
		_show_direction_indicator(dir)
	else:
		# 非相邻房间，隐藏指示器
		_extract_indicator.visible = false

func _find_nearest_extract_room() -> String:
	for room_id in _rooms:
		var room: RoomData = _rooms[room_id]
		if room.has_extraction_point:
			return room_id
	return ""

func _show_direction_indicator(direction: String) -> void:
	_extract_indicator.visible = true
	var viewport_size = get_viewport().get_visible_rect().size
	var arrow_pos: Vector2

	match direction:
		"north":
			arrow_pos = Vector2(viewport_size.x / 2, INDICATOR_MARGIN)
		"south":
			arrow_pos = Vector2(viewport_size.x / 2, viewport_size.y - INDICATOR_MARGIN)
		"east":
			arrow_pos = Vector2(viewport_size.x - INDICATOR_MARGIN, viewport_size.y / 2)
		"west":
			arrow_pos = Vector2(INDICATOR_MARGIN, viewport_size.y / 2)

	_extract_arrow.position = arrow_pos - Vector2(10, 10)
	_extract_label.position = arrow_pos + Vector2(15, -8)
	_extract_label.text = "撤离点 →"
