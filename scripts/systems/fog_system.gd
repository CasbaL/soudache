## 迷雾系统（大地图版本）
## 管理区域的可见性状态：FOGGED（全黑）、REVEALED（轮廓）、EXPLORED（完全可见）
extends Node

# ============================================================
# 信号
# ============================================================

signal fog_updated(zone_id: String, new_state: FogState)

# ============================================================
# 迷雾状态枚举
# ============================================================

enum FogState {
	FOGGED,    # 全黑，玩家不知道有什么
	REVEALED,  # 半透明轮廓，知道有区域但不知道内容
	EXPLORED   # 完全可见，知道区域内容
}

# ============================================================
# 状态
# ============================================================

# 每个区域的迷雾状态 { zone_id: FogState }
var _fog_states: Dictionary = {}

# 区域数据引用 { zone_id: zone_object }
var _zones: Dictionary = {}

# 地图尺寸
var _map_size: Vector2i = Vector2i.ZERO

# ============================================================
# 初始化
# ============================================================

## 初始化迷雾系统
func initialize(zones: Dictionary, map_size: Vector2i) -> void:
	_zones = zones
	_map_size = map_size
	_fog_states.clear()

	# 所有区域初始为FOGGED
	for zone_id in zones:
		_fog_states[zone_id] = FogState.FOGGED

	# 找到出生点区域，设为EXPLORED
	for zone_id in zones:
		var zone = zones[zone_id]
		if zone.has_method("get") and zone.get("type") != null:
			# 检查是否是SPAWN类型（类型值为0）
			if zone.type == 0:  # MapZone.ZoneType.SPAWN
				_fog_states[zone_id] = FogState.EXPLORED
				_reveal_adjacent_zones(zone_id)
				break

# ============================================================
# 进入区域
# ============================================================

## 玩家进入区域时调用
func enter_zone(zone_id: String) -> void:
	if zone_id not in _fog_states:
		return

	var old_state = _fog_states[zone_id]
	_fog_states[zone_id] = FogState.EXPLORED

	if old_state != FogState.EXPLORED:
		fog_updated.emit(zone_id, FogState.EXPLORED)

	# 揭开相邻区域
	_reveal_adjacent_zones(zone_id)

## 揭开指定区域的所有相邻区域
func _reveal_adjacent_zones(zone_id: String) -> void:
	if zone_id not in _zones:
		return

	var zone = _zones[zone_id]
	if not zone.has_method("get"):
		return

	var zone_center: Vector2 = zone.get("center")
	var zone_radius: float = zone.get("radius")

	# 检查所有区域，找出距离较近的
	for other_id in _zones:
		if other_id == zone_id:
			continue
		if other_id not in _fog_states:
			continue

		var other_zone = _zones[other_id]
		if not other_zone.has_method("get"):
			continue

		var other_center: Vector2 = other_zone.get("center")
		var other_radius: float = other_zone.get("radius")
		var dist = zone_center.distance_to(other_center)

		# 距离小于两个区域半径之和的视为相邻
		if dist < (zone_radius + other_radius) * 2.5:
			if _fog_states[other_id] == FogState.FOGGED:
				_fog_states[other_id] = FogState.REVEALED
				fog_updated.emit(other_id, FogState.REVEALED)

# ============================================================
# 查询
# ============================================================

## 获取区域的迷雾状态
func get_fog_state(zone_id: String) -> FogState:
	return _fog_states.get(zone_id, FogState.FOGGED)

## 区域是否已探索
func is_explored(zone_id: String) -> bool:
	return get_fog_state(zone_id) == FogState.EXPLORED

## 区域是否已发现（已揭示）
func is_revealed(zone_id: String) -> bool:
	return get_fog_state(zone_id) >= FogState.REVEALED

## 获取所有迷雾状态（用于渲染小地图）
func get_all_fog_states() -> Dictionary:
	var result: Dictionary = {}
	for zone_id in _fog_states:
		match _fog_states[zone_id]:
			FogState.EXPLORED:
				result[zone_id] = "explored"
			FogState.REVEALED:
				result[zone_id] = "revealed"
			FogState.FOGGED:
				result[zone_id] = "fogged"
	return result

## 获取已探索区域数量
func get_explored_count() -> int:
	var count = 0
	for zone_id in _fog_states:
		if _fog_states[zone_id] == FogState.EXPLORED:
			count += 1
	return count

## 获取已发现区域数量（包括已探索）
func get_revealed_count() -> int:
	var count = 0
	for zone_id in _fog_states:
		if _fog_states[zone_id] >= FogState.REVEALED:
			count += 1
	return count

## 获取总区域数
func get_total_count() -> int:
	return _fog_states.size()

## 强制揭开所有迷雾（调试用）
func reveal_all() -> void:
	for zone_id in _fog_states:
		_fog_states[zone_id] = FogState.EXPLORED
	for zone_id in _fog_states:
		fog_updated.emit(zone_id, FogState.EXPLORED)
