## 迷雾系统
## 管理房间的可见性状态：FOGGED（全黑）、REVEALED（轮廓）、EXPLORED（完全可见）
extends Node

# ============================================================
# 信号
# ============================================================

signal fog_updated(room_id: String, new_state: FogState)

# ============================================================
# 迷雾状态枚举
# ============================================================

enum FogState {
	FOGGED,    # 全黑，玩家不知道有什么
	REVEALED,  # 半透明轮廓，知道有房间但不知道内容
	EXPLORED   # 完全可见，知道房间内容
}

# ============================================================
# 状态
# ============================================================

# 每个房间的迷雾状态 { room_id: FogState }
var _fog_states: Dictionary = {}

# 房间数据引用 { room_id: RoomData }
var _rooms: Dictionary = {}

# ============================================================
# 初始化
# ============================================================

## 初始化迷雾系统
func initialize(rooms: Dictionary, start_room_id: String) -> void:
	_rooms = rooms
	_fog_states.clear()

	# 所有房间初始为FOGGED
	for room_id in rooms:
		_fog_states[room_id] = FogState.FOGGED

	# 起始房间设为EXPLORED
	_fog_states[start_room_id] = FogState.EXPLORED

	# 相邻房间设为REVEALED
	_reveal_adjacent_rooms(start_room_id)

# ============================================================
# 进入房间
# ============================================================

## 玩家进入房间时调用
func enter_room(room_id: String) -> void:
	if room_id not in _fog_states:
		return

	var old_state = _fog_states[room_id]
	_fog_states[room_id] = FogState.EXPLORED

	if old_state != FogState.EXPLORED:
		fog_updated.emit(room_id, FogState.EXPLORED)

	# 揭开相邻房间
	_reveal_adjacent_rooms(room_id)

## 揭开指定房间的所有相邻房间
func _reveal_adjacent_rooms(room_id: String) -> void:
	if room_id not in _rooms:
		return

	var room: RoomData = _rooms[room_id]
	for conn_id in room.connections:
		if conn_id in _fog_states:
			if _fog_states[conn_id] == FogState.FOGGED:
				_fog_states[conn_id] = FogState.REVEALED
				fog_updated.emit(conn_id, FogState.REVEALED)

# ============================================================
# 查询
# ============================================================

## 获取房间的迷雾状态
func get_fog_state(room_id: String) -> FogState:
	return _fog_states.get(room_id, FogState.FOGGED)

## 房间是否已探索
func is_explored(room_id: String) -> bool:
	return get_fog_state(room_id) == FogState.EXPLORED

## 房间是否已发现（已揭示）
func is_revealed(room_id: String) -> bool:
	return get_fog_state(room_id) >= FogState.REVEALED

## 获取所有迷雾状态（用于渲染小地图）
func get_all_fog_states() -> Dictionary:
	var result: Dictionary = {}
	for room_id in _fog_states:
		match _fog_states[room_id]:
			FogState.EXPLORED:
				result[room_id] = "explored"
			FogState.REVEALED:
				result[room_id] = "revealed"
			FogState.FOGGED:
				result[room_id] = "fogged"
	return result

## 获取已探索房间数量
func get_explored_count() -> int:
	var count = 0
	for room_id in _fog_states:
		if _fog_states[room_id] == FogState.EXPLORED:
			count += 1
	return count

## 获取已发现房间数量（包括已探索）
func get_revealed_count() -> int:
	var count = 0
	for room_id in _fog_states:
		if _fog_states[room_id] >= FogState.REVEALED:
			count += 1
	return count

## 获取总房间数
func get_total_count() -> int:
	return _fog_states.size()

## 强制揭开所有迷雾（调试用）
func reveal_all() -> void:
	for room_id in _fog_states:
		_fog_states[room_id] = FogState.EXPLORED
	for room_id in _fog_states:
		fog_updated.emit(room_id, FogState.EXPLORED)
