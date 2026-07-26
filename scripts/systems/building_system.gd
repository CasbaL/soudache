## 建筑系统 - 自动加载单例
## 管理 9 栋建筑的等级、升级、效率加成
extends Node

# 建筑ID常量
const ALL_BUILDINGS = [
	"alchemy_furnace", "forge", "training_room",
	"library", "farm", "warehouse",
	"portal", "shop", "treasure_vault",
]
const MAX_LEVEL = 5

# 当前建筑等级 { building_id: level }
var building_levels: Dictionary = {}

signal building_upgraded(building_id: String, new_level: int)
signal resources_changed()

func _ready() -> void:
	_init_building_levels()

func _init_building_levels() -> void:
	for id in ALL_BUILDINGS:
		if not building_levels.has(id):
			building_levels[id] = 1

func get_building_level(building_id: String) -> int:
	return building_levels.get(building_id, 1)

func get_building_bonus(building_id: String) -> float:
	var level = get_building_level(building_id)
	return 1.0 + (level - 1) * 0.2  # +20% per level

func is_max_level(building_id: String) -> bool:
	return get_building_level(building_id) >= MAX_LEVEL

func can_upgrade(building_id: String) -> bool:
	if is_max_level(building_id):
		return false
	var cost = get_upgrade_cost(building_id)
	return _has_enough_resources(cost)

## 升级建筑，成功返回 true
func upgrade_building(building_id: String) -> bool:
	if is_max_level(building_id):
		return false
	var current_level = get_building_level(building_id)
	var target_level = current_level + 1
	var cost = _get_upgrade_cost_for_level(building_id, target_level)
	if not _has_enough_resources(cost):
		return false
	_consume_resources(cost)
	building_levels[building_id] = target_level
	building_upgraded.emit(building_id, target_level)
	resources_changed.emit()
	return true

func get_upgrade_cost(building_id: String) -> Dictionary:
	if is_max_level(building_id):
		return {}
	var current_level = get_building_level(building_id)
	return _get_upgrade_cost_for_level(building_id, current_level + 1)

## 升级消耗表
func _get_upgrade_cost_for_level(_building_id: String, level: int) -> Dictionary:
	match level:
		2: return {"spirit_stone": 800, "ore": 30}
		3: return {"spirit_stone": 1500, "herb": 60}
		4: return {"spirit_stone": 3000, "artifact_spirit": 5}
		5: return {"spirit_stone": 6000, "artifact_spirit": 10}
		_: return {"spirit_stone": 300}

func serialize() -> Dictionary:
	return building_levels.duplicate()

func deserialize(data: Dictionary) -> void:
	building_levels.clear()
	for id in ALL_BUILDINGS:
		building_levels[id] = data.get(id, 1)
	_init_building_levels()

# --- Resource helpers (reads/writes GameManager.storage) ---

func _get_resource_amount(resource_id: String) -> int:
	return GameManager.storage.get(resource_id, 0)

func _has_enough_resources(cost: Dictionary) -> bool:
	for resource_id in cost:
		if _get_resource_amount(resource_id) < cost[resource_id]:
			return false
	return true

func _consume_resources(cost: Dictionary) -> void:
	for resource_id in cost:
		GameManager.storage[resource_id] = _get_resource_amount(resource_id) - cost[resource_id]
