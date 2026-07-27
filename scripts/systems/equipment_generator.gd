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

# 被动效果池
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

# 触发效果池
const TRIGGER_EFFECTS = [
	{"name": "嗜血", "type": "trigger", "trigger": "on_crit", "effect": "heal_percent", "value": 0.05, "cooldown": 10, "description": "暴击时回复5%生命值"},
	{"name": "坚韧", "type": "trigger", "trigger": "on_low_hp", "threshold": 0.30, "effect": "defense_buff", "value": 0.30, "duration": 30, "description": "生命低于30%时防御+30%"},
	{"name": "狂暴", "type": "trigger", "trigger": "on_low_hp", "threshold": 0.30, "effect": "attack_buff", "value": 0.30, "duration": 30, "description": "生命低于30%时攻击+30%"},
	{"name": "连击", "type": "trigger", "trigger": "on_attack", "effect": "double_attack", "chance": 0.15, "description": "15%概率触发二次攻击"},
	{"name": "反击", "type": "trigger", "trigger": "on_hit", "effect": "counter_attack", "chance": 0.20, "damage_percent": 0.50, "cooldown": 5, "description": "20%概率反击，造成50%攻击伤害"},
	{"name": "吸血", "type": "trigger", "trigger": "on_attack", "effect": "lifesteal", "value": 0.03, "description": "回复3%造成伤害"},
	{"name": "破甲", "type": "trigger", "trigger": "on_attack", "effect": "armor_break", "chance": 0.10, "value": 0.20, "duration": 5, "description": "10%概率降低目标防御20%"},
	{"name": "致盲", "type": "trigger", "trigger": "on_attack", "effect": "blind", "chance": 0.08, "value": 0.20, "duration": 5, "description": "8%概率降低目标攻击20%"},
	{"name": "冰冻", "type": "trigger", "trigger": "on_attack", "effect": "freeze", "chance": 0.05, "duration": 1, "cooldown": 15, "description": "5%概率冻结目标1秒"},
	{"name": "灼烧", "type": "trigger", "trigger": "on_attack", "effect": "burn", "chance": 0.12, "damage_percent": 0.20, "duration": 3, "description": "12%概率灼烧目标，每秒造成20%攻击伤害"},
]

# 每个稀有度最多效果数（被动+触发）
const MAX_PASSIVE_EFFECTS = [0, 1, 1, 2, 2]
const MAX_TRIGGER_EFFECTS = [0, 0, 1, 1, 2]

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

	# 随机被动效果
	var effects: Array = []
	var max_passive: int = MAX_PASSIVE_EFFECTS[rarity_index]
	if max_passive > 0:
		var pool = PASSIVE_EFFECTS.duplicate()
		pool.shuffle()
		var count = randi_range(1, max_passive)
		for i in range(min(count, pool.size())):
			var fx = pool[i].duplicate()
			fx["value"] = snappedf(randf_range(fx["range"][0], fx["range"][1]), 0.01)
			fx.erase("range")
			effects.append(fx)

	# 随机触发效果
	var max_trigger: int = MAX_TRIGGER_EFFECTS[rarity_index]
	if max_trigger > 0:
		var trigger_pool = TRIGGER_EFFECTS.duplicate()
		trigger_pool.shuffle()
		var trigger_count = randi_range(1, max_trigger)
		for i in range(min(trigger_count, trigger_pool.size())):
			var fx = trigger_pool[i].duplicate()
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
