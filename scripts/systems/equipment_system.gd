## 装备系统 - 自动加载单例
## 管理装备穿戴、卸下、属性汇总、套装效果
extends Node

# 五个装备槽
enum Slot { WEAPON, ARMOR, HELMET, ACCESSORY_1, ACCESSORY_2 }

const SLOT_NAMES = ["weapon", "armor", "helmet", "accessory", "accessory"]

# 已装备的物品 {Slot: EquipmentData or null}
var equipped: Dictionary = {}

# 套装数据引用
var _SetBonusData = preload("res://scripts/systems/set_bonus_data.gd")

# 当前激活的套装效果缓存
var _active_set_effects: Dictionary = {}

signal equipment_changed(slot: int)
signal set_bonus_changed(set_id: String, piece_count: int)

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

## 汇总所有装备的最终属性（包含套装加成）
func get_total_stats() -> Dictionary:
	var totals = {
		"attack": 0,
		"defense": 0,
		"health": 0,
		"crit_rate": 0.0,
		"crit_damage": 0.0,
		"dodge_rate": 0.0,
	}
	# 先计算装备基础属性
	for slot in equipped:
		var item = equipped[slot]
		if item == null:
			continue
		var stats = item.get_final_stats()
		for key in stats:
			if totals.has(key):
				totals[key] += stats[key]
	# 再应用套装效果
	var set_effects = get_active_set_effects()
	for set_id in set_effects:
		var effect = set_effects[set_id]
		var stats_bonus = effect.get("stats", {})
		if stats_bonus.has("attack_percent"):
			totals["attack"] = int(totals["attack"] * (1.0 + stats_bonus["attack_percent"]))
		if stats_bonus.has("defense_percent"):
			totals["defense"] = int(totals["defense"] * (1.0 + stats_bonus["defense_percent"]))
		if stats_bonus.has("health_percent"):
			totals["health"] = int(totals["health"] * (1.0 + stats_bonus["health_percent"]))
		if stats_bonus.has("crit_rate"):
			totals["crit_rate"] += stats_bonus["crit_rate"]
		if stats_bonus.has("all_percent"):
			totals["attack"] = int(totals["attack"] * (1.0 + stats_bonus["all_percent"]))
			totals["defense"] = int(totals["defense"] * (1.0 + stats_bonus["all_percent"]))
			totals["health"] = int(totals["health"] * (1.0 + stats_bonus["all_percent"]))
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

## 获取当前装备的套装组成 {set_id: [装备ID列表]}
func get_equipped_set_pieces() -> Dictionary:
	var set_pieces: Dictionary = {}
	for slot in equipped:
		var item = equipped[slot]
		if item == null:
			continue
		var set_id = _SetBonusData.get_set_for_piece(item.id)
		if set_id != "":
			if not set_pieces.has(set_id):
				set_pieces[set_id] = []
			set_pieces[set_id].append(item.id)
	return set_pieces

## 获取当前激活的套装效果 {set_id: effect_dict}
func get_active_set_effects() -> Dictionary:
	var result: Dictionary = {}
	var set_pieces = get_equipped_set_pieces()
	for set_id in set_pieces:
		var piece_count = set_pieces[set_id].size()
		# 获取最高件数的套装效果
		var best_effect: Dictionary = {}
		var best_count = 0
		for count in [3, 2]:
			if piece_count >= count:
				var effect = _SetBonusData.get_set_effect(set_id, count)
				if not effect.is_empty():
					best_effect = effect
					best_count = count
					break
		if not best_effect.is_empty():
			result[set_id] = best_effect
			# 检查套装效果是否变化
			if not _active_set_effects.has(set_id) or _active_set_effects[set_id] != best_effect:
				set_bonus_changed.emit(set_id, best_count)
	_active_set_effects = result
	return result

## 获取指定套装的当前件数
func get_set_piece_count(set_id: String) -> int:
	var set_pieces = get_equipped_set_pieces()
	return set_pieces.get(set_id, []).size()

## 检查是否有指定套装效果激活
func has_set_bonus(set_id: String, min_pieces: int = 2) -> bool:
	return get_set_piece_count(set_id) >= min_pieces

## 获取套装的on_hit效果（用于战斗系统调用）
func get_set_on_hit_effects() -> Array:
	var effects: Array = []
	var active_sets = get_active_set_effects()
	for set_id in active_sets:
		var effect = active_sets[set_id]
		if effect.has("on_hit_effect"):
			effects.append(effect["on_hit_effect"])
	return effects

## 获取套装的经验和资源加成
func get_set_passive_bonuses() -> Dictionary:
	var bonuses = {"exp_bonus": 0.0, "resource_bonus": 0.0}
	var active_sets = get_active_set_effects()
	for set_id in active_sets:
		var effect = active_sets[set_id]
		if effect.has("passive_effect"):
			var passive = effect["passive_effect"]
			bonuses["exp_bonus"] += passive.get("exp_bonus", 0.0)
			bonuses["resource_bonus"] += passive.get("resource_bonus", 0.0)
	return bonuses

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
