## 房间管理器
## 管理当前房间的敌人/资源生成、房间切换、完成追踪
extends Node

# ============================================================
# 信号
# ============================================================

signal room_entered(room_id: String)
signal room_cleared(room_id: String)
signal room_exited(room_id: String)
signal all_rooms_cleared()
signal boss_defeated()

# ============================================================
# 配置
# ============================================================

# 敌人散布范围（距房间中心的偏移）
const ENEMY_SPREAD_X: float = 250.0
const ENEMY_SPREAD_Y: float = 400.0

# 资源散布范围
const RESOURCE_SPREAD_X: float = 200.0
const RESOURCE_SPREAD_Y: float = 350.0

# 资源场景
var _resource_scene: PackedScene = null

# ============================================================
# 状态
# ============================================================

var _rooms: Dictionary = {}  # { id: RoomData }
var _current_room_id: String = ""
var _enemy_container: Node2D = null
var _resource_container: Node2D = null

# 当前房间中存活的敌人
var _active_enemies: Array[Node2D] = []
# 当前房间中的资源
var _active_resources: Array[Node2D] = []

# 房间完成状态（全局追踪）
var _cleared_rooms: Dictionary = {}  # { room_id: true }

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	# 预加载资源场景
	if ResourceLoader.exists("res://scenes/resources/resource_item.tscn"):
		_resource_scene = load("res://scenes/resources/resource_item.tscn")

## 初始化房间管理器
func initialize(rooms: Dictionary, enemy_container: Node2D, resource_container: Node2D) -> void:
	_rooms = rooms
	_enemy_container = enemy_container
	_resource_container = resource_container
	_cleared_rooms.clear()
	_current_room_id = ""

## 设置当前房间（进入房间时调用）
func load_room(room_id: String) -> void:
	if room_id not in _rooms:
		print("[RoomManager] 未知房间ID: %s" % room_id)
		return

	# 清理旧房间
	if _current_room_id != "":
		_exit_current_room()

	_current_room_id = room_id
	var room: RoomData = _rooms[room_id]
	room.enter()

	# 生成敌人
	_spawn_room_enemies(room)

	# 生成资源
	_spawn_room_resources(room)

	# Boss房间特殊处理
	if room.type == RoomData.RoomType.BOSS:
		_setup_boss_room(room)

	room_entered.emit(room_id)

## 退出当前房间
func _exit_current_room() -> void:
	if _current_room_id == "":
		return

	# 清除所有敌人和资源
	clear_room()

	room_exited.emit(_current_room_id)

## 清除当前房间的所有实体
func clear_room() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()

	for resource in _active_resources:
		if is_instance_valid(resource):
			resource.queue_free()
	_active_resources.clear()

# ============================================================
# 敌人生成
# ============================================================

func _spawn_room_enemies(room: RoomData) -> void:
	if _enemy_container == null:
		return

	var center = Vector2(RoomData.ROOM_WIDTH / 2, RoomData.ROOM_HEIGHT / 2)

	for enemy_config in room.enemies:
		var enemy_id = enemy_config.get("enemy_id", "")
		var count = enemy_config.get("count", 0)
		if enemy_id == "" or count <= 0:
			continue

		for i in range(count):
			var spawn_pos = center + Vector2(
				randf_range(-ENEMY_SPREAD_X, ENEMY_SPREAD_X),
				randf_range(-ENEMY_SPREAD_Y, ENEMY_SPREAD_Y)
			)

			var enemy = EnemySpawner.spawn_enemy(enemy_id, spawn_pos)
			if enemy:
				_active_enemies.append(enemy)
				# 连接死亡信号
				if enemy.has_signal("died"):
					enemy.died.connect(_on_enemy_died.bind(enemy))

## 敌人死亡回调
func _on_enemy_died(enemy: Node2D) -> void:
	_active_enemies.erase(enemy)

	# 检查是否所有敌人已清除
	if _active_enemies.is_empty():
		_on_room_enemies_cleared()

## 房间内所有敌人清除
func _on_room_enemies_cleared() -> void:
	if _current_room_id == "":
		return

	var room: RoomData = _rooms.get(_current_room_id)
	if room == null:
		return

	if not room.is_cleared:
		room.mark_cleared()
		_cleared_rooms[_current_room_id] = true
		room_cleared.emit(_current_room_id)

		# 检查是否Boss房间
		if room.type == RoomData.RoomType.BOSS:
			boss_defeated.emit()

		# 检查是否所有战斗/精英房间已清除
		_check_all_cleared()

## 检查所有战斗类房间是否都已清除
func _check_all_cleared() -> void:
	for room_id in _rooms:
		var room: RoomData = _rooms[room_id]
		if room.type in [RoomData.RoomType.COMBAT, RoomData.RoomType.ELITE, RoomData.RoomType.BOSS]:
			if not room.is_cleared:
				return
	all_rooms_cleared.emit()

# ============================================================
# 资源生成
# ============================================================

func _spawn_room_resources(room: RoomData) -> void:
	if _resource_container == null:
		return

	var center = Vector2(RoomData.ROOM_WIDTH / 2, RoomData.ROOM_HEIGHT / 2)

	for res_config in room.resources:
		var resource_id = res_config.get("resource_id", "")
		var amount = res_config.get("amount", 0)
		var name_str = res_config.get("name", "")
		if resource_id == "" or amount <= 0:
			continue

		# 对于宝箱等特殊资源，生成多个
		var spawn_count = 1
		if resource_id in ["chest"]:
			spawn_count = amount

		for i in range(spawn_count):
			var spawn_pos = center + Vector2(
				randf_range(-RESOURCE_SPREAD_X, RESOURCE_SPREAD_X),
				randf_range(-RESOURCE_SPREAD_Y, RESOURCE_SPREAD_Y)
			)

			_spawn_single_resource(resource_id, name_str, amount, spawn_pos)

func _spawn_single_resource(resource_id: String, resource_name: String, amount: int, pos: Vector2) -> void:
	if _resource_scene:
		var resource = _resource_scene.instantiate()
		resource.item_id = resource_id
		resource.item_name = resource_name
		resource.item_amount = amount
		resource.position = pos
		_resource_container.add_child(resource)
		_active_resources.append(resource)
	else:
		# 如果没有资源场景，直接创建一个简单的资源节点
		var resource_node = _create_fallback_resource(resource_id, resource_name, amount, pos)
		_resource_container.add_child(resource_node)
		_active_resources.append(resource_node)

## 创建后备资源节点（当 resource_item.tscn 不存在时）
func _create_fallback_resource(resource_id: String, resource_name: String, amount: int, pos: Vector2) -> Node2D:
	var node = Area2D.new()
	node.position = pos
	node.collision_layer = 4
	node.collision_mask = 1

	# 视觉
	var sprite = ColorRect.new()
	sprite.size = Vector2(20, 20)
	sprite.position = -Vector2(10, 10)
	match resource_id:
		"spirit_stone":
			sprite.color = Color(0.3, 0.6, 1.0)
		"herb":
			sprite.color = Color(0.2, 0.8, 0.2)
		"ore":
			sprite.color = Color(0.6, 0.4, 0.2)
		"chest":
			sprite.color = Color(0.8, 0.6, 0.2)
		"fire_crystal":
			sprite.color = Color(0.9, 0.3, 0.1)
		"gear":
			sprite.color = Color(0.5, 0.5, 0.6)
		"technique_fragment":
			sprite.color = Color(0.7, 0.3, 0.9)
		"equipment":
			sprite.color = Color(0.2, 0.8, 0.9)
		_:
			sprite.color = Color(0.5, 0.5, 0.5)
	node.add_child(sprite)

	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	node.add_child(collision)

	# 给节点一个脚本来处理收集
	node.set_meta("item_id", resource_id)
	node.set_meta("item_name", resource_name)
	node.set_meta("item_amount", amount)
	node.body_entered.connect(_on_fallback_resource_body_entered.bind(node))

	return node

func _on_fallback_resource_body_entered(body: Node2D, resource_node: Node2D) -> void:
	if body is Player:
		var item_data = {
			"id": resource_node.get_meta("item_id"),
			"name": resource_node.get_meta("item_name"),
			"amount": resource_node.get_meta("item_amount")
		}
		if GameManager.add_to_inventory(item_data):
			_active_resources.erase(resource_node)
			resource_node.queue_free()

# ============================================================
# Boss房间
# ============================================================

func _setup_boss_room(room: RoomData) -> void:
	# Boss房间可能有额外环境效果，目前留空
	pass

# ============================================================
# 公共查询
# ============================================================

func get_current_room_id() -> String:
	return _current_room_id

func get_current_room() -> RoomData:
	return _rooms.get(_current_room_id, null)

func get_room(room_id: String) -> RoomData:
	return _rooms.get(room_id, null)

func is_room_cleared(room_id: String) -> bool:
	return _cleared_rooms.has(room_id)

func get_enemy_count() -> int:
	return _active_enemies.size()

func has_active_enemies() -> bool:
	return not _active_enemies.is_empty()
