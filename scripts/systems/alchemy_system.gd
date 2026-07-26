## 炼丹系统 - 自动加载单例
## 管理丹方、炼制流程、炼制队列
extends Node

# 丹方定义 { recipe_id: { name, description, unlock_level, craft_time, materials, effect, duration } }
const RECIPES: Dictionary = {
	"restore_pill": {
		"name": "回复丹",
		"description": "回复 30% 生命值",
		"unlock_level": 1,
		"craft_time": 60,
		"materials": {"herb": 3},
		"effect": "heal_percent",
		"effect_value": 0.30,
		"duration": 0.0,
	},
	"shield_pill": {
		"name": "护盾丹",
		"description": "获得护盾，吸收 200 伤害",
		"unlock_level": 1,
		"craft_time": 120,
		"materials": {"herb": 5},
		"effect": "shield",
		"effect_value": 200,
		"duration": 30.0,
	},
	"attack_pill": {
		"name": "攻击丹",
		"description": "攻击力 +20%",
		"unlock_level": 2,
		"craft_time": 180,
		"materials": {"herb": 8, "ore": 2},
		"effect": "attack_percent",
		"effect_value": 0.20,
		"duration": 60.0,
	},
	"defense_pill": {
		"name": "防御丹",
		"description": "防御力 +20%",
		"unlock_level": 2,
		"craft_time": 180,
		"materials": {"herb": 8, "ore": 2},
		"effect": "defense_percent",
		"effect_value": 0.20,
		"duration": 60.0,
	},
	"crit_pill": {
		"name": "暴击丹",
		"description": "暴击率 +15%",
		"unlock_level": 3,
		"craft_time": 300,
		"materials": {"herb": 12, "ore": 3},
		"effect": "crit_rate",
		"effect_value": 0.15,
		"duration": 60.0,
	},
	"dodge_pill": {
		"name": "闪避丹",
		"description": "闪避率 +15%",
		"unlock_level": 3,
		"craft_time": 300,
		"materials": {"herb": 12, "ore": 3},
		"effect": "dodge_rate",
		"effect_value": 0.15,
		"duration": 60.0,
	},
	"advanced_restore_pill": {
		"name": "高级回复丹",
		"description": "回复 60% 生命值",
		"unlock_level": 4,
		"craft_time": 420,
		"materials": {"herb": 20, "artifact_spirit": 1},
		"effect": "heal_percent",
		"effect_value": 0.60,
		"duration": 0.0,
	},
	"advanced_shield_pill": {
		"name": "高级护盾丹",
		"description": "获得护盾，吸收 500 伤害",
		"unlock_level": 4,
		"craft_time": 480,
		"materials": {"herb": 25, "artifact_spirit": 2},
		"effect": "shield",
		"effect_value": 500,
		"duration": 30.0,
	},
	"rare_attack_pill": {
		"name": "稀有攻击丹",
		"description": "攻击力 +40%",
		"unlock_level": 5,
		"craft_time": 540,
		"materials": {"herb": 40, "artifact_spirit": 3},
		"effect": "attack_percent",
		"effect_value": 0.40,
		"duration": 60.0,
	},
	"rare_defense_pill": {
		"name": "稀有防御丹",
		"description": "防御力 +40%",
		"unlock_level": 5,
		"craft_time": 540,
		"materials": {"herb": 40, "artifact_spirit": 3},
		"effect": "defense_percent",
		"effect_value": 0.40,
		"duration": 60.0,
	},
}

# 炼制队列 [ { recipe_id, end_time, status } ]
var craft_queue: Array = []
# 最大队列长度由建筑等级决定: level
var max_queue_size: int = 1

signal craft_started(recipe_id: String)
signal craft_completed(recipe_id: String)
signal craft_queue_changed()

func _ready() -> void:
	_update_max_queue()

func _process(_delta: float) -> void:
	var now = Time.get_unix_time_from_system()
	var changed = false
	for i in range(craft_queue.size() - 1, -1, -1):
		var item: Dictionary = craft_queue[i]
		if item.get("status") == "crafting" and now >= item.get("end_time", 0.0):
			item["status"] = "done"
			craft_completed.emit(item.get("recipe_id", ""))
			changed = true
	if changed:
		craft_queue_changed.emit()

## 更新最大队列长度（建筑升级时调用）
func _update_max_queue() -> void:
	max_queue_size = BuildingSystem.get_building_level("alchemy_furnace")

## 获取所有已解锁的丹方
func get_unlocked_recipes() -> Array:
	var level = BuildingSystem.get_building_level("alchemy_furnace")
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

## 开始炼制，成功返回 true
func craft_potion(recipe_id: String) -> bool:
	if not RECIPES.has(recipe_id):
		return false
	var recipe: Dictionary = RECIPES[recipe_id]
	var level = BuildingSystem.get_building_level("alchemy_furnace")
	if recipe.get("unlock_level", 1) > level:
		return false
	if craft_queue.size() >= max_queue_size:
		return false
	if not has_materials(recipe_id):
		return false
	# 消耗材料
	var materials: Dictionary = recipe.get("materials", {})
	for res_id in materials:
		GameManager.storage[res_id] = GameManager.storage.get(res_id, 0) - materials[res_id]
	# 效率加成缩短时间
	var bonus = BuildingSystem.get_building_bonus("alchemy_furnace")
	var base_time: float = recipe.get("craft_time", 60.0)
	var actual_time = base_time / (1.0 + bonus)
	var now = Time.get_unix_time_from_system()
	craft_queue.append({
		"recipe_id": recipe_id,
		"start_time": now,
		"end_time": now + actual_time,
		"status": "crafting",
	})
	craft_started.emit(recipe_id)
	craft_queue_changed.emit()
	return true

## 收取已完成的丹药（index 为队列位置），返回丹药数据
func collect_potion(index: int) -> Dictionary:
	if index < 0 or index >= craft_queue.size():
		return {}
	var item: Dictionary = craft_queue[index]
	if item.get("status") != "done":
		return {}
	var recipe_id: String = item.get("recipe_id", "")
	craft_queue.remove_at(index)
	craft_queue_changed.emit()
	# 添加到背包
	var recipe: Dictionary = RECIPES.get(recipe_id, {})
	var potion = {
		"id": recipe_id,
		"name": recipe.get("name", ""),
		"type": "potion",
		"effect": recipe.get("effect", ""),
		"effect_value": recipe.get("effect_value", 0),
		"duration": recipe.get("duration", 0.0),
		"amount": 1,
	}
	GameManager.add_to_inventory(potion)
	return potion

## 收取所有已完成的丹药
func collect_all_done() -> Array:
	var collected: Array = []
	for i in range(craft_queue.size() - 1, -1, -1):
		if craft_queue[i].get("status") == "done":
			var result = collect_potion(i)
			if not result.is_empty():
				collected.append(result)
	return collected

## 序列化（存档）
func serialize() -> Dictionary:
	return {
		"queue": craft_queue.duplicate(true),
	}

## 反序列化（读档）
func deserialize(data: Dictionary) -> void:
	craft_queue = data.get("queue", []).duplicate(true)
	_update_max_queue()
