## 房间模板数据
## 存储各层各类型房间的敌人配置、资源、NPC对话等
## 基于地图设计文档的完整模板
class_name RoomTemplates
extends RefCounted

# ============================================================
# 模板数据结构
# 每个模板 = {
#   id: String,
#   name: String,
#   enemies: Array[Dictionary]  — { enemy_id, count_min, count_max }
#   resources: Array[Dictionary] — { resource_id, name, amount_min, amount_max }
#   has_npc: bool,
#   npc_dialogue: String,
#   difficulty: int (1-5)
# }
# ============================================================

# ──────────────────────────────────────────────
# 第1层：幽竹林
# ──────────────────────────────────────────────

static func get_layer1_combat_templates() -> Array[Dictionary]:
	return [
		{
			"id": "combat_bamboo_ambush",
			"name": "竹林伏击",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 3, "count_max": 4}
			],
			"resources": [
				{"resource_id": "herb", "name": "灵草", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 1
		},
		{
			"id": "combat_river_encounter",
			"name": "溪边遭遇",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 2, "count_max": 2},
				{"enemy_id": "bamboo_archer", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 50, "amount_max": 50}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 1
		},
		{
			"id": "combat_stone_bridge",
			"name": "石桥战斗",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 4, "count_max": 4}
			],
			"resources": [],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 2
		},
		{
			"id": "combat_bamboo_clearing",
			"name": "竹林空地",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 2, "count_max": 2},
				{"enemy_id": "bamboo_elite", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 1, "amount_max": 1}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		},
		{
			"id": "combat_bamboo_maze",
			"name": "竹林迷宫",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 5, "count_max": 5}
			],
			"resources": [
				{"resource_id": "herb", "name": "灵草", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 2
		},
		{
			"id": "combat_bamboo_altar",
			"name": "竹林祭坛",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 3, "count_max": 3}
			],
			"resources": [
				{"resource_id": "technique_fragment", "name": "功法残页", "amount_min": 1, "amount_max": 1}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 2
		},
		{
			"id": "combat_bamboo_trap",
			"name": "竹林陷阱",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 2, "count_max": 2}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 30, "amount_max": 30}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 1
		},
		{
			"id": "combat_bamboo_treasury",
			"name": "竹林宝库",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 1
		}
	]

static func get_layer1_resource_templates() -> Array[Dictionary]:
	return [
		{
			"id": "resource_herb_cluster",
			"name": "灵草丛",
			"enemies": [],
			"resources": [
				{"resource_id": "herb", "name": "灵草", "amount_min": 5, "amount_max": 5}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_mineral_vein",
			"name": "矿脉",
			"enemies": [],
			"resources": [
				{"resource_id": "ore", "name": "矿石", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_chest_room",
			"name": "宝箱房间",
			"enemies": [],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_spirit_spring",
			"name": "灵泉",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 100, "amount_max": 100}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_ancient_tablet",
			"name": "古碑",
			"enemies": [],
			"resources": [
				{"resource_id": "technique_fragment", "name": "功法残页", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer1_event_templates() -> Array[Dictionary]:
	return [
		{
			"id": "event_old_merchant",
			"name": "老道商人",
			"enemies": [],
			"resources": [],
			"has_npc": true,
			"npc_dialogue": "小子，要买点什么？老道这里货真价实。",
			"difficulty": 0
		},
		{
			"id": "event_mysterious_taoist",
			"name": "神秘老道",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 50, "amount_max": 200}
			],
			"has_npc": true,
			"npc_dialogue": "小子，想试试运气吗？",
			"difficulty": 0
		},
		{
			"id": "event_trapped_cultivator",
			"name": "被困修士",
			"enemies": [
				{"enemy_id": "bamboo_spirit", "count_min": 2, "count_max": 3}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 100, "amount_max": 100}
			],
			"has_npc": true,
			"npc_dialogue": "道友救我！我被竹妖困在这里三天了！",
			"difficulty": 1
		},
		{
			"id": "event_teleport_array",
			"name": "古传送阵",
			"enemies": [],
			"resources": [],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer1_elite_templates() -> Array[Dictionary]:
	return [
		{
			"id": "elite_bamboo_nest",
			"name": "竹妖巢穴",
			"enemies": [
				{"enemy_id": "bamboo_elite", "count_min": 1, "count_max": 1},
				{"enemy_id": "bamboo_spirit", "count_min": 4, "count_max": 4}
			],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 4
		},
		{
			"id": "elite_bamboo_throne",
			"name": "竹妖王座",
			"enemies": [
				{"enemy_id": "bamboo_elite", "count_min": 2, "count_max": 2}
			],
			"resources": [
				{"resource_id": "technique_fragment", "name": "功法残页", "amount_min": 1, "amount_max": 1},
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 200, "amount_max": 200}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 5
		}
	]

static func get_layer1_extract_templates() -> Array[Dictionary]:
	return [
		{
			"id": "extract_bamboo_exit",
			"name": "竹林出口",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 50, "amount_max": 100}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "extract_ancient_well",
			"name": "古井",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 100, "amount_max": 200}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer1_secret_templates() -> Array[Dictionary]:
	return [
		{
			"id": "secret_bamboo_treasure",
			"name": "竹妖宝藏",
			"enemies": [],
			"resources": [
				{"resource_id": "equipment", "name": "仙品装备", "amount_min": 1, "amount_max": 1},
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 500, "amount_max": 500}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "secret_cultivator_cave",
			"name": "古修士洞府",
			"enemies": [],
			"resources": [
				{"resource_id": "technique_fragment", "name": "神品功法残页", "amount_min": 1, "amount_max": 1}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

# ──────────────────────────────────────────────
# 第2层：火焰山
# ──────────────────────────────────────────────

static func get_layer2_combat_templates() -> Array[Dictionary]:
	return [
		{
			"id": "combat_lava_zone",
			"name": "熔岩地带",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 3, "count_max": 3}
			],
			"resources": [
				{"resource_id": "fire_crystal", "name": "火晶石", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 2
		},
		{
			"id": "combat_volcano_crater",
			"name": "火山口",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 2, "count_max": 2},
				{"enemy_id": "fire_giant", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "ore", "name": "矿石", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 4
		},
		{
			"id": "combat_lava_bridge",
			"name": "熔岩桥",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 4, "count_max": 4}
			],
			"resources": [],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		},
		{
			"id": "combat_fire_maze",
			"name": "火焰迷宫",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 5, "count_max": 5}
			],
			"resources": [
				{"resource_id": "fire_crystal", "name": "火晶石", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		},
		{
			"id": "combat_fire_altar",
			"name": "火焰祭坛",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 3, "count_max": 3},
				{"enemy_id": "fire_giant", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "technique_fragment", "name": "功法残页", "amount_min": 1, "amount_max": 1}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 4
		},
		{
			"id": "combat_fire_trap",
			"name": "火焰陷阱",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 2, "count_max": 2}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 50, "amount_max": 50}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 2
		},
		{
			"id": "combat_fire_treasury",
			"name": "火焰宝库",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 2
		},
		{
			"id": "combat_fire_arena",
			"name": "火焰竞技场",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 6, "count_max": 6}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 200, "amount_max": 200}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		}
	]

static func get_layer2_resource_templates() -> Array[Dictionary]:
	return [
		{
			"id": "resource_fire_crystal_mine",
			"name": "火晶石矿",
			"enemies": [],
			"resources": [
				{"resource_id": "fire_crystal", "name": "火晶石", "amount_min": 5, "amount_max": 5}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_fire_chest",
			"name": "火焰宝箱",
			"enemies": [],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_fire_spring",
			"name": "火焰灵泉",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 200, "amount_max": 200}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_fire_tablet",
			"name": "火焰古碑",
			"enemies": [],
			"resources": [
				{"resource_id": "technique_fragment", "name": "功法残页", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_fire_vein",
			"name": "火焰矿脉",
			"enemies": [],
			"resources": [
				{"resource_id": "ore", "name": "矿石", "amount_min": 5, "amount_max": 5}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer2_event_templates() -> Array[Dictionary]:
	return [
		{
			"id": "event_fire_merchant",
			"name": "火焰商人",
			"enemies": [],
			"resources": [],
			"has_npc": true,
			"npc_dialogue": "道友，在这火焰山能活下来，你有点本事。",
			"difficulty": 0
		},
		{
			"id": "event_fire_spirit_npc",
			"name": "火焰精灵",
			"enemies": [],
			"resources": [
				{"resource_id": "fire_crystal", "name": "火晶石", "amount_min": 3, "amount_max": 8}
			],
			"has_npc": true,
			"npc_dialogue": "想感受火焰的力量吗？",
			"difficulty": 0
		},
		{
			"id": "event_trapped_fire_cultivator",
			"name": "被困火焰修士",
			"enemies": [
				{"enemy_id": "fire_spirit", "count_min": 2, "count_max": 3}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 200, "amount_max": 200}
			],
			"has_npc": true,
			"npc_dialogue": "道友救我！我被困在这火焰阵里了！",
			"difficulty": 2
		},
		{
			"id": "event_fire_teleport",
			"name": "火焰传送阵",
			"enemies": [],
			"resources": [],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer2_elite_templates() -> Array[Dictionary]:
	return [
		{
			"id": "elite_fire_nest",
			"name": "火焰巢穴",
			"enemies": [
				{"enemy_id": "fire_giant", "count_min": 1, "count_max": 1},
				{"enemy_id": "fire_spirit", "count_min": 4, "count_max": 4}
			],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 4
		},
		{
			"id": "elite_fire_throne",
			"name": "火焰王座",
			"enemies": [
				{"enemy_id": "fire_giant", "count_min": 2, "count_max": 2}
			],
			"resources": [
				{"resource_id": "equipment", "name": "仙品装备", "amount_min": 1, "amount_max": 1},
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 500, "amount_max": 500}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 5
		}
	]

static func get_layer2_extract_templates() -> Array[Dictionary]:
	return [
		{
			"id": "extract_fire_exit",
			"name": "火焰出口",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 100, "amount_max": 200}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "extract_fire_well",
			"name": "火焰古井",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 200, "amount_max": 400}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer2_secret_templates() -> Array[Dictionary]:
	return [
		{
			"id": "secret_fire_treasure",
			"name": "火焰宝藏",
			"enemies": [],
			"resources": [
				{"resource_id": "equipment", "name": "神品装备", "amount_min": 1, "amount_max": 1},
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 1000, "amount_max": 1000}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "secret_fire_cave",
			"name": "火焰修士洞府",
			"enemies": [],
			"resources": [
				{"resource_id": "technique_fragment", "name": "神品功法残页", "amount_min": 1, "amount_max": 1}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

# ──────────────────────────────────────────────
# 第3层：天机阁
# ──────────────────────────────────────────────

static func get_layer3_combat_templates() -> Array[Dictionary]:
	return [
		{
			"id": "combat_mechanism_corridor",
			"name": "机关通道",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 3, "count_max": 3}
			],
			"resources": [
				{"resource_id": "gear", "name": "齿轮", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		},
		{
			"id": "combat_gear_room",
			"name": "齿轮房间",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 2, "count_max": 2},
				{"enemy_id": "mechanism_general", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "ore", "name": "矿石", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 5
		},
		{
			"id": "combat_rune_array",
			"name": "符文阵",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 4, "count_max": 4}
			],
			"resources": [],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		},
		{
			"id": "combat_mechanism_maze",
			"name": "机关迷宫",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 5, "count_max": 5}
			],
			"resources": [
				{"resource_id": "gear", "name": "齿轮", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 4
		},
		{
			"id": "combat_mechanism_altar",
			"name": "机关祭坛",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 3, "count_max": 3},
				{"enemy_id": "mechanism_general", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "technique_fragment", "name": "功法残页", "amount_min": 1, "amount_max": 1}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 5
		},
		{
			"id": "combat_mechanism_trap",
			"name": "机关陷阱",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 2, "count_max": 2}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 100, "amount_max": 100}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		},
		{
			"id": "combat_mechanism_treasury",
			"name": "机关宝库",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 1, "count_max": 1}
			],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 3
		},
		{
			"id": "combat_mechanism_arena",
			"name": "机关竞技场",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 6, "count_max": 6}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 500, "amount_max": 500}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 4
		}
	]

static func get_layer3_resource_templates() -> Array[Dictionary]:
	return [
		{
			"id": "resource_gear_workshop",
			"name": "齿轮工坊",
			"enemies": [],
			"resources": [
				{"resource_id": "gear", "name": "齿轮", "amount_min": 5, "amount_max": 5}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_rune_study",
			"name": "符文书房",
			"enemies": [],
			"resources": [
				{"resource_id": "technique_fragment", "name": "功法残页", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_mechanism_chest",
			"name": "机关宝箱",
			"enemies": [],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 3, "amount_max": 3}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_mechanism_spring",
			"name": "机关灵泉",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 500, "amount_max": 500}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "resource_mechanism_vein",
			"name": "机关矿脉",
			"enemies": [],
			"resources": [
				{"resource_id": "ore", "name": "矿石", "amount_min": 5, "amount_max": 5}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer3_event_templates() -> Array[Dictionary]:
	return [
		{
			"id": "event_mechanism_merchant",
			"name": "机关商人",
			"enemies": [],
			"resources": [],
			"has_npc": true,
			"npc_dialogue": "道友，这天机阁的机关可不好对付。",
			"difficulty": 0
		},
		{
			"id": "event_mechanism_spirit",
			"name": "机关精灵",
			"enemies": [],
			"resources": [
				{"resource_id": "gear", "name": "齿轮", "amount_min": 5, "amount_max": 15}
			],
			"has_npc": true,
			"npc_dialogue": "想试试机关的力量吗？",
			"difficulty": 0
		},
		{
			"id": "event_trapped_mechanism_cultivator",
			"name": "被困机关修士",
			"enemies": [
				{"enemy_id": "mechanism_beast", "count_min": 2, "count_max": 3}
			],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 300, "amount_max": 300}
			],
			"has_npc": true,
			"npc_dialogue": "道友救我！我被困在这机关阵里了！",
			"difficulty": 3
		},
		{
			"id": "event_mechanism_teleport",
			"name": "机关传送阵",
			"enemies": [],
			"resources": [],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer3_elite_templates() -> Array[Dictionary]:
	return [
		{
			"id": "elite_mechanism_nest",
			"name": "机关巢穴",
			"enemies": [
				{"enemy_id": "mechanism_general", "count_min": 1, "count_max": 1},
				{"enemy_id": "mechanism_beast", "count_min": 4, "count_max": 4}
			],
			"resources": [
				{"resource_id": "chest", "name": "宝箱", "amount_min": 2, "amount_max": 2}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 5
		},
		{
			"id": "elite_mechanism_throne",
			"name": "机关王座",
			"enemies": [
				{"enemy_id": "mechanism_general", "count_min": 1, "count_max": 1},
				{"enemy_id": "mechanism_beast", "count_min": 2, "count_max": 2}
			],
			"resources": [
				{"resource_id": "equipment", "name": "神品装备", "amount_min": 1, "amount_max": 1},
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 1000, "amount_max": 1000}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 5
		}
	]

static func get_layer3_extract_templates() -> Array[Dictionary]:
	return [
		{
			"id": "extract_tianji_exit",
			"name": "天机出口",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 200, "amount_max": 400}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "extract_tianji_well",
			"name": "天机古井",
			"enemies": [],
			"resources": [
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 400, "amount_max": 800}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

static func get_layer3_secret_templates() -> Array[Dictionary]:
	return [
		{
			"id": "secret_tianji_treasure",
			"name": "天机宝藏",
			"enemies": [],
			"resources": [
				{"resource_id": "equipment", "name": "神品装备", "amount_min": 1, "amount_max": 1},
				{"resource_id": "spirit_stone", "name": "灵石", "amount_min": 2000, "amount_max": 2000}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		},
		{
			"id": "secret_tianji_realm",
			"name": "天机秘境",
			"enemies": [],
			"resources": [
				{"resource_id": "technique_fragment", "name": "神品功法残页", "amount_min": 1, "amount_max": 1},
				{"resource_id": "equipment", "name": "神品装备", "amount_min": 1, "amount_max": 1}
			],
			"has_npc": false,
			"npc_dialogue": "",
			"difficulty": 0
		}
	]

# ──────────────────────────────────────────────
# 按层获取所有模板的统一入口
# ──────────────────────────────────────────────

## 获取指定层、指定房间类型的模板列表
static func get_templates(layer: int, room_type) -> Array[Dictionary]:
	var RT = load("res://scripts/systems/room.gd")
	match layer:
		1:
			match room_type:
				RT.RoomType.COMBAT:
					return get_layer1_combat_templates()
				RT.RoomType.RESOURCE:
					return get_layer1_resource_templates()
				RT.RoomType.EVENT:
					return get_layer1_event_templates()
				RT.RoomType.ELITE:
					return get_layer1_elite_templates()
				RT.RoomType.EXTRACT:
					return get_layer1_extract_templates()
				RT.RoomType.SECRET:
					return get_layer1_secret_templates()
		2:
			match room_type:
				RT.RoomType.COMBAT:
					return get_layer2_combat_templates()
				RT.RoomType.RESOURCE:
					return get_layer2_resource_templates()
				RT.RoomType.EVENT:
					return get_layer2_event_templates()
				RT.RoomType.ELITE:
					return get_layer2_elite_templates()
				RT.RoomType.EXTRACT:
					return get_layer2_extract_templates()
				RT.RoomType.SECRET:
					return get_layer2_secret_templates()
		3:
			match room_type:
				RT.RoomType.COMBAT:
					return get_layer3_combat_templates()
				RT.RoomType.RESOURCE:
					return get_layer3_resource_templates()
				RT.RoomType.EVENT:
					return get_layer3_event_templates()
				RT.RoomType.ELITE:
					return get_layer3_elite_templates()
				RT.RoomType.EXTRACT:
					return get_layer3_extract_templates()
				RT.RoomType.SECRET:
					return get_layer3_secret_templates()
	return []

## 获取Boss敌人ID（按层）
static func get_boss_id(layer: int) -> String:
	match layer:
		1:
			return "bamboo_king"
		2:
			return "fire_demon"
		3:
			return "tianji_elder"
	return ""

## 获取Boss名称（按层）
static func get_boss_name(layer: int) -> String:
	match layer:
		1:
			return "竹妖王"
		2:
			return "火魔"
		3:
			return "天机老人"
	return ""

## 获取层主题名称
static func get_layer_theme_name(layer: int) -> String:
	match layer:
		1:
			return "幽竹林"
		2:
			return "火焰山"
		3:
			return "天机阁"
	return ""

## 获取层主题色彩（用于渲染）
static func get_layer_theme_colors(layer: int) -> Dictionary:
	match layer:
		1:
			return {
				"floor": Color(0.15, 0.25, 0.15),
				"wall": Color(0.3, 0.45, 0.3),
				"accent": Color(0.2, 0.6, 0.2),
				"bg": Color(0.05, 0.1, 0.05),
			}
		2:
			return {
				"floor": Color(0.3, 0.12, 0.05),
				"wall": Color(0.5, 0.2, 0.1),
				"accent": Color(0.9, 0.4, 0.1),
				"bg": Color(0.1, 0.03, 0.0),
			}
		3:
			return {
				"floor": Color(0.15, 0.15, 0.2),
				"wall": Color(0.35, 0.35, 0.45),
				"accent": Color(0.7, 0.6, 0.2),
				"bg": Color(0.05, 0.05, 0.08),
			}
	return {
		"floor": Color(0.2, 0.2, 0.2),
		"wall": Color(0.4, 0.4, 0.4),
		"accent": Color(0.6, 0.6, 0.6),
		"bg": Color(0.1, 0.1, 0.1),
	}

## 从模板随机选择一个
static func pick_random_template(layer: int, room_type) -> Dictionary:
	var templates = get_templates(layer, room_type)
	if templates.is_empty():
		return {}
	return templates[randi() % templates.size()]
