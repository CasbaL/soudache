## 地图生成器
## 根据层配置生成完整地图：主路径 + 分支 + 特殊房间
class_name MapGenerator
extends RefCounted

# 预加载 RoomData 脚本
var _RoomDataScript = load("res://scripts/systems/room.gd")
var _RoomTemplatesScript = load("res://scripts/systems/room_templates.gd")

# ============================================================
# 层配置
# ============================================================

const LAYER_ROOM_COUNTS: Dictionary = {
	1: Vector2i(8, 10),
	2: Vector2i(10, 12),
	3: Vector2i(12, 15),
}

const LAYER_MAIN_PATH_LENGTHS: Dictionary = {
	1: 5,
	2: 8,
	3: 11,
}

const BRANCH_COUNT_MIN: int = 2
const BRANCH_COUNT_MAX: int = 3
const BRANCH_LENGTH_MIN: int = 1
const BRANCH_LENGTH_MAX: int = 3

# ============================================================
# 生成状态
# ============================================================

var _rooms: Dictionary = {}
var _room_counter: int = 0
var _layer: int = 1
var _used_positions: Dictionary = {}
var _main_path_ids: Array[String] = []
var _branch_path_ids: Array[String] = []

# ============================================================
# 公共接口
# ============================================================

func generate_layer(layer_num: int) -> Dictionary:
	_layer = layer_num
	_rooms.clear()
	_room_counter = 0
	_used_positions.clear()
	_main_path_ids.clear()
	_branch_path_ids.clear()

	_generate_main_path()
	_generate_branch_paths()
	_assign_room_types()
	_assign_templates()
	_verify_reachability()

	var start_room_id = _main_path_ids[0]
	var boss_room_id = _main_path_ids[_main_path_ids.size() - 1]

	return {
		"rooms": _rooms.duplicate(),
		"main_path": _main_path_ids.duplicate(),
		"branch_paths": _branch_path_ids.duplicate(),
		"start_room_id": start_room_id,
		"boss_room_id": boss_room_id,
		"layer": _layer,
	}

# ============================================================
# 步骤1：生成主路径
# ============================================================

func _generate_main_path() -> void:
	var main_path_length = LAYER_MAIN_PATH_LENGTHS.get(_layer, 5)
	var current_pos = Vector2i(0, 0)

	var start_room = _create_room(current_pos, _RoomDataScript.RoomType.START)
	_main_path_ids.append(start_room.id)
	_used_positions[current_pos] = start_room.id

	for i in range(main_path_length - 1):
		current_pos = _find_next_main_path_pos(current_pos)
		var room = _create_room(current_pos)
		_main_path_ids.append(room.id)
		_used_positions[current_pos] = room.id

	for i in range(_main_path_ids.size() - 1):
		var room_a = _rooms[_main_path_ids[i]]
		var room_b = _rooms[_main_path_ids[i + 1]]
		_connect_rooms(room_a, room_b)

	_rooms[_main_path_ids[_main_path_ids.size() - 1]].type = _RoomDataScript.RoomType.BOSS

func _find_next_main_path_pos(current: Vector2i) -> Vector2i:
	var directions: Array[Vector2i] = []
	if randf() < 0.7:
		directions.append(Vector2i(1, 0))
		directions.append(Vector2i(0, 1))
	else:
		directions.append(Vector2i(0, 1))
		directions.append(Vector2i(1, 0))

	for dir in directions:
		var candidate = current + dir
		if candidate not in _used_positions:
			return candidate

	for dir in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var candidate = current + dir
		if candidate not in _used_positions:
			return candidate

	var fallback = current + Vector2i(2, 0)
	if fallback not in _used_positions:
		return fallback
	return current + Vector2i(3, 0)

# ============================================================
# 步骤2：生成分支路径
# ============================================================

func _generate_branch_paths() -> void:
	var branch_count = randi_range(BRANCH_COUNT_MIN, BRANCH_COUNT_MAX)

	var available_main_nodes: Array[String] = []
	for i in range(1, _main_path_ids.size() - 1):
		available_main_nodes.append(_main_path_ids[i])

	var branch_points: Array[String] = []
	var shuffled = available_main_nodes.duplicate()
	shuffled.shuffle()
	for i in range(min(branch_count, shuffled.size())):
		branch_points.append(shuffled[i])

	for bp_id in branch_points:
		_generate_single_branch(bp_id)

func _generate_single_branch(from_room_id: String) -> void:
	var from_room = _rooms[from_room_id]
	var branch_length = randi_range(BRANCH_LENGTH_MIN, BRANCH_LENGTH_MAX)
	var current_pos = from_room.grid_pos

	var prev_room = from_room

	for i in range(branch_length):
		var next_pos = _find_branch_pos(current_pos, from_room.grid_pos)
		if next_pos == current_pos:
			break

		var new_room = _create_room(next_pos)
		_connect_rooms(prev_room, new_room)

		_branch_path_ids.append(new_room.id)
		_used_positions[next_pos] = new_room.id

		prev_room = new_room
		current_pos = next_pos

func _find_branch_pos(current: Vector2i, origin: Vector2i) -> Vector2i:
	var preferred_dirs: Array[Vector2i] = []
	var away = current - origin

	if away.y >= 0:
		preferred_dirs.append(Vector2i(0, 1))
		preferred_dirs.append(Vector2i(1, 0))
	else:
		preferred_dirs.append(Vector2i(0, -1))
		preferred_dirs.append(Vector2i(1, 0))

	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		if d not in preferred_dirs:
			preferred_dirs.append(d)

	for dir in preferred_dirs:
		var candidate = current + dir
		if candidate not in _used_positions:
			if not _is_adjacent_to_main_path_except(candidate, origin):
				return candidate

	for dir in preferred_dirs:
		var candidate = current + dir
		if candidate not in _used_positions:
			return candidate

	return current

func _is_adjacent_to_main_path_except(pos: Vector2i, except_origin: Vector2i) -> bool:
	for dir in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var neighbor = pos + dir
		if neighbor == except_origin:
			continue
		if neighbor in _used_positions:
			var neighbor_id = _used_positions[neighbor]
			if neighbor_id in _main_path_ids:
				return true
	return false

# ============================================================
# 步骤3：分配房间类型
# ============================================================

func _assign_room_types() -> void:
	var unassigned: Array[String] = []

	for room_id in _main_path_ids:
		var room = _rooms[room_id]
		if room.type != _RoomDataScript.RoomType.START and room.type != _RoomDataScript.RoomType.BOSS:
			unassigned.append(room_id)

	for room_id in _branch_path_ids:
		unassigned.append(room_id)

	var total = unassigned.size()

	var combat_count = maxi(1, roundi(total * 0.40))
	var resource_count = maxi(1, roundi(total * 0.20))
	var event_count = maxi(1, roundi(total * 0.15))
	var elite_count = maxi(1, roundi(total * 0.10))

	var type_pool: Array = []
	for i in range(combat_count):
		type_pool.append(_RoomDataScript.RoomType.COMBAT)
	for i in range(resource_count):
		type_pool.append(_RoomDataScript.RoomType.RESOURCE)
	for i in range(event_count):
		type_pool.append(_RoomDataScript.RoomType.EVENT)
	for i in range(elite_count):
		type_pool.append(_RoomDataScript.RoomType.ELITE)

	var extract_count = randi_range(2, 3)
	for i in range(extract_count):
		type_pool.append(_RoomDataScript.RoomType.EXTRACT)

	var secret_count = randi_range(1, 2)
	for i in range(secret_count):
		type_pool.append(_RoomDataScript.RoomType.SECRET)

	while type_pool.size() > unassigned.size():
		type_pool.pop_back()
	while type_pool.size() < unassigned.size():
		type_pool.append(_RoomDataScript.RoomType.COMBAT)

	type_pool.shuffle()

	for i in range(unassigned.size()):
		if i < type_pool.size():
			_rooms[unassigned[i]].type = type_pool[i]

# ============================================================
# 步骤4：为房间分配模板
# ============================================================

func _assign_templates() -> void:
	for room_id in _rooms:
		var room = _rooms[room_id]
		if room.type == _RoomDataScript.RoomType.START:
			room.template_id = "start"
			room.layer_theme = _RoomTemplatesScript.get_layer_theme_name(_layer)
			print("[MapGenerator] 房间 %s: START, 无敌人" % room_id)
			continue
		if room.type == _RoomDataScript.RoomType.BOSS:
			room.template_id = "boss_" + _RoomTemplatesScript.get_boss_id(_layer)
			room.enemies = [{"enemy_id": _RoomTemplatesScript.get_boss_id(_layer), "count": 1}]
			room.difficulty = 5
			room.layer_theme = _RoomTemplatesScript.get_layer_theme_name(_layer)
			print("[MapGenerator] 房间 %s: BOSS, 敌人: %s" % [room_id, room.enemies])
			continue

		var template = _RoomTemplatesScript.pick_random_template(_layer, room.type)
		if template.is_empty():
			print("[MapGenerator] 警告: 房间 %s 类型 %d 没有模板，使用COMBAT" % [room_id, room.type])
			template = _RoomTemplatesScript.pick_random_template(_layer, _RoomDataScript.RoomType.COMBAT)

		room.template_id = template.get("id", "")
		room.difficulty = template.get("difficulty", 1)
		room.has_npc = template.get("has_npc", false)
		room.npc_dialogue = template.get("npc_dialogue", "")
		room.layer_theme = _RoomTemplatesScript.get_layer_theme_name(_layer)
		room.has_extraction_point = (room.type == _RoomDataScript.RoomType.EXTRACT)

		var template_enemies = template.get("enemies", [])
		for e in template_enemies:
			var count = randi_range(e.get("count_min", 1), e.get("count_max", 1))
			if count > 0:
				room.enemies.append({"enemy_id": e.get("enemy_id", ""), "count": count})

		var template_resources = template.get("resources", [])
		for r in template_resources:
			var amount = randi_range(r.get("amount_min", 1), r.get("amount_max", 1))
			if amount > 0:
				room.resources.append({
					"resource_id": r.get("resource_id", ""),
					"name": r.get("name", ""),
					"amount": amount
				})

		print("[MapGenerator] 房间 %s: %s, 模板: %s, 敌人: %d, 资源: %d" % [room_id, room.get_type_name(), room.template_id, room.enemies.size(), room.resources.size()])

# ============================================================
# 步骤5：验证可达性（BFS）
# ============================================================

func _verify_reachability() -> void:
	if _main_path_ids.is_empty():
		return

	var start_id = _main_path_ids[0]
	var visited: Dictionary = {}
	var queue: Array[String] = [start_id]
	visited[start_id] = true

	while queue.size() > 0:
		var current_id = queue.pop_front()
		var room = _rooms[current_id]
		for conn_id in room.connections:
			if conn_id not in visited and conn_id in _rooms:
				visited[conn_id] = true
				queue.append(conn_id)

	for room_id in _rooms:
		if room_id not in visited:
			print("[MapGenerator] WARNING: 房间 %s 不可达，尝试修复" % room_id)
			_fix_unreachable_room(room_id, visited)

func _fix_unreachable_room(room_id: String, visited: Dictionary) -> void:
	var room = _rooms[room_id]
	var best_id = ""
	var best_dist = 999999

	for v_id in visited:
		var v_room = _rooms[v_id]
		var dist = (room.grid_pos - v_room.grid_pos).length()
		if dist < best_dist:
			best_dist = dist
			best_id = v_id

	if best_id != "":
		_connect_rooms(room, _rooms[best_id])
		visited[room_id] = true

# ============================================================
# 辅助方法
# ============================================================

func _create_room(grid_pos: Vector2i, type = null) -> Variant:
	_room_counter += 1
	if type == null:
		type = _RoomDataScript.RoomType.COMBAT
	var room = _RoomDataScript.new("room_%03d" % _room_counter, type, grid_pos)
	_rooms[room.id] = room
	return room

func _connect_rooms(room_a, room_b) -> void:
	room_a.connect_to(room_b.id)
	room_b.connect_to(room_a.id)

func get_rooms() -> Dictionary:
	return _rooms

func get_main_path() -> Array[String]:
	return _main_path_ids
