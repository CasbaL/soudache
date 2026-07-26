## 装备打造系统 - 自动加载单例
## 根据炼器台等级解锁装备配方，使用矿石+灵草+器灵打造装备
extends Node

# 装备配方 { recipe_id: { name, type, rarity, stats, unlock_level, craft_time, materials } }
const RECIPES: Dictionary = {
	# 凡品 Lv1
	"green_steel_sword": {
		"name": "青钢剑", "type": "weapon", "rarity": "white",
		"stats": {"attack": 50}, "unlock_level": 1, "craft_time": 300,
		"materials": {"ore": 10},
	},
	"cloth_armor": {
		"name": "布衣", "type": "armor", "rarity": "white",
		"stats": {"defense": 30}, "unlock_level": 1, "craft_time": 300,
		"materials": {"herb": 10},
	},
	"spirit_stone_ring": {
		"name": "灵石戒指", "type": "accessory", "rarity": "white",
		"stats": {"health": 100}, "unlock_level": 1, "craft_time": 300,
		"materials": {"ore": 15},
	},
	# 灵品 Lv2
	"spirit_iron_sword": {
		"name": "灵铁剑", "type": "weapon", "rarity": "green",
		"stats": {"attack": 100}, "unlock_level": 2, "craft_time": 600,
		"materials": {"ore": 30, "herb": 20},
	},
	"spirit_pattern_armor": {
		"name": "灵纹甲", "type": "armor", "rarity": "green",
		"stats": {"defense": 60}, "unlock_level": 2, "craft_time": 600,
		"materials": {"ore": 30, "herb": 20},
	},
	"spirit_power_necklace": {
		"name": "灵力项链", "type": "accessory", "rarity": "green",
		"stats": {"health": 200}, "unlock_level": 2, "craft_time": 600,
		"materials": {"ore": 40, "herb": 30},
	},
	# 宝品 Lv3
	"treasure_iron_sword": {
		"name": "宝铁剑", "type": "weapon", "rarity": "blue",
		"stats": {"attack": 180}, "unlock_level": 3, "craft_time": 900,
		"materials": {"ore": 60, "artifact_spirit": 2},
	},
	"treasure_pattern_armor": {
		"name": "宝纹甲", "type": "armor", "rarity": "blue",
		"stats": {"defense": 110}, "unlock_level": 3, "craft_time": 900,
		"materials": {"ore": 60, "artifact_spirit": 2},
	},
	"treasure_power_necklace": {
		"name": "宝力项链", "type": "accessory", "rarity": "blue",
		"stats": {"health": 400}, "unlock_level": 3, "craft_time": 900,
		"materials": {"ore": 80, "artifact_spirit": 3},
	},
	# 仙品 Lv4
	"immortal_iron_sword": {
		"name": "仙铁剑", "type": "weapon", "rarity": "purple",
		"stats": {"attack": 300}, "unlock_level": 4, "craft_time": 1200,
		"materials": {"ore": 120, "artifact_spirit": 5},
	},
	"immortal_pattern_armor": {
		"name": "仙纹甲", "type": "armor", "rarity": "purple",
		"stats": {"defense": 180}, "unlock_level": 4, "craft_time": 1200,
		"materials": {"ore": 120, "artifact_spirit": 5},
	},
	"immortal_power_necklace": {
		"name": "仙力项链", "type": "accessory", "rarity": "purple",
		"stats": {"health": 700}, "unlock_level": 4, "craft_time": 1200,
		"materials": {"ore": 160, "artifact_spirit": 8},
	},
	# 神品 Lv5
	"divine_iron_sword": {
		"name": "神铁剑", "type": "weapon", "rarity": "gold",
		"stats": {"attack": 500}, "unlock_level": 5, "craft_time": 1800,
		"materials": {"ore": 250, "artifact_spirit": 15},
	},
	"divine_pattern_armor": {
		"name": "神纹甲", "type": "armor", "rarity": "gold",
		"stats": {"defense": 300}, "unlock_level": 5, "craft_time": 1800,
		"materials": {"ore": 250, "artifact_spirit": 15},
	},
	"divine_power_necklace": {
		"name": "神力项链", "type": "accessory", "rarity": "gold",
		"stats": {"health": 1200}, "unlock_level": 5, "craft_time": 1800,
		"materials": {"ore": 300, "artifact_spirit": 20},
	},
}

# 成功率表（根据炼器台等级）
const SUCCESS_RATES = [0.80, 0.85, 0.90, 0.95, 1.00]

# 打造队列 [ { recipe_id, end_time, status, success } ]
var craft_queue: Array = []

signal craft_started(recipe_id: String)
signal craft_completed(recipe_id: String, success: bool)
signal craft_queue_changed()

func _process(_delta: float) -> void:
	var now = Time.get_unix_time_from_system()
	var changed = false
	for i in range(craft_queue.size() - 1, -1, -1):
		var item: Dictionary = craft_queue[i]
		if item.get("status") == "crafting" and now >= item.get("end_time", 0.0):
			var success = _roll_success()
			item["status"] = "done"
			item["success"] = success
			craft_completed.emit(item.get("recipe_id", ""), success)
			changed = true
	if changed:
		craft_queue_changed.emit()

func _roll_success() -> bool:
	var level = BuildingSystem.get_building_level("forge")
	var rate: float = SUCCESS_RATES[clampi(level - 1, 0, SUCCESS_RATES.size() - 1)]
	return randf() < rate

## 获取已解锁的配方列表
func get_unlocked_recipes() -> Array:
	var level = BuildingSystem.get_building_level("forge")
	var result: Array = []
	for recipe_id in RECIPES:
		if RECIPES[recipe_id].get("unlock_level", 1) <= level:
			result.append(recipe_id)
	return result

## 检查材料是否足够
func has_materials(recipe_id: String) -> bool:
	var recipe: Dictionary = RECIPES.get(recipe_id, {})
	var materials: Dictionary = recipe.get("materials", {})
	for res_id in materials:
		if GameManager.storage.get(res_id, 0) < materials[res_id]:
			return false
	return true

## 开始打造，成功入队返回 true
func craft_equipment(recipe_id: String) -> bool:
	if not RECIPES.has(recipe_id):
		return false
	var recipe: Dictionary = RECIPES[recipe_id]
	var level = BuildingSystem.get_building_level("forge")
	if recipe.get("unlock_level", 1) > level:
		return false
	if not has_materials(recipe_id):
		return false
	# 消耗材料
	var materials: Dictionary = recipe.get("materials", {})
	for res_id in materials:
		GameManager.storage[res_id] = GameManager.storage.get(res_id, 0) - materials[res_id]
	# 效率加成缩短时间
	var bonus = BuildingSystem.get_building_bonus("forge")
	var base_time: float = recipe.get("craft_time", 300.0)
	var actual_time = base_time / (1.0 + bonus)
	var now = Time.get_unix_time_from_system()
	craft_queue.append({
		"recipe_id": recipe_id,
		"start_time": now,
		"end_time": now + actual_time,
		"status": "crafting",
		"success": false,
	})
	craft_started.emit(recipe_id)
	craft_queue_changed.emit()
	return true

## 收取打造结果（index 为队列位置），返回装备字典或空字典
func collect_equipment(index: int) -> Dictionary:
	if index < 0 or index >= craft_queue.size():
		return {}
	var item: Dictionary = craft_queue[index]
	if item.get("status") != "done":
		return {}
	var recipe_id: String = item.get("recipe_id", "")
	var success: bool = item.get("success", false)
	craft_queue.remove_at(index)
	craft_queue_changed.emit()
	if not success:
		return {}  # 打造失败，材料已损失
	var recipe: Dictionary = RECIPES.get(recipe_id, {})
	var equip = {
		"id": recipe_id,
		"name": recipe.get("name", ""),
		"type": recipe.get("type", "weapon"),
		"rarity": recipe.get("rarity", "white"),
	}
	# 合并属性
	for stat_key in recipe.get("stats", {}):
		equip[stat_key] = recipe.stats[stat_key]
	GameManager.add_to_inventory(equip)
	return equip

## 收取所有已完成的
func collect_all_done() -> Array:
	var collected: Array = []
	for i in range(craft_queue.size() - 1, -1, -1):
		if craft_queue[i].get("status") == "done":
			var result = collect_equipment(i)
			collected.append(result)
	return collected

func serialize() -> Dictionary:
	return {"queue": craft_queue.duplicate(true)}

func deserialize(data: Dictionary) -> void:
	craft_queue = data.get("queue", []).duplicate(true)
