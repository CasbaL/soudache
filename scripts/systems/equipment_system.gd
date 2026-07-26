## 装备系统 - 自动加载单例
## 管理装备穿戴、卸下、属性汇总
extends Node

# 五个装备槽
enum Slot { WEAPON, ARMOR, HELMET, ACCESSORY_1, ACCESSORY_2 }

const SLOT_NAMES = ["weapon", "armor", "helmet", "accessory", "accessory"]

# 已装备的物品 {Slot: EquipmentData or null}
var equipped: Dictionary = {}

signal equipment_changed(slot: int)

func _ready() -> void:
	for slot in Slot.values():
		equipped[slot] = null

## 装备一件物品到指定槽位，返回被替换的旧装备（可为 null）
func equip_item(item_data, slot: int):
	if slot < 0 or slot > Slot.ACCESSORY_2:
		return null
	# 类型校验
	var expected_type = SLOT_NAMES[slot]
	if item_data.type != expected_type:
		push_warning("装备类型不匹配：期望 %s，实际 %s" % [expected_type, item_data.type])
		return null

	var old = equipped.get(slot)
	equipped[slot] = item_data
	equipment_changed.emit(slot)
	return old

## 卸下指定槽位的装备，返回该装备
func unequip_item(slot: int):
	if slot < 0 or slot > Slot.ACCESSORY_2:
		return null
	var item = equipped.get(slot)
	if item == null:
		return null
	equipped[slot] = null
	equipment_changed.emit(slot)
	return item

## 获取指定槽位的装备
func get_equipped(slot: int):
	return equipped.get(slot)

## 汇总所有装备的最终属性
func get_total_stats() -> Dictionary:
	var totals = {
		"attack": 0,
		"defense": 0,
		"health": 0,
		"crit_rate": 0.0,
		"crit_damage": 0.0,
		"dodge_rate": 0.0,
	}
	for slot in equipped:
		var item = equipped[slot]
		if item == null:
			continue
		var stats = item.get_final_stats()
		for key in stats:
			if totals.has(key):
				totals[key] += stats[key]
	return totals

## 将装备属性加成应用到玩家（由 player.gd 调用）
func apply_stats_to_player(player: Node) -> void:
	var bonus = get_total_stats()
	if "attack_damage" in player:
		player.attack_damage = player.attack_damage + int(bonus.attack)
	if "defense" in player:
		player.defense = player.defense + int(bonus.defense)
	if "max_health" in player:
		player.max_health = player.max_health + int(bonus.health)
	if "crit_rate" in player:
		player.crit_rate = player.crit_rate + bonus.crit_rate

## 序列化所有装备槽（用于存档）
func serialize() -> Dictionary:
	var data = {}
	for slot in equipped:
		var item = equipped[slot]
		if item:
			data[str(slot)] = item.to_dict()
		else:
			data[str(slot)] = null
	return data

## 从存档恢复装备
func deserialize(data: Dictionary) -> void:
	var EquipmentDataScript = preload("res://scripts/systems/equipment_data.gd")
	for slot_str in data:
		var slot = int(slot_str)
		var item_dict = data[slot_str]
		if item_dict == null:
			equipped[slot] = null
		else:
			equipped[slot] = EquipmentDataScript.new(item_dict)
	equipment_changed.emit(-1)  # -1 表示全部刷新
