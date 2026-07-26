## 装备强化系统 - 自动加载单例
## 处理强化逻辑：成功率、降级、材料消耗
extends Node

# 成功率表（index = 强化等级，从 +1 开始）
const SUCCESS_RATES = [
	1.00,  # +1
	0.95,  # +2
	0.90,  # +3
	0.80,  # +4
	0.70,  # +5
	0.60,  # +6
	0.50,  # +7
	0.40,  # +8
	0.30,  # +9
	0.20,  # +10
	0.15,  # +11
	0.10,  # +12
	0.08,  # +13
	0.05,  # +14
	0.03,  # +15
]

# 失败降级表（index = 强化等级，从 +1 开始；值 = 降级数，-1 表示归零）
const FAIL_PENALTY = [
	0, 0, 0,   # +1~+3 无惩罚
	1, 1,      # +4~+5 降1
	2, 2,      # +6~+7 降2
	3, 3,      # +8~+9 降3
	-1, -1, -1, -1, -1, -1  # +10~+15 归零
]

# 材料消耗表 {level: {ling_shi, qi_ling}}
const MATERIAL_COST = {
	0:  {"ling_shi": 100,  "qi_ling": 1},
	1:  {"ling_shi": 150,  "qi_ling": 1},
	2:  {"ling_shi": 200,  "qi_ling": 2},
	3:  {"ling_shi": 300,  "qi_ling": 2},
	4:  {"ling_shi": 400,  "qi_ling": 3},
	5:  {"ling_shi": 500,  "qi_ling": 3},
	6:  {"ling_shi": 700,  "qi_ling": 4},
	7:  {"ling_shi": 1000, "qi_ling": 5},
	8:  {"ling_shi": 1500, "qi_ling": 6},
	9:  {"ling_shi": 2000, "qi_ling": 8},
	10: {"ling_shi": 3000, "qi_ling": 10},
	11: {"ling_shi": 4000, "qi_ling": 12},
	12: {"ling_shi": 5000, "qi_ling": 15},
	13: {"ling_shi": 7000, "qi_ling": 18},
	14: {"ling_shi": 10000, "qi_ling": 20},
}

signal enhance_result(success: bool, new_level: int)

## 获取当前等级的强化成功率
func get_success_rate(level: int) -> float:
	if level < 0 or level >= SUCCESS_RATES.size():
		return 0.0
	return SUCCESS_RATES[level]

## 获取当前等级的材料消耗
func get_material_cost(level: int) -> Dictionary:
	return MATERIAL_COST.get(level, {"ling_shi": 99999, "qi_ling": 99})

## 尝试强化一件装备
## 返回 {success, new_level, old_level}
func enhance_equipment(equipment) -> Dictionary:
	var old_level = equipment.enhance_level
	if old_level >= SUCCESS_RATES.size():
		return {"success": false, "new_level": old_level, "old_level": old_level}

	var rate = SUCCESS_RATES[old_level]
	var roll = randf()
	var success = roll < rate

	if success:
		equipment.enhance_level += 1
		enhance_result.emit(true, equipment.enhance_level)
		return {"success": true, "new_level": equipment.enhance_level, "old_level": old_level}
	else:
		var penalty = FAIL_PENALTY[old_level]
		var new_level: int
		if penalty == -1:
			new_level = 0
		else:
			new_level = max(0, old_level - penalty)
		equipment.enhance_level = new_level
		enhance_result.emit(false, new_level)
		return {"success": false, "new_level": new_level, "old_level": old_level}
