## 装备随机生成器
## 根据稀有度随机生成装备实例
class_name EquipmentGenerator
extends RefCounted

# 基础属性范围表 {rarity_index: {stat: [min, max]}}
const WEAPON_RANGES = {
	0: {"attack": [30, 50],   "crit_rate": [0.0, 0.03], "crit_damage": [0.0, 0.10]},
	1: {"attack": [60, 100],  "crit_rate": [0.03, 0.06], "crit_damage": [0.10, 0.20]},
	2: {"attack": [120, 180], "crit_rate": [0.06, 0.10], "crit_damage": [0.20, 0.35]},
	3: {"attack": [200, 300], "crit_rate": [0.10, 0.15], "crit_damage": [0.35, 0.50]},
	4: {"attack": [350, 500], "crit_rate": [0.15, 0.20], "crit_damage": [0.50, 0.80]},
}

const ARMOR_RANGES = {
	0: {"defense": [20, 35],   "health": [50, 100],  "dodge_rate": [0.0, 0.02]},
	1: {"defense": [45, 70],   "health": [120, 200], "dodge_rate": [0.02, 0.04]},
	2: {"defense": [80, 120],  "health": [250, 400], "dodge_rate": [0.04, 0.07]},
	3: {"defense": [140, 200], "health": [450, 700], "dodge_rate": [0.07, 0.10]},
	4: {"defense": [230, 350], "health": [800, 1200], "dodge_rate": [0.10, 0.15]},
}

const HELMET_RANGES = {
	0: {"health": [80, 120],   "defense": [10, 20]},
	1: {"health": [150, 250],  "defense": [25, 40]},
	2: {"health": [300, 450],  "defense": [50, 75]},
	3: {"health": [500, 750],  "defense": [85, 125]},
	4: {"health": [900, 1350], "defense": [140, 210]},
}

const ACCESSORY_RANGES = {
	0: {"health": [30, 60]},
	1: {"health": [70, 120]},
	2: {"health": [140, 220]},
	3: {"health": [250, 380]},
	4: {"health": [420, 630]},
}

# 效果池
const PASSIVE_EFFECTS = [
	{"name": "攻击强化", "type": "passive", "stat": "attack_pct",  "range": [0.05, 0.25]},
	{"name": "防御强化", "type": "passive", "stat": "defense_pct", "range": [0.05, 0.25]},
	{"name": "生命强化", "type": "passive", "stat": "health_pct",  "range": [0.05, 0.25]},
	{"name": "暴击强化", "type": "passive", "stat": "crit_pct",    "range": [0.03, 0.15]},
	{"name": "闪避强化", "type": "passive", "stat": "dodge_pct",   "range": [0.03, 0.15]},
	{"name": "移速强化", "type": "passive", "stat": "speed_pct",   "range": [0.05, 0.15]},
	{"name": "技能强化", "type": "passive", "stat": "skill_pct",   "range": [0.05, 0.20]},
	{"name": "冷却缩减", "type": "passive", "stat": "cdr_pct",     "range": [0.05, 0.15]},
]

# 每个稀有度最多效果数
const MAX_EFFECTS = [0, 1, 2, 2, 3]

# 武器名称模板
const WEAPON_NAMES = ["青钢剑", "灵铁剑", "宝铁剑", "仙铁剑", "神铁剑"]
const ARMOR_NAMES = ["布衣", "灵纹甲", "宝纹甲", "仙纹甲", "神纹甲"]
const HELMET_NAMES = ["布帽", "灵纹冠", "宝纹冠", "仙纹冠", "神纹冠"]
const ACCESSORY_NAMES = ["灵石戒指", "灵力项链", "宝力项链", "仙力项链", "神力项链"]

## 生成一件随机装备
## rarity_index: 0=白 1=绿 2=蓝 3=紫 4=金
## type_override: "weapon"/"armor"/"helmet"/"accessory"，为空则随机
static func generate_equipment(rarity_index: int = 0, type_override: String = ""):
	rarity_index = clampi(rarity_index, 0, 4)

	# 选择类型
	var equip_type: String
	if type_override != "":
		equip_type = type_override
	else:
		var types = ["weapon", "armor", "helmet", "accessory"]
		equip_type = types[randi() % types.size()]

	# 根据类型选范围表
	var ranges: Dictionary
	var names: Array
	match equip_type:
		"weapon":
			ranges = WEAPON_RANGES[rarity_index]
			names = WEAPON_NAMES
		"armor":
			ranges = ARMOR_RANGES[rarity_index]
			names = ARMOR_NAMES
		"helmet":
			ranges = HELMET_RANGES[rarity_index]
			names = HELMET_NAMES
		"accessory":
			ranges = ACCESSORY_RANGES[rarity_index]
			names = ACCESSORY_NAMES
		_:
			ranges = WEAPON_RANGES[rarity_index]
			names = WEAPON_NAMES

	# 生成 ID
	var uid = "equip_%d_%d" % [Time.get_ticks_msec(), randi() % 10000]

	# 随机基础属性
	var base_stats: Dictionary = {}
	for stat_key in ranges:
		var range_arr: Array = ranges[stat_key]
		var min_val: float = range_arr[0]
		var max_val: float = range_arr[1]
		if stat_key in ["crit_rate", "crit_damage", "dodge_rate"]:
			base_stats[stat_key] = snappedf(randf_range(min_val, max_val), 0.001)
		else:
			base_stats[stat_key] = randi_range(int(min_val), int(max_val))

	# 随机效果
	var effects: Array = []
	var max_fx: int = MAX_EFFECTS[rarity_index]
	if max_fx > 0:
		var pool = PASSIVE_EFFECTS.duplicate()
		pool.shuffle()
		var count = randi_range(1, max_fx)
		for i in range(min(count, pool.size())):
			var fx = pool[i].duplicate()
			fx["value"] = snappedf(randf_range(fx["range"][0], fx["range"][1]), 0.01)
			fx.erase("range")
			effects.append(fx)

	# 构建数据
	var rarity_names = ["white", "green", "blue", "purple", "gold"]
	var rarity_str = rarity_names[clampi(rarity_index, 0, 4)]
	var data = {
		"id": uid,
		"name": names[rarity_index],
		"type": equip_type,
		"rarity": rarity_str,
	}
	# 合并 base_stats 到顶层
	for key in base_stats:
		data[key] = base_stats[key]
	data["effects"] = effects

	return load("res://scripts/systems/equipment_data.gd").new(data)
