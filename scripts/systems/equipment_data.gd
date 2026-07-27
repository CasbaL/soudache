## 装备数据类
## 封装单件装备的所有属性和计算逻辑
class_name EquipmentData
extends RefCounted

enum Rarity { WHITE, GREEN, BLUE, PURPLE, GOLD }

const RARITY_NAMES = ["凡品", "灵品", "宝品", "仙品", "神品"]
const RARITY_COLORS = [
	Color(0.8, 0.8, 0.8),   # 白
	Color(0.2, 0.85, 0.2),  # 绿
	Color(0.3, 0.5, 1.0),   # 蓝
	Color(0.7, 0.3, 0.9),   # 紫
	Color(1.0, 0.85, 0.2),  # 金
]
const RARITY_MULTIPLIERS = [1.0, 1.3, 1.6, 2.0, 2.5]
const ENHANCE_BONUS_PER_LEVEL = 0.05

var id: String = ""
var name: String = ""
var type: String = ""          # weapon / armor / helmet / accessory
var rarity: Rarity = Rarity.WHITE
var set_id: String = ""        # 套装ID，空表示非套装
var enhance_level: int = 0
var base_stats: Dictionary = {}  # attack, defense, health, crit_rate, crit_damage, dodge_rate
var effects: Array = []          # [{type, name, value}]

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "")
	name = data.get("name", "")
	type = data.get("type", "weapon")
	rarity = _str_to_rarity(data.get("rarity", "white"))
	set_id = data.get("set_id", "")
	enhance_level = data.get("enhance_level", 0)
	# Accept both flat keys (attack, defense) and nested baseStats
	base_stats = {}
	for key in ["attack", "defense", "health", "crit_rate", "crit_damage", "dodge_rate"]:
		var val = data.get(key, data.get("baseStats", {}).get(key, 0))
		if val != 0:
			base_stats[key] = val
	# Also support baseAttack / baseDefense / baseHealth / baseCritRate / baseCritDamage keys from equipment.json
	for mapping in [
		["baseAttack", "attack"], ["baseDefense", "defense"], ["baseHealth", "health"],
		["baseCritRate", "crit_rate"], ["baseCritDamage", "crit_damage"],
	]:
		if data.has(mapping[0]):
			base_stats[mapping[1]] = data[mapping[0]]
	effects = data.get("effects", [])

static func _str_to_rarity(s: String) -> Rarity:
	match s.to_lower():
		"white", "凡品": return Rarity.WHITE
		"green", "灵品": return Rarity.GREEN
		"blue", "宝品": return Rarity.BLUE
		"purple", "仙品": return Rarity.PURPLE
		"gold", "神品": return Rarity.GOLD
		_: return Rarity.WHITE

## 稀有度颜色
func get_rarity_color() -> Color:
	return RARITY_COLORS[rarity]

## 稀有度名称
func get_rarity_name() -> String:
	return RARITY_NAMES[rarity]

## 强化加成倍率 (1.0 + level * 5%)
func get_enhance_multiplier() -> float:
	return 1.0 + enhance_level * ENHANCE_BONUS_PER_LEVEL

## 计算最终属性（基础 × 稀有度倍率 × 强化加成）
func get_final_stats() -> Dictionary:
	var mult = RARITY_MULTIPLIERS[rarity] * get_enhance_multiplier()
	var result: Dictionary = {}
	for key in base_stats:
		var base_val = base_stats[key]
		if key in ["crit_rate", "crit_damage", "dodge_rate"]:
			# 百分比属性：加法强化
			result[key] = base_val * mult
		else:
			result[key] = int(base_val * mult)
	return result

## 生成用于保存的字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"rarity": _rarity_to_str(rarity),
		"set_id": set_id,
		"enhance_level": enhance_level,
		"base_stats": base_stats.duplicate(),
		"effects": effects.duplicate(true),
	}

static func _rarity_to_str(r: Rarity) -> String:
	match r:
		Rarity.WHITE: return "white"
		Rarity.GREEN: return "green"
		Rarity.BLUE: return "blue"
		Rarity.PURPLE: return "purple"
		Rarity.GOLD: return "gold"
		_: return "white"

## 检查是否是套装装备
func is_set_piece() -> bool:
	return set_id != ""

## 获取套装名称
func get_set_name() -> String:
	if set_id == "":
		return ""
	var SetBonusData = preload("res://scripts/systems/set_bonus_data.gd")
	return SetBonusData.get_set_name(set_id)
