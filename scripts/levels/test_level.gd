## 测试关卡
## 使用 MapGenerator + MapRenderer + RoomManager + FogSystem 的完整地图系统
extends Node2D

# ============================================================
# 导出参数
# ============================================================

@export var layer_number: int = 1  # 当前层数（1=幽竹林, 2=火焰山, 3=天机阁）

# ============================================================
# 场景引用
# ============================================================

@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var enemy_container: Node2D = $Enemies
@onready var resource_container: Node2D = $Resources
@onready var extraction_point = $ExtractionPoint
@onready var hud: CanvasLayer = $HUD
@onready var map_renderer: Node2D = $MapRenderer

# ============================================================
# 预加载脚本
# ============================================================

var _MapGeneratorScript = preload("res://scripts/systems/map_generator.gd")
var _RoomDataScript = preload("res://scripts/systems/room.gd")
var _RoomManagerScript = preload("res://scripts/systems/room_manager.gd")
var _FogSystemScript = preload("res://scripts/systems/fog_system.gd")

# ============================================================
# 系统节点
# ============================================================

var _map_generator = null
var _room_manager = null
var _fog_system = null

# ============================================================
# 地图数据
# ============================================================

var _rooms: Dictionary = {}        # { id: RoomData }
var _current_room_id: String = ""
var _start_room_id: String = ""
var _boss_room_id: String = ""

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print("[TestLevel] _ready 开始")
	
	# 初始化游戏
	GameManager.start_new_game()

	# 初始化子系统
	_init_subsystems()

	# 检查节点引用
	print("[TestLevel] player: %s" % str(player))
	print("[TestLevel] enemy_container: %s" % str(enemy_container))
	print("[TestLevel] resource_container: %s" % str(resource_container))
	print("[TestLevel] map_renderer: %s" % str(map_renderer))

	# 生成地图
	_generate_map()

	# 连接信号
	_connect_signals()

	# 初始化HUD
	if hud and player:
		hud.initialize(player)

	# 将玩家放到起始房间
	_enter_start_room()
	
	# 打印房间连接信息
	_print_room_connections()
	
	print("[TestLevel] _ready 完成")

## 打印房间连接信息（用于调试）
func _print_room_connections() -> void:
	print("[TestLevel] === 房间连接信息 ===")
	for room_id in _rooms:
		var room = _rooms[room_id]
		print("[TestLevel] 房间 %s (%s) 位置: %s 连接: %s" % [
			room_id, 
			room.get_type_name(),
			str(room.grid_pos),
			str(room.connections)
		])

## 初始化子系统
func _init_subsystems() -> void:
	# 地图生成器
	_map_generator = _MapGeneratorScript.new()

	# 房间管理器（作为子节点）
	_room_manager = Node.new()
	_room_manager.set_script(_RoomManagerScript)
	_room_manager.name = "RoomManager"
	add_child(_room_manager)

	# 迷雾系统（作为子节点）
	_fog_system = Node.new()
	_fog_system.set_script(_FogSystemScript)
	_fog_system.name = "FogSystem"
	add_child(_fog_system)

## 连接信号
func _connect_signals() -> void:
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

	if extraction_point and extraction_point.has_signal("extract_completed"):
		extraction_point.extract_completed.connect(_on_extract_completed)

# ============================================================
# 地图生成
# ============================================================

func _generate_map() -> void:
	# 生成地图数据
	var map_data = _map_generator.generate_layer(layer_number)
	_rooms = map_data.get("rooms", {})
	_start_room_id = map_data.get("start_room_id", "")
	_boss_room_id = map_data.get("boss_room_id", "")

	if _rooms.is_empty():
		push_error("[TestLevel] 地图生成失败：没有房间")
		return

	print("[TestLevel] 第%d层地图生成完成：%d个房间" % [layer_number, _rooms.size()])
	print("[TestLevel] 起始房间: %s, Boss房间: %s" % [_start_room_id, _boss_room_id])

	# 初始化渲染器
	if map_renderer:
		map_renderer.initialize_map(_rooms)
		map_renderer.set_layer_theme(layer_number)

	# 初始化房间管理器
	if _room_manager:
		_room_manager.initialize(_rooms, enemy_container, resource_container)

	# 初始化迷雾系统
	if _fog_system:
		_fog_system.initialize(_rooms, _start_room_id)

# ============================================================
# 房间进入/切换
# ============================================================

## 进入起始房间
func _enter_start_room() -> void:
	if _start_room_id == "":
		return

	_enter_room(_start_room_id)

	# 放置玩家到房间中心
	var start_room = _rooms.get(_start_room_id)
	if start_room and player:
		player.position = start_room.get_world_center()
		
		# 更新渲染器位置，使起始房间在视口中居中
		if map_renderer:
			map_renderer.position = -start_room.get_world_rect().position

## 进入指定房间
func _enter_room(room_id: String) -> void:
	if room_id not in _rooms:
		return

	_current_room_id = room_id
	var room = _rooms[room_id]

	# 更新迷雾
	if _fog_system:
		_fog_system.enter_room(room_id)

	# 加载房间（生成敌人/资源）
	if _room_manager:
		_room_manager.load_room(room_id)

	# 渲染房间
	if map_renderer:
		map_renderer.render_room(room_id)
		# 更新小地图
		var fog_states = _fog_system.get_all_fog_states() if _fog_system else {}
		map_renderer.render_minimap(room_id, fog_states)

	# 设置撤离点位置
	if room.has_extraction_point and extraction_point:
		extraction_point.position = room.get_world_center()
		extraction_point.visible = true
		extraction_point.can_extract = true
	elif extraction_point:
		extraction_point.visible = false

	# Boss房间特殊处理
	if room.type == _RoomDataScript.RoomType.BOSS:
		print("[TestLevel] === 进入Boss房间 ===")

	room.enter()
	print("[TestLevel] 进入房间: %s (%s)" % [room.id, room.get_type_name()])

## 玩家移动到房间边缘时切换房间
func _check_room_transition() -> void:
	if _current_room_id == "" or player == null:
		return

	var room = _rooms.get(_current_room_id)
	if room == null:
		return

	var player_pos = player.position
	var room_rect = Rect2(
		Vector2(room.grid_pos.x * _RoomDataScript.ROOM_WIDTH, room.grid_pos.y * _RoomDataScript.ROOM_HEIGHT),
		Vector2(_RoomDataScript.ROOM_WIDTH, _RoomDataScript.ROOM_HEIGHT)
	)

	# 检查是否走到门口方向
	var margin = 30.0
	if player_pos.x < room_rect.position.x + margin:
		print("[TestLevel] 玩家到达西边边缘，尝试切换房间")
		_try_transition_to("west")
	elif player_pos.x > room_rect.end.x - margin:
		print("[TestLevel] 玩家到达东边边缘，尝试切换房间")
		_try_transition_to("east")
	elif player_pos.y < room_rect.position.y + margin:
		print("[TestLevel] 玩家到达北边边缘，尝试切换房间")
		_try_transition_to("north")
	elif player_pos.y > room_rect.end.y - margin:
		print("[TestLevel] 玩家到达南边边缘，尝试切换房间")
		_try_transition_to("south")

## 尝试向指定方向切换房间
func _try_transition_to(direction: String) -> void:
	if _current_room_id == "":
		return

	var current_room = _rooms.get(_current_room_id)
	if current_room == null:
		return

	# 查找该方向的连接房间
	for conn_id in current_room.connections:
		var conn_room = _rooms.get(conn_id)
		if conn_room == null:
			continue
		var dir = current_room.get_direction_to(conn_room)
		if dir == direction:
			# 检查是否还有敌人（未清除的战斗房间不允许离开）
			if _room_manager and _room_manager.has_active_enemies():
				var room_type = current_room.type
				if room_type in [_RoomDataScript.RoomType.COMBAT, _RoomDataScript.RoomType.ELITE, _RoomDataScript.RoomType.BOSS]:
					print("[TestLevel] 击败所有敌人才能离开！")
					return

			# 切换房间
			_enter_room(conn_id)

			# 将玩家放到新房间的对应入口
			_place_player_at_entrance(direction)
			return

## 将玩家放到新房间的入口位置
func _place_player_at_entrance(from_direction: String) -> void:
	if player == null:
		return

	var room = _rooms.get(_current_room_id)
	if room == null:
		return

	var center = room.get_world_center()
	match from_direction:
		"east":
			player.position = Vector2(center.x + 250, center.y)
		"west":
			player.position = Vector2(center.x - 250, center.y)
		"south":
			player.position = Vector2(center.x, center.y + 450)
		"north":
			player.position = Vector2(center.x, center.y - 450)
	
	# 更新渲染器位置，使新房间在视口中居中
	if map_renderer:
		map_renderer.position = -room.get_world_rect().position

# ============================================================
# 物理更新
# ============================================================

func _physics_process(_delta: float) -> void:
	_check_room_transition()

# ============================================================
# 信号回调
# ============================================================

func _on_player_health_changed(new_health: int) -> void:
	if hud and player:
		hud.update_health(new_health, player.max_health)

func _on_extract_completed() -> void:
	print("[TestLevel] 撤离完成！准备进入下一层")
	# 通知 GameManager
	GameManager.go_to_next_layer()

## 敌人掉落物品（连接到 RoomManager 的信号）
func _on_enemy_dropped_items(items: Array, enemy_position: Vector2) -> void:
	if ResourceLoader.exists("res://scenes/resources/resource_item.tscn"):
		var resource_scene = load("res://scenes/resources/resource_item.tscn")
		for item in items:
			var resource = resource_scene.instantiate()
			resource.item_id = item.get("id", "")
			resource.item_name = item.get("name", "")
			resource.item_amount = item.get("amount", 1)
			resource.position = enemy_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			resource_container.add_child(resource)
