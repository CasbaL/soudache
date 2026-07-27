## 传送阵系统 - 自动加载单例
## 管理传送点解锁、传送功能
extends Node

# 传送点定义
const TELEPORT_POINTS: Dictionary = {
	"layer1_entrance": {
		"name": "幽竹林入口",
		"description": "第1层入口",
		"unlock_level": 1,
		"layer": 1,
		"position": Vector2(0, 0),
	},
	"layer1_extract": {
		"name": "幽竹林撤离点",
		"description": "第1层撤离点",
		"unlock_level": 2,
		"layer": 1,
		"position": Vector2(500, 500),
	},
	"layer2_entrance": {
		"name": "火焰山入口",
		"description": "第2层入口",
		"unlock_level": 3,
		"layer": 2,
		"position": Vector2(0, 0),
	},
	"layer2_extract": {
		"name": "火焰山撤离点",
		"description": "第2层撤离点",
		"unlock_level": 4,
		"layer": 2,
		"position": Vector2(500, 500),
	},
	"layer3_entrance": {
		"name": "天机阁入口",
		"description": "第3层入口",
		"unlock_level": 5,
		"layer": 3,
		"position": Vector2(0, 0),
	},
}

# 已解锁的传送点
var unlocked_points: Dictionary = {}

signal teleport_point_unlocked(point_id: String)
signal teleport_success(point_id: String)
signal teleport_failed(point_id: String, reason: String)

func _ready() -> void:
	pass

## 获取传送阵等级
func get_portal_level() -> int:
	return BuildingSystem.get_building_level("portal")

## 获取已解锁的传送点列表
func get_unlocked_points() -> Array:
	var result: Array = []
	for point_id in unlocked_points:
		result.append(point_id)
	return result

## 检查传送点是否已解锁
func is_unlocked(point_id: String) -> bool:
	return unlocked_points.has(point_id)

## 检查传送点是否可解锁
func can_unlock(point_id: String) -> bool:
	if is_unlocked(point_id):
		return false
	var point = TELEPORT_POINTS.get(point_id, {})
	if point.is_empty():
		return false
	var level = get_portal_level()
	return point.get("unlock_level", 1) <= level

## 解锁传送点
func unlock_point(point_id: String) -> bool:
	if not can_unlock(point_id):
		return false
	var point = TELEPORT_POINTS.get(point_id, {})
	unlocked_points[point_id] = {
		"unlocked_at": Time.get_unix_time_from_system(),
	}
	teleport_point_unlocked.emit(point_id)
	return true

## 获取传送点数据
func get_point_data(point_id: String) -> Dictionary:
	return TELEPORT_POINTS.get(point_id, {})

## 检查是否可以传送到指定点
func can_teleport(point_id: String) -> bool:
	if not is_unlocked(point_id):
		return false
	# 检查是否已经在目标层
	var point = TELEPORT_POINTS.get(point_id, {})
	var target_layer = point.get("layer", 1)
	if GameManager.current_layer == target_layer:
		return false
	return true

## 执行传送
func teleport(point_id: String) -> bool:
	if not can_teleport(point_id):
		if not is_unlocked(point_id):
			teleport_failed.emit(point_id, "传送点未解锁")
		else:
			teleport_failed.emit(point_id, "已在当前层级")
		return false
	var point = TELEPORT_POINTS.get(point_id, {})
	var target_layer = point.get("layer", 1)
	# 更新游戏层级
	GameManager.current_layer = target_layer
	# 这里可以添加传送特效、加载场景等逻辑
	teleport_success.emit(point_id)
	return true

## 获取所有传送点（包括未解锁的）
func get_all_points() -> Dictionary:
	return TELEPORT_POINTS.duplicate()

## 获取指定层级的传送点
func get_layer_points(layer: int) -> Array:
	var result: Array = []
	for point_id in TELEPORT_POINTS:
		if TELEPORT_POINTS[point_id].get("layer", 0) == layer:
			result.append(point_id)
	return result

## 自动解锁符合条件的传送点
func auto_unlock_points() -> Array:
	var newly_unlocked: Array = []
	var level = get_portal_level()
	for point_id in TELEPORT_POINTS:
		if not is_unlocked(point_id):
			var point = TELEPORT_POINTS[point_id]
			if point.get("unlock_level", 1) <= level:
				unlock_point(point_id)
				newly_unlocked.append(point_id)
	return newly_unlocked

## 序列化
func serialize() -> Dictionary:
	return {
		"unlocked": unlocked_points.duplicate(true),
	}

## 反序列化
func deserialize(data: Dictionary) -> void:
	unlocked_points = data.get("unlocked", {}).duplicate(true)
