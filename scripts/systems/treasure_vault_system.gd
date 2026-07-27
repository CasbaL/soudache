## 宝库系统 - 自动加载单例
## 存放珍稀物品，减少撤离损失
extends Node

# 宝库配置（根据宝库等级）
const VAULT_CONFIG: Dictionary = {
	1: {"slots": 3, "protection_rate": 0.0},
	2: {"slots": 5, "protection_rate": 0.20},
	3: {"slots": 8, "protection_rate": 0.40},
	4: {"slots": 12, "protection_rate": 0.60},
	5: {"slots": 20, "protection_rate": 0.80},
}

# 珍稀物品类型（可以存入宝库的物品）
const VALUABLE_TYPES = ["blueprint", "rare_material", "divine_equipment", "set_equipment"]

# 宝库存储的物品 { slot_index: item_data }
var vault_items: Dictionary = {}

signal item_stored(slot: int, item: Dictionary)
signal item_withdrawn(slot: int, item: Dictionary)
signal vault_updated()

func _ready() -> void:
	pass

## 获取宝库等级
func get_vault_level() -> int:
	return BuildingSystem.get_building_level("treasure_vault")

## 获取宝库配置
func get_vault_config() -> Dictionary:
	var level = get_vault_level()
	return VAULT_CONFIG.get(level, VAULT_CONFIG[1])

## 获取宝库槽位数
func get_max_slots() -> int:
	var config = get_vault_config()
	return config.get("slots", 3)

## 获取保护率（减少撤离损失的比例）
func get_protection_rate() -> float:
	var config = get_vault_config()
	return config.get("protection_rate", 0.0)

## 检查物品是否可以存入宝库
func can_store_item(item: Dictionary) -> bool:
	var item_type = item.get("type", "")
	var rarity = item.get("rarity", "white")
	# 珍稀物品可以存入
	if item_type in VALUABLE_TYPES:
		return true
	# 高稀有度装备可以存入
	if item_type in ["weapon", "armor", "helmet", "accessory"] and rarity in ["purple", "gold"]:
		return true
	# 套装装备可以存入
	if item.get("set_id", "") != "":
		return true
	return false

## 获取空闲槽位
func _get_empty_slot() -> int:
	var max_slots = get_max_slots()
	for i in range(max_slots):
		if not vault_items.has(i):
			return i
	return -1

## 存入物品
func store_item(item: Dictionary) -> bool:
	if not can_store_item(item):
		return false
	var slot = _get_empty_slot()
	if slot < 0:
		return false
	vault_items[slot] = item.duplicate(true)
	item_stored.emit(slot, item)
	vault_updated.emit()
	return true

## 取出物品
func withdraw_item(slot: int) -> Dictionary:
	if not vault_items.has(slot):
		return {}
	var item = vault_items[slot]
	vault_items.erase(slot)
	item_withdrawn.emit(slot, item)
	vault_updated.emit()
	return item

## 获取宝库物品列表
func get_vault_items() -> Dictionary:
	return vault_items.duplicate(true)

## 获取宝库物品数量
func get_item_count() -> int:
	return vault_items.size()

## 计算撤离损失后的物品（根据保护率）
func calculate_extraction_loss(items: Array) -> Dictionary:
	var protection_rate = get_protection_rate()
	var kept_items: Array = []
	var lost_items: Array = []
	for item in items:
		var roll = randf()
		if roll < protection_rate:
			kept_items.append(item)
		else:
			lost_items.append(item)
	return {
		"kept": kept_items,
		"lost": lost_items,
		"protection_rate": protection_rate,
	}

## 撤离时处理宝库物品（宝库物品不受损失）
func process_extraction() -> Dictionary:
	# 宝库物品完全保护，不受撤离损失
	return {
		"vault_items": vault_items.duplicate(true),
		"vault_protected": true,
	}

## 序列化
func serialize() -> Dictionary:
	return {
		"items": vault_items.duplicate(true),
	}

## 反序列化
func deserialize(data: Dictionary) -> void:
	vault_items = data.get("items", {}).duplicate(true)
