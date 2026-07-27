## 境界系统 - 自动加载单例
## 管理角色境界：炼气 → 筑基 → 金丹 → 元婴 → 化神
## 每个境界给玩家属性加成，修炼室等级限制最大可突破境界
extends Node

# 境界列表（索引 = 境界等级 0-4）
const REALM_NAMES = ["炼气", "筑基", "金丹", "元婴", "化神"]

# 各境界属性加成（累加式，化神总计 +400 攻击）
const REALM_BONUSES = [
	{"attack": 30,  "defense": 15,  "health": 100},   # 炼气
	{"attack": 60,  "defense": 30,  "health": 200},   # 筑基
	{"attack": 100, "defense": 50,  "health": 350},   # 金丹
	{"attack": 150, "defense": 80,  "health": 500},   # 元婴
	{"attack": 200, "defense": 120, "health": 700},   # 化神
]

# 突破消耗
const ADVANCE_COSTS = [
	{},  # 初始炼气不需要消耗
	{"spirit_stone": 500},
	{"spirit_stone": 1500, "herb": 50},
	{"spirit_stone": 4000, "herb": 150, "artifact_spirit": 5},
	{"spirit_stone": 10000, "herb": 400, "artifact_spirit": 15},
]

# 当前境界索引（0 = 炼气）
var current_realm: int = 0

# 突破成功率（根据修炼室等级）
const BREAKTHROUGH_RATES = [0.70, 0.80, 0.85, 0.90, 1.00]

signal realm_changed(new_realm: int)
signal breakthrough_attempted(success: bool, new_realm: int)

func _ready() -> void:
	pass

## 获取当前境界名称
func get_realm_name() -> String:
	return REALM_NAMES[current_realm]

## 获取当前境界等级索引
func get_realm_index() -> int:
	return current_realm

## 获取当前境界属性加成
func get_realm_bonus() -> Dictionary:
	return REALM_BONUSES[current_realm].duplicate()

## 获取累积属性加成（所有已突破境界之和）
func get_total_realm_bonus() -> Dictionary:
	var total = {"attack": 0, "defense": 0, "health": 0}
	for i in range(current_realm + 1):
		for key in REALM_BONUSES[i]:
			total[key] += REALM_BONUSES[i][key]
	return total

## 是否已达到最大境界
func is_max_realm() -> bool:
	return current_realm >= REALM_NAMES.size() - 1

## 获取修炼室等级允许的最大境界索引
func get_max_allowed_realm() -> int:
	var training_level = BuildingSystem.get_building_level("training_room")
	# 修炼室 Lv1→炼气(0), Lv2→筑基(1), ...
	return clampi(training_level - 1, 0, REALM_NAMES.size() - 1)

## 是否可以尝试突破
func can_attempt_breakthrough() -> bool:
	if is_max_realm():
		return false
	var target = current_realm + 1
	if target > get_max_allowed_realm():
		return false
	var cost: Dictionary = ADVANCE_COSTS[target]
	return _has_enough_resources(cost)

## 尝试突破，返回是否成功
func attempt_breakthrough() -> bool:
	if not can_attempt_breakthrough():
		return false
	var target = current_realm + 1
	var cost: Dictionary = ADVANCE_COSTS[target]
	# 消耗资源
	_consume_resources(cost)
	# 成功率
	var training_level = BuildingSystem.get_building_level("training_room")
	var rate: float = BREAKTHROUGH_RATES[clampi(training_level - 1, 0, BREAKTHROUGH_RATES.size() - 1)]
	var success = randf() < rate
	if success:
		current_realm = target
		realm_changed.emit(current_realm)
	breakthrough_attempted.emit(success, current_realm)
	return success

## 获取突破消耗
func get_breakthrough_cost() -> Dictionary:
	if is_max_realm():
		return {}
	return ADVANCE_COSTS[current_realm + 1].duplicate()

## 获取突破成功率
func get_breakthrough_rate() -> float:
	var training_level = BuildingSystem.get_building_level("training_room")
	return BREAKTHROUGH_RATES[clampi(training_level - 1, 0, BREAKTHROUGH_RATES.size() - 1)]

func serialize() -> Dictionary:
	return {"current_realm": current_realm}

func deserialize(data: Dictionary) -> void:
	current_realm = data.get("current_realm", 0)

func _has_enough_resources(cost: Dictionary) -> bool:
	for res_id in cost:
		if GameManager.storage.get(res_id, 0) < cost[res_id]:
			return false
	return true

func _consume_resources(cost: Dictionary) -> void:
	for res_id in cost:
		GameManager.storage[res_id] = GameManager.storage.get(res_id, 0) - cost[res_id]
