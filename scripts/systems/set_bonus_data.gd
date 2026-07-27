## 套装数据定义
## 定义所有套装的组成和效果
class_name SetBonusData
extends RefCounted

# 套装ID常量
const SET_BAMBOO = "bamboo_shadow"      # 竹影套 - 第1层
const SET_FLAME = "flame_blaze"         # 烈焰套 - 第2层
const SET_TIANJI = "tianji_mechanism"   # 天机套 - 第3层
const SET_SPIRIT = "spirit_rhythm"      # 灵韵套 - 通用

# 套装数据定义
# structure: {
#   "set_id": {
#     "name": 套装名称,
#     "description": 描述,
#     "pieces": [装备ID列表],
#     "effects": {
#       2: {2件套效果},
#       3: {3件套效果}
#     }
#   }
# }
const SET_DATA: Dictionary = {
	SET_BAMBOO: {
		"name": "竹影套",
		"description": "幽竹林Boss掉落，适合剑修",
		"pieces": ["bamboo_sword", "bamboo_armor", "bamboo_helmet"],
		"effects": {
			2: {
				"name": "竹影双件",
				"description": "攻击力+10%，生命值+10%",
				"stats": {"attack_percent": 0.10, "health_percent": 0.10}
			},
			3: {
				"name": "竹影三件",
				"description": "剑气斩伤害+30%，冷却-20%",
				"skill_bonus": {"skill_id": "sword_qi_slash", "damage_bonus": 0.30, "cooldown_reduction": 0.20}
			}
		}
	},
	SET_FLAME: {
		"name": "烈焰套",
		"description": "火焰山Boss掉落，适合剑修和符修",
		"pieces": ["flame_sword", "flame_armor", "flame_helmet"],
		"effects": {
			2: {
				"name": "烈焰双件",
				"description": "攻击力+15%，暴击率+5%",
				"stats": {"attack_percent": 0.15, "crit_rate": 0.05}
			},
			3: {
				"name": "烈焰三件",
				"description": "攻击时20%概率灼烧目标，每秒造成30%攻击伤害，持续4秒",
				"on_hit_effect": {"type": "burn", "chance": 0.20, "damage_percent": 0.30, "duration": 4.0}
			}
		}
	},
	SET_TIANJI: {
		"name": "天机套",
		"description": "天机阁Boss掉落，适合丹修",
		"pieces": ["tianji_weapon", "tianji_armor", "tianji_helmet"],
		"effects": {
			2: {
				"name": "天机双件",
				"description": "防御力+20%，生命值+15%",
				"stats": {"defense_percent": 0.20, "health_percent": 0.15}
			},
			3: {
				"name": "天机三件",
				"description": "受击时25%概率触发护盾，吸收20%最大生命值伤害，持续10秒",
				"on_hit_effect": {"type": "shield", "chance": 0.25, "shield_percent": 0.20, "duration": 10.0}
			}
		}
	},
	SET_SPIRIT: {
		"name": "灵韵套",
		"description": "通用套装，所有层级随机掉落",
		"pieces": ["spirit_weapon", "spirit_armor", "spirit_helmet"],
		"effects": {
			2: {
				"name": "灵韵双件",
				"description": "所有属性+5%",
				"stats": {"all_percent": 0.05}
			},
			3: {
				"name": "灵韵三件",
				"description": "经验获取+20%，资源获取+15%",
				"passive_effect": {"exp_bonus": 0.20, "resource_bonus": 0.15}
			}
		}
	}
}

# Boss掉落套装映射
const BOSS_SET_DROPS: Dictionary = {
	"bamboo_king": SET_BAMBOO,
	"fire_demon": SET_FLAME,
	"tianji_elder": SET_TIANJI
}

## 获取套装数据
static func get_set_data(set_id: String) -> Dictionary:
	return SET_DATA.get(set_id, {})

## 获取套装名称
static func get_set_name(set_id: String) -> String:
	var data = SET_DATA.get(set_id, {})
	return data.get("name", "")

## 获取套装效果
static func get_set_effect(set_id: String, piece_count: int) -> Dictionary:
	var data = SET_DATA.get(set_id, {})
	var effects = data.get("effects", {})
	return effects.get(piece_count, {})

## 检查装备是否属于某个套装
static func get_set_for_piece(equipment_id: String) -> String:
	for set_id in SET_DATA:
		var pieces = SET_DATA[set_id].get("pieces", [])
		if equipment_id in pieces:
			return set_id
	return ""

## 获取Boss掉落的套装ID
static func get_boss_set(boss_id: String) -> String:
	return BOSS_SET_DROPS.get(boss_id, "")

## 获取所有套装ID列表
static func get_all_set_ids() -> Array:
	return SET_DATA.keys()
