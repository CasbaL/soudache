## 建筑数据定义
## 9栋建筑的静态配置：名称、描述、升级消耗、解锁条件、效率加成
class_name BuildingData
extends RefCounted

# 建筑 ID 常量
const ALCHEMY_FURNACE = "alchemy_furnace"
const FORGE = "forge"
const TRAINING_ROOM = "training_room"
const LIBRARY = "library"
const FARM = "farm"
const WAREHOUSE = "warehouse"
const PORTAL = "portal"
const SHOP = "shop"
const TREASURE_VAULT = "treasure_vault"

const MAX_LEVEL = 5

# 所有建筑 ID 列表
const ALL_BUILDINGS = [
	ALCHEMY_FURNACE, FORGE, TRAINING_ROOM,
	LIBRARY, FARM, WAREHOUSE,
	PORTAL, SHOP, TREASURE_VAULT,
]

# ─── 建筑元数据 ───
# 每项: { name, description, category }
const META: Dictionary = {
	ALCHEMY_FURNACE: {
		"name": "炼丹炉",
		"description": "将灵草炼制成丹药，提供战斗增益",
		"category": "alchemy",
	},
	FORGE: {
		"name": "炼器台",
		"description": "将矿石打造成装备，提升战力",
		"category": "crafting",
	},
	TRAINING_ROOM: {
		"name": "修炼室",
		"description": "提升角色境界，解锁新能力",
		"category": "cultivation",
	},
	LIBRARY: {
		"name": "藏经阁",
		"description": "存储和学习功法，跨局保留",
		"category": "skill",
	},
	FARM: {
		"name": "灵田",
		"description": "种植灵草和矿石，被动产出资源",
		"category": "resource",
	},
	WAREHOUSE: {
		"name": "仓库",
		"description": "增加资源存储上限",
		"category": "storage",
	},
	PORTAL: {
		"name": "传送阵",
		"description": "快速传送到地图各层",
		"category": "utility",
	},
	SHOP: {
		"name": "商店",
		"description": "购买稀有材料和装备",
		"category": "shop",
	},
	TREASURE_VAULT: {
		"name": "宝库",
		"description": "存放珍稀物品，减少撤离损失",
		"category": "storage",
	},
}

# ─── 升级消耗 ───
# upgrade_costs[building_id][level] = { resource: amount, ... }
# level 是目标等级（从 2 开始，1 级无需消耗）
const UPGRADE_COSTS: Dictionary = {
	ALCHEMY_FURNACE: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	FORGE: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	TRAINING_ROOM: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	LIBRARY: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	FARM: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	WAREHOUSE: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	PORTAL: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	SHOP: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
	TREASURE_VAULT: {
		2: {"spirit_stone": 800, "ore": 30},
		3: {"spirit_stone": 1500, "herb": 60},
		4: {"spirit_stone": 3000, "artifact_spirit": 5},
		5: {"spirit_stone": 6000, "artifact_spirit": 10},
	},
}

# ─── 效率加成（每级 +20%）───
# efficiency_bonus[level] = 额外百分比 (0.0 = 基础)
static func get_efficiency_bonus(level: int) -> float:
	if level <= 1:
		return 0.0
	return (level - 1) * 0.20

# ─── 解锁条件 ───
# 每个建筑有最低等级要求（默认 1 级即可建造）
const UNLOCK_CONDITIONS: Dictionary = {
	ALCHEMY_FURNACE: {"min_level": 1},
	FORGE: {"min_level": 1},
	TRAINING_ROOM: {"min_level": 1},
	LIBRARY: {"min_level": 2},
	FARM: {"min_level": 2},
	WAREHOUSE: {"min_level": 2},
	PORTAL: {"min_level": 3},
	SHOP: {"min_level": 3},
	TREASURE_VAULT: {"min_level": 3},
}

# ─── 辅助方法 ───

## 获取建筑名称
static func get_name(building_id: String) -> String:
	return META.get(building_id, {}).get("name", building_id)

## 获取建筑描述
static func get_description(building_id: String) -> String:
	return META.get(building_id, {}).get("description", "")

## 获取建筑分类
static func get_category(building_id: String) -> String:
	return META.get(building_id, {}).get("category", "general")

## 获取指定建筑升到目标等级的消耗
static func get_upgrade_cost(building_id: String, target_level: int) -> Dictionary:
	var costs: Dictionary = UPGRADE_COSTS.get(building_id, {})
	return costs.get(target_level, {})

## 检查是否满足解锁条件
static func is_unlockable(building_id: String, building_levels: Dictionary) -> bool:
	var condition: Dictionary = UNLOCK_CONDITIONS.get(building_id, {})
	var min_level: int = condition.get("min_level", 1)
	# 洞府核心等级决定能否建造
	var core_level: int = building_levels.get("alchemy_furnace", 1)  # 用炼丹炉作为默认参考
	return core_level >= min_level
