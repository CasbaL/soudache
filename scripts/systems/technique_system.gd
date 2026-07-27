## 功法系统 - 自动加载单例
## 管理功法学习、功法槽位、功法效果
extends Node

# 功法类型
enum TechniqueType { PASSIVE, ACTIVE }

# 功法定义
const TECHNIQUES: Dictionary = {
	# 基础功法 Lv1
	"basic_sword_art": {
		"name": "基础剑法",
		"type": TechniqueType.PASSIVE,
		"description": "攻击力+10%",
		"unlock_level": 1,
		"learn_time": 600,
		"cost": {"technique_fragment": 5},
		"effect": {"attack_percent": 0.10}
	},
	"basic_defense_art": {
		"name": "基础护体",
		"type": TechniqueType.PASSIVE,
		"description": "防御力+10%",
		"unlock_level": 1,
		"learn_time": 600,
		"cost": {"technique_fragment": 5},
		"effect": {"defense_percent": 0.10}
	},
	"basic_movement_art": {
		"name": "基础身法",
		"type": TechniqueType.PASSIVE,
		"description": "闪避率+5%",
		"unlock_level": 1,
		"learn_time": 600,
		"cost": {"technique_fragment": 5},
		"effect": {"dodge_rate": 0.05}
	},
	# 高级功法 Lv2
	"advanced_sword_art": {
		"name": "高级剑法",
		"type": TechniqueType.PASSIVE,
		"description": "攻击力+20%",
		"unlock_level": 2,
		"learn_time": 1800,
		"cost": {"technique_fragment": 15},
		"effect": {"attack_percent": 0.20}
	},
	"advanced_defense_art": {
		"name": "高级护体",
		"type": TechniqueType.PASSIVE,
		"description": "防御力+20%",
		"unlock_level": 2,
		"learn_time": 1800,
		"cost": {"technique_fragment": 15},
		"effect": {"defense_percent": 0.20}
	},
	"advanced_movement_art": {
		"name": "高级身法",
		"type": TechniqueType.PASSIVE,
		"description": "闪避率+10%",
		"unlock_level": 2,
		"learn_time": 1800,
		"cost": {"technique_fragment": 15},
		"effect": {"dodge_rate": 0.10}
	},
	# 绝学 Lv3
	"ultimate_sword_slash": {
		"name": "绝学·剑气斩",
		"type": TechniqueType.ACTIVE,
		"description": "新技能：剑气斩",
		"unlock_level": 3,
		"learn_time": 3600,
		"cost": {"technique_fragment": 30},
		"skill_id": "sword_qi_slash"
	},
	"ultimate_sword_control": {
		"name": "绝学·御剑术",
		"type": TechniqueType.ACTIVE,
		"description": "新技能：御剑术",
		"unlock_level": 3,
		"learn_time": 3600,
		"cost": {"technique_fragment": 30},
		"skill_id": "sword_fly"
	},
	"ultimate_talisman_seal": {
		"name": "绝学·定身符",
		"type": TechniqueType.ACTIVE,
		"description": "新技能：定身符",
		"unlock_level": 3,
		"learn_time": 3600,
		"cost": {"technique_fragment": 30},
		"skill_id": "talisman_seal"
	},
	# 神通 Lv4
	"divine_sword_rain": {
		"name": "神通·万剑归宗",
		"type": TechniqueType.ACTIVE,
		"description": "新技能：万剑归宗",
		"unlock_level": 4,
		"learn_time": 7200,
		"cost": {"technique_fragment": 60},
		"skill_id": "sword_rain"
	},
	"divine_thunder_array": {
		"name": "神通·天雷阵",
		"type": TechniqueType.ACTIVE,
		"description": "新技能：天雷阵",
		"unlock_level": 4,
		"learn_time": 7200,
		"cost": {"technique_fragment": 60},
		"skill_id": "thunder_array"
	},
	"divine_revive": {
		"name": "神通·九转还魂",
		"type": TechniqueType.ACTIVE,
		"description": "新技能：九转还魂",
		"unlock_level": 4,
		"learn_time": 7200,
		"cost": {"technique_fragment": 60},
		"skill_id": "revive_pill"
	},
}

# 功法槽位配置（根据藏经阁等级）
const SLOT_CONFIG: Dictionary = {
	1: 3,
	2: 5,
	3: 7,
	4: 10,
	5: 15,
}

# 已学习的功法 { technique_id: { learned_at, level } }
var learned_techniques: Dictionary = {}

# 正在学习的功法 { technique_id: { end_time, status } }
var learning_queue: Dictionary = {}

# 装备的功法槽位 [ technique_id, ... ]
var equipped_techniques: Array = []

signal technique_learned(technique_id: String)
signal technique_equipped(technique_id: String)
signal technique_unequipped(technique_id: String)
signal learning_completed(technique_id: String)

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	var now = Time.get_unix_time_from_system()
	var completed: Array = []
	for tech_id in learning_queue:
		var item = learning_queue[tech_id]
		if item.get("status") == "learning" and now >= item.get("end_time", 0.0):
			item["status"] = "done"
			completed.append(tech_id)
	for tech_id in completed:
		_complete_learning(tech_id)

## 获取藏经阁等级对应的功法槽位数
func get_max_slots() -> int:
	var level = BuildingSystem.get_building_level("library")
	return SLOT_CONFIG.get(level, 3)

## 获取已解锁的功法列表
func get_unlocked_techniques() -> Array:
	var level = BuildingSystem.get_building_level("library")
	var result: Array = []
	for tech_id in TECHNIQUES:
		if TECHNIQUES[tech_id].get("unlock_level", 1) <= level:
			result.append(tech_id)
	return result

## 检查功法是否已学习
func is_learned(technique_id: String) -> bool:
	return learned_techniques.has(technique_id)

## 检查功法是否正在学习
func is_learning(technique_id: String) -> bool:
	return learning_queue.has(technique_id) and learning_queue[technique_id].get("status") == "learning"

## 检查材料是否足够学习功法
func has_materials(technique_id: String) -> bool:
	var tech = TECHNIQUES.get(technique_id, {})
	var cost = tech.get("cost", {})
	for res_id in cost:
		if GameManager.storage.get(res_id, 0) < cost[res_id]:
			return false
	return true

## 开始学习功法
func start_learning(technique_id: String) -> bool:
	if not TECHNIQUES.has(technique_id):
		return false
	if is_learned(technique_id):
		return false
	if is_learning(technique_id):
		return false
	var tech = TECHNIQUES[technique_id]
	var level = BuildingSystem.get_building_level("library")
	if tech.get("unlock_level", 1) > level:
		return false
	if not has_materials(technique_id):
		return false
	# 消耗材料
	var cost = tech.get("cost", {})
	for res_id in cost:
		GameManager.storage[res_id] = GameManager.storage.get(res_id, 0) - cost[res_id]
	# 计算学习时间（受藏经阁效率加成）
	var bonus = BuildingSystem.get_building_bonus("library")
	var base_time = tech.get("learn_time", 600.0)
	var actual_time = base_time / (1.0 + bonus)
	var now = Time.get_unix_time_from_system()
	learning_queue[technique_id] = {
		"start_time": now,
		"end_time": now + actual_time,
		"status": "learning",
	}
	return true

## 完成学习
func _complete_learning(technique_id: String) -> void:
	learning_queue.erase(technique_id)
	learned_techniques[technique_id] = {
		"learned_at": Time.get_unix_time_from_system(),
		"level": 1,
	}
	technique_learned.emit(technique_id)
	learning_completed.emit(technique_id)

## 装备功法到槽位
func equip_technique(technique_id: String, slot: int) -> bool:
	if not is_learned(technique_id):
		return false
	var max_slots = get_max_slots()
	if slot < 0 or slot >= max_slots:
		return false
	# 如果槽位已有功法，先卸下
	if slot < equipped_techniques.size() and equipped_techniques[slot] != "":
		unequip_technique(slot)
	# 扩展槽位数组
	while equipped_techniques.size() <= slot:
		equipped_techniques.append("")
	equipped_techniques[slot] = technique_id
	technique_equipped.emit(technique_id)
	return true

## 卸下功法
func unequip_technique(slot: int) -> bool:
	if slot < 0 or slot >= equipped_techniques.size():
		return false
	var tech_id = equipped_techniques[slot]
	if tech_id == "":
		return false
	equipped_techniques[slot] = ""
	technique_unequipped.emit(tech_id)
	return true

## 获取已装备的功法列表
func get_equipped_techniques() -> Array:
	var result: Array = []
	for tech_id in equipped_techniques:
		if tech_id != "":
			result.append(tech_id)
	return result

## 获取功法的被动效果加成
func get_passive_bonuses() -> Dictionary:
	var bonuses = {
		"attack_percent": 0.0,
		"defense_percent": 0.0,
		"health_percent": 0.0,
		"crit_rate": 0.0,
		"dodge_rate": 0.0,
	}
	for tech_id in get_equipped_techniques():
		var tech = TECHNIQUES.get(tech_id, {})
		if tech.get("type") == TechniqueType.PASSIVE:
			var effect = tech.get("effect", {})
			for key in effect:
				if bonuses.has(key):
					bonuses[key] += effect[key]
	return bonuses

## 获取已装备的主动技能ID列表
func get_active_skills() -> Array:
	var skills: Array = []
	for tech_id in get_equipped_techniques():
		var tech = TECHNIQUES.get(tech_id, {})
		if tech.get("type") == TechniqueType.ACTIVE:
			skills.append(tech.get("skill_id", ""))
	return skills

## 获取功法数据
func get_technique_data(technique_id: String) -> Dictionary:
	return TECHNIQUES.get(technique_id, {})

## 获取学习进度（0.0 ~ 1.0）
func get_learning_progress(technique_id: String) -> float:
	if not is_learning(technique_id):
		return 0.0
	var item = learning_queue[technique_id]
	var now = Time.get_unix_time_from_system()
	var start_time = item.get("start_time", now)
	var end_time = item.get("end_time", now)
	var total = end_time - start_time
	var elapsed = now - start_time
	if total <= 0:
		return 1.0
	return clampf(elapsed / total, 0.0, 1.0)

## 序列化
func serialize() -> Dictionary:
	return {
		"learned": learned_techniques.duplicate(true),
		"equipped": equipped_techniques.duplicate(),
		"learning": learning_queue.duplicate(true),
	}

## 反序列化
func deserialize(data: Dictionary) -> void:
	learned_techniques = data.get("learned", {}).duplicate(true)
	equipped_techniques = data.get("equipped", []).duplicate()
	learning_queue = data.get("learning", {}).duplicate(true)
