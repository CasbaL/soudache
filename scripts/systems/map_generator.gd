## 地图生成器
## 根据层配置生成完整地图：主路径 + 分支 + 特殊房间
## 基于"手工模板 + 程序化连接"理念
class_name MapGenerator
extends RefCounted

# ============================================================
# 层配置
# ============================================================

# 每层的房间数量范围 [min, max]
const LAYER_ROOM_COUNTS: Dictionary = {
	1: Vector2i(8, 10),
	2: Vector2i(10, 12),
	3: Vector2i(12, 15),
}

# 每层主路径长度（层数 × 3 + 2）
const LAYER_MAIN_PATH_LENGTHS: Dictionary = {
	1: 5,
	2: 8,
	3: 11,
}

# 分支路径数量范围
const BRANCH_COUNT_MIN: int = 2
const BRANCH_COUNT_MAX: int = 3

# 分支路径长度范围
const BRANCH_LENGTH_MIN: int = 1
const BRANCH_LENGTH_MAX: int = 3

# ============================================================
# 生成状态
# ============================================================

var _rooms: Dictionary = {}  # { id: RoomData }
var _room_counter: int = 0
var _layer: int = 1
var _used_positions: Dictionary = {}  # { Vector2i: room_id }
var _main_path_ids: Array[String] = []
var _branch_path_ids: Array[String] = []

# ============================================================
# 公共接口
# ============================================================

## 生成完整的一层地图
## 返回 { rooms: Dictionary, main_path: Array[String], start_room_id: String, boss_room_id: String }
func generate_layer(layer_num: int) -> Dictionary:
	_layer = layer_num
	_rooms.clear()
	_room_counter = 0
	_used_positions.clear()
	_main_path_ids.clear()
	_branch_path_ids.clear()

	# 步骤1：生成主路径
	_generate_main_path()

	# 步骤2：添加分支路径
	_generate_branch_paths()

	# 步骤3：分配房间类型
	_assign_room_types()

	# 步骤4：为每个房间分配模板
	_assign_templates()

	# 步骤5：验证可达性（BFS）
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

	# 创建起始房间
	var start_room = _create_room(current_pos, RoomData.RoomType.START)
	_main_path_ids.append(start_room.id)
	_used_positions[current_pos] = start_room.id

	# 逐步向右/下延伸
	for i in range(main_path_length - 1):
		current_pos = _find_next_main_path_pos(current_pos)
		var room = _create_room(current_pos)
		_main_path_ids.append(room.id)
		_used_positions[current_pos] = room.id

	# 连接主路径房间
	for i in range(_main_path_ids.size() - 1):
		var room_a = _rooms[_main_path_ids[i]]
		var room_b = _rooms[_main_path_ids[i + 1]]
		_connect_rooms(room_a, room_b)

	# 最后一个房间设为BOSS
	_rooms[_main_path_ids[_main_path_ids.size() - 1]].type = RoomData.RoomType.BOSS

## 寻找主路径下一个位置（优先向右，偶尔向下）
func _find_next_main_path_pos(current: Vector2i) -> Vector2i:
	var directions: Array[Vector2i] = []

	# 主要向右走，偶尔向下
	if randf() < 0.7:
		directions.append(Vector2i(1, 0))  # 右
		directions.append(Vector2i(0, 1))  # 下
	else:
		directions.append(Vector2i(0, 1))  # 下
		directions.append(Vector2i(1, 0))  # 右

	for dir in directions:
		var candidate = current + dir
		if candidate not in _used_positions:
			return candidate

	# 如果首选方向都被占了，搜索所有相邻格子
	for dir in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var candidate = current + dir
		if candidate not in _used_positions:
			return candidate

	# 极端情况：强制放右边更远处
	var fallback = current + Vector2i(2, 0)
	if fallback not in _used_positions:
		return fallback
	return current + Vector2i(3, 0)

# ============================================================
# 步骤2：生成分支路径
# ============================================================

func _generate_branch_paths() -> void:
	var branch_count = randi_range(BRANCH_COUNT_MIN, BRANCH_COUNT_MAX)

	# 从主路径中间节点分叉（排除首尾）
	var available_main_nodes: Array[String] = []
	for i in range(1, _main_path_ids.size() - 1):
		available_main_nodes.append(_main_path_ids[i])

	# 随机选择分叉点
	var branch_points: Array[String] = []
	var shuffled = available_main_nodes.duplicate()
	shuffled.shuffle()
	for i in range(min(branch_count, shuffled.size())):
		branch_points.append(shuffled[i])

	for bp_id in branch_points:
		_generate_single_branch(bp_id)

## 从指定房间生成一条分支
func _generate_single_branch(from_room_id: String) -> void:
	var from_room: RoomData = _rooms[from_room_id]
	var branch_length = randi_range(BRANCH_LENGTH_MIN, BRANCH_LENGTH_MAX)
	var current_pos = from_room.grid_pos

	var prev_room = from_room

	for i in range(branch_length):
		# 寻找可用的相邻格子（排除已有房间的方向）
		var next_pos = _find_branch_pos(current_pos, from_room.grid_pos)
		if next_pos == current_pos:
			break  # 无可用位置，终止分支

		var new_room = _create_room(next_pos)
		_connect_rooms(prev_room, new_room)

		_branch_path_ids.append(new_room.id)
		_used_positions[next_pos] = new_room.id

		prev_room = new_room
		current_pos = next_pos

## 寻找分支路径下一个位置（不走回主路径方向）
func _find_branch_pos(current: Vector2i, origin: Vector2i) -> Vector2i:
	# 优先向下或向右延伸分支
	var preferred_dirs: Array[Vector2i] = []
	var away = current - origin

	# 远离主路径的方向优先
	if away.y >= 0:
		preferred_dirs.append(Vector2i(0, 1))
		preferred_dirs.append(Vector2i(1, 0))
	else:
		preferred_dirs.append(Vector2i(0, -1))
		preferred_dirs.append(Vector2i(1, 0))

	# 追加其他方向
	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		if d not in preferred_dirs:
			preferred_dirs.append(d)

	for dir in preferred_dirs:
		var candidate = current + dir
		if candidate not in _used_positions:
			# 确保不紧邻主路径（除了起点）
			if not _is_adjacent_to_main_path_except(candidate, origin):
				return candidate

	# 放松约束：允许紧邻主路径
	for dir in preferred_dirs:
		var candidate = current + dir
		if candidate not in _used_positions:
			return candidate

	return current  # 无法扩展

## 检查位置是否紧邻主路径（排除指定的源房间附近）
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
	# 收集尚未分配类型的房间（START和BOSS已分配）
	var unassigned: Array[String] = []

	for room_id in _main_path_ids:
		var room: RoomData = _rooms[room_id]
		if room.type != RoomData.RoomType.START and room.type != RoomData.RoomType.BOSS:
			unassigned.append(room_id)

	for room_id in _branch_path_ids:
		unassigned.append(room_id)

	var total = unassigned.size()

	# 按比例分配：40% COMBAT, 20% RESOURCE, 15% EVENT, 10% ELITE
	var combat_count = maxi(1, roundi(total * 0.40))
	var resource_count = maxi(1, roundi(total * 0.20))
	var event_count = maxi(1, roundi(total * 0.15))
	var elite_count = maxi(1, roundi(total * 0.10))
	# 剩余给 EXTRACT + SECRET

	# 构建类型列表
	var type_pool: Array[RoomData.RoomType] = []
	for i in range(combat_count):
		type_pool.append(RoomData.RoomType.COMBAT)
	for i in range(resource_count):
		type_pool.append(RoomData.RoomType.RESOURCE)
	for i in range(event_count):
		type_pool.append(RoomData.RoomType.EVENT)
	for i in range(elite_count):
		type_pool.append(RoomData.RoomType.ELITE)

	# 添加2-3个EXTRACT
	var extract_count = randi_range(2, 3)
	for i in range(extract_count):
		type_pool.append(RoomData.RoomType.EXTRACT)

	# 添加1-2个SECRET
	var secret_count = randi_range(1, 2)
	for i in range(secret_count):
		type_pool.append(RoomData.RoomType.SECRET)

	# 截断或填充到精确数量
	while type_pool.size() > unassigned.size():
		type_pool.pop_back()
	while type_pool.size() < unassigned.size():
		type_pool.append(RoomData.RoomType.COMBAT)

	# 随机打乱
	type_pool.shuffle()

	# 策略性放置：EXTRACT放在分支上，SECRET放在分支末端
	_strategic_place_special(unassigned, type_pool)

	# 批量分配剩余类型
	for i in range(unassigned.size()):
		if i < type_pool.size():
			_rooms[unassigned[i]].type = type_pool[i]

## 策略性放置特殊房间
func _strategic_place_special(unassigned: Array[String], type_pool: Array[RoomData.RoomType]) -> void:
	# 从type_pool中提取EXTRACT和SECRET
	var extracts: Array[int] = []
	var secrets: Array[int] = []
	for i in range(type_pool.size()):
		if type_pool[i] == RoomData.RoomType.EXTRACT:
			extracts.append(i)
		elif type_pool[i] == RoomData.RoomType.SECRET:
			secrets.append(i)

	# 将EXTRACT放在分支路径上
	var branch_unassigned: Array[String] = []
	for room_id in unassigned:
		if room_id in _branch_path_ids:
			branch_unassigned.append(room_id)

	# 分配EXTRACT到分支
	for i in range(mini(extracts.size(), branch_unassigned.size())):
		var idx = extracts[i]
		if idx < unassigned.size():
			# 交换：将分支房间放到EXTRACT位置
			var branch_room_id = branch_unassigned[i]
			var branch_idx = unassigned.find(branch_room_id)
			if branch_idx >= 0 and branch_idx != idx:
				# 交换unassigned中的位置
				var temp = unassigned[idx]
				unassigned[idx] = branch_room_id
				unassigned[branch_idx] = temp

	# SECRET放在分支末端
	if _branch_path_ids.size() > 0 and secrets.size() > 0:
		var last_branch = _branch_path_ids[_branch_path_ids.size() - 1]
		var last_branch_idx = unassigned.find(last_branch)
		if last_branch_idx >= 0 and secrets[0] < unassigned.size():
			var sec_idx = secrets[0]
			if last_branch_idx != sec_idx:
				var temp = unassigned[sec_idx]
				unassigned[sec_idx] = last_branch
				unassigned[last_branch_idx] = temp

# ============================================================
# 步骤4：为房间分配模板
# ============================================================

func _assign_templates() -> void:
	for room_id in _rooms:
		var room: RoomData = _rooms[room_id]
		if room.type == RoomData.RoomType.START:
			room.template_id = "start"
			room.layer_theme = RoomTemplates.get_layer_theme_name(_layer)
			continue
		if room.type == RoomData.RoomType.BOSS:
			room.template_id = "boss_" + RoomTemplates.get_boss_id(_layer)
			room.enemies = [{"enemy_id": RoomTemplates.get_boss_id(_layer), "count": 1}]
			room.difficulty = 5
			room.layer_theme = RoomTemplates.get_layer_theme_name(_layer)
			continue

		var template = RoomTemplates.pick_random_template(_layer, room.type)
		if template.is_empty():
			# 回退为COMBAT模板
			template = RoomTemplates.pick_random_template(_layer, RoomData.RoomType.COMBAT)

		room.template_id = template.get("id", "")
		room.difficulty = template.get("difficulty", 1)
		room.has_npc = template.get("has_npc", false)
		room.npc_dialogue = template.get("npc_dialogue", "")
		room.layer_theme = RoomTemplates.get_layer_theme_name(_layer)
		room.has_extraction_point = (room.type == RoomData.RoomType.EXTRACT)

		# 解析敌人配置
		var template_enemies = template.get("enemies", [])
		for e in template_enemies:
			var count = randi_range(e.get("count_min", 1), e.get("count_max", 1))
			if count > 0:
				room.enemies.append({"enemy_id": e.get("enemy_id", ""), "count": count})

		# 解析资源配置
		var template_resources = template.get("resources", [])
		for r in template_resources:
			var amount = randi_range(r.get("amount_min", 1), r.get("amount_max", 1))
			if amount > 0:
				room.resources.append({
					"resource_id": r.get("resource_id", ""),
					"name": r.get("name", ""),
					"amount": amount
				})

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
		var room: RoomData = _rooms[current_id]
		for conn_id in room.connections:
			if conn_id not in visited and conn_id in _rooms:
				visited[conn_id] = true
				queue.append(conn_id)

	# 检查是否所有房间可达
	for room_id in _rooms:
		if room_id not in visited:
			print("[MapGenerator] WARNING: 房间 %s 不可达，尝试修复" % room_id)
			_fix_unreachable_room(room_id, visited)

## 修复不可达房间：连接到最近的可达房间
func _fix_unreachable_room(room_id: String, visited: Dictionary) -> void:
	var room: RoomData = _rooms[room_id]
	var best_id = ""
	var best_dist = 999999

	for v_id in visited:
		var v_room: RoomData = _rooms[v_id]
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

## 创建房间
func _create_room(grid_pos: Vector2i, type: RoomData.RoomType = RoomData.RoomType.COMBAT) -> RoomData:
	_room_counter += 1
	var room = RoomData.new("room_%03d" % _room_counter, type, grid_pos)
	_rooms[room.id] = room
	return room

## 连接两个房间（双向）
func _connect_rooms(room_a: RoomData, room_b: RoomData) -> void:
	room_a.connect_to(room_b.id)
	room_b.connect_to(room_a.id)

## 获取所有房间
func get_rooms() -> Dictionary:
	return _rooms

## 获取主路径
func get_main_path() -> Array[String]:
	return _main_path_ids
