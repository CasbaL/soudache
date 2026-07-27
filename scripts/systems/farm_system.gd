## 药园系统 - 自动加载单例
## 管理种植、生长、收获
extends Node

# 作物定义
const CROPS: Dictionary = {
	"herb_seed": {
		"name": "普通灵草",
		"output_id": "herb",
		"output_name": "灵草",
		"output_amount": 3,
		"grow_time": 1800,  # 30分钟
		"seed_cost": 1,
	},
	"quality_herb_seed": {
		"name": "优质灵草",
		"output_id": "herb",
		"output_name": "灵草",
		"output_amount": 8,
		"grow_time": 7200,  # 2小时
		"seed_cost": 1,
	},
	"rare_herb_seed": {
		"name": "稀有灵草",
		"output_id": "herb",
		"output_name": "灵草",
		"output_amount": 20,
		"grow_time": 21600,  # 6小时
		"seed_cost": 1,
	},
	"ore_seed": {
		"name": "普通矿石",
		"output_id": "ore",
		"output_name": "矿石",
		"output_amount": 3,
		"grow_time": 1800,
		"seed_cost": 1,
	},
	"quality_ore_seed": {
		"name": "优质矿石",
		"output_id": "ore",
		"output_name": "矿石",
		"output_amount": 8,
		"grow_time": 7200,
		"seed_cost": 1,
	},
	"rare_ore_seed": {
		"name": "稀有矿石",
		"output_id": "ore",
		"output_name": "矿石",
		"output_amount": 20,
		"grow_time": 21600,
		"seed_cost": 1,
	},
}

# 田地配置（根据灵田等级）
const FARM_SLOTS: Dictionary = {
	1: 1,
	2: 2,
	3: 3,
	4: 4,
	5: 5,
}

# 已种植的作物 { slot_index: { crop_id, output_id, output_amount, planted_at, grow_time, status } }
var planted_crops: Dictionary = {}

signal crop_planted(slot: int, crop_id: String)
signal crop_harvested(slot: int, output_id: String, amount: int)
signal crop_ready(slot: int)

func _ready() -> void:
	# 登录时自动收获成熟作物
	call_deferred("_auto_harvest_on_login")

## 登录时自动收获成熟作物
func _auto_harvest_on_login() -> void:
	var harvested = harvest_all()
	if harvested.size() > 0:
		var total_herb = 0
		var total_ore = 0
		for item in harvested:
			if item.get("output_id", "") == "herb":
				total_herb += item.get("amount", 0)
			elif item.get("output_id", "") == "ore":
				total_ore += item.get("amount", 0)
		if total_herb > 0 or total_ore > 0:
			print("[FarmSystem] 离线收获: 灵草+%d, 矿石+%d" % [total_herb, total_ore])

func _process(_delta: float) -> void:
	var now = Time.get_unix_time_from_system()
	for slot in planted_crops:
		var crop = planted_crops[slot]
		if crop.get("status") == "growing":
			var planted_at = crop.get("planted_at", now)
			var grow_time = crop.get("grow_time", 1800)
			if now >= planted_at + grow_time:
				crop["status"] = "ready"
				crop_ready.emit(slot)

## 获取灵田等级
func get_farm_level() -> int:
	return BuildingSystem.get_building_level("farm")

## 获取最大田地数量
func get_max_slots() -> int:
	var level = get_farm_level()
	return FARM_SLOTS.get(level, 1)

## 获取可用田地数量
func get_available_slots() -> int:
	var max_slots = get_max_slots()
	var used_slots = 0
	for slot in planted_crops:
		if planted_crops[slot].get("status") != "empty":
			used_slots += 1
	return max_slots - used_slots

## 获取作物数据
func get_crop_data(crop_id: String) -> Dictionary:
	return CROPS.get(crop_id, {})

## 检查是否可以种植
func can_plant(crop_id: String) -> bool:
	if not CROPS.has(crop_id):
		return false
	if get_available_slots() <= 0:
		return false
	var crop = CROPS[crop_id]
	var seed_amount = GameManager.storage.get(crop_id, 0)
	return seed_amount >= crop.get("seed_cost", 1)

## 获取空闲田地索引
func _get_empty_slot() -> int:
	var max_slots = get_max_slots()
	for i in range(max_slots):
		if not planted_crops.has(i) or planted_crops[i].get("status") == "empty":
			return i
	return -1

## 种植作物
func plant_crop(crop_id: String) -> bool:
	if not can_plant(crop_id):
		return false
	var crop = CROPS[crop_id]
	var slot = _get_empty_slot()
	if slot < 0:
		return false
	# 消耗种子
	GameManager.storage[crop_id] = GameManager.storage.get(crop_id, 0) - crop.get("seed_cost", 1)
	# 计算生长时间（受灵田效率加成）
	var bonus = BuildingSystem.get_building_bonus("farm")
	var base_time = crop.get("grow_time", 1800.0)
	var actual_time = base_time / (1.0 + bonus)
	var now = Time.get_unix_time_from_system()
	planted_crops[slot] = {
		"crop_id": crop_id,
		"output_id": crop.get("output_id", ""),
		"output_name": crop.get("output_name", ""),
		"output_amount": crop.get("output_amount", 1),
		"planted_at": now,
		"grow_time": actual_time,
		"status": "growing",
	}
	crop_planted.emit(slot, crop_id)
	return true

## 获取作物生长进度（0.0 ~ 1.0）
func get_growth_progress(slot: int) -> float:
	if not planted_crops.has(slot):
		return 0.0
	var crop = planted_crops[slot]
	if crop.get("status") == "ready":
		return 1.0
	if crop.get("status") != "growing":
		return 0.0
	var now = Time.get_unix_time_from_system()
	var planted_at = crop.get("planted_at", now)
	var grow_time = crop.get("grow_time", 1800)
	var elapsed = now - planted_at
	if grow_time <= 0:
		return 1.0
	return clampf(elapsed / grow_time, 0.0, 1.0)

## 检查作物是否成熟
func is_crop_ready(slot: int) -> bool:
	if not planted_crops.has(slot):
		return false
	return planted_crops[slot].get("status") == "ready"

## 收获作物
func harvest_crop(slot: int) -> Dictionary:
	if not is_crop_ready(slot):
		return {}
	var crop = planted_crops[slot]
	var output_id = crop.get("output_id", "")
	var output_name = crop.get("output_name", "")
	var amount = crop.get("output_amount", 1)
	# 添加到仓库
	GameManager.add_to_storage(output_id, amount)
	# 清空田地
	planted_crops[slot] = {"status": "empty"}
	crop_harvested.emit(slot, output_id, amount)
	return {
		"output_id": output_id,
		"output_name": output_name,
		"amount": amount,
	}

## 收获所有成熟作物
func harvest_all() -> Array:
	var harvested: Array = []
	for slot in planted_crops:
		if is_crop_ready(slot):
			var result = harvest_crop(slot)
			if not result.is_empty():
				harvested.append(result)
	return harvested

## 获取田地状态
func get_slot_status(slot: int) -> Dictionary:
	if not planted_crops.has(slot):
		return {"status": "empty"}
	return planted_crops[slot].duplicate()

## 获取所有田地状态
func get_all_slots_status() -> Dictionary:
	return planted_crops.duplicate(true)

## 序列化
func serialize() -> Dictionary:
	return {
		"crops": planted_crops.duplicate(true),
	}

## 反序列化
func deserialize(data: Dictionary) -> void:
	planted_crops = data.get("crops", {}).duplicate(true)
