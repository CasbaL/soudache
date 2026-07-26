## 门派系统 - 自动加载单例
## 管理门派选择、属性查询、技能加载
extends Node

# 门派ID常量
const SWORD: String = "sword"
const TALISMAN: String = "talisman"
const PILL: String = "pill"

# 当前选择的门派
var current_faction: String = ""

# 大招充能进度 {faction_id: charge}
var ultimate_charge: float = 0.0
var ultimate_charge_max: float = 100.0

# 预加载 FactionData 脚本
var _FactionDataScript = preload("res://scripts/systems/faction_data.gd")
var _faction_data_instance = null

# 信号
signal faction_selected(faction_id: String)
signal ultimate_charge_changed(current: float, maximum: float)
signal ultimate_ready()

func _ready() -> void:
	# 创建 FactionData 实例
	_faction_data_instance = _FactionDataScript.new()

## 选择门派
func select_faction(faction_id: String) -> void:
	if _faction_data_instance.get_faction(faction_id).is_empty():
		push_error("无效的门派ID: " + faction_id)
		return
	
	current_faction = faction_id
	ultimate_charge = 0.0
	
	# 同步到技能系统
	SkillSystem.set_faction(faction_id)
	
	# 同步基础属性到游戏管理器
	var stats = _faction_data_instance.get_stats(faction_id)
	GameManager.player_data.max_health = stats.get("max_health", 500)
	GameManager.player_data.health = stats.get("max_health", 500)
	GameManager.player_data.attack = stats.get("attack", 100)
	GameManager.player_data.defense = stats.get("defense", 50)
	GameManager.player_data.speed = stats.get("speed", 200.0)
	GameManager.player_data.crit_rate = stats.get("crit_rate", 0.05)
	GameManager.player_data.crit_damage = stats.get("crit_damage", 1.5)
	
	faction_selected.emit(faction_id)

## 获取当前门派ID
func get_current_faction() -> String:
	return current_faction

## 获取当前门派基础属性
func get_faction_stats(faction_id: String = "") -> Dictionary:
	var id = faction_id if faction_id != "" else current_faction
	return _faction_data_instance.get_stats(id)

## 获取当前门派技能列表（来自 skills.json）
func get_faction_skills(faction_id: String = "") -> Array:
	var id = faction_id if faction_id != "" else current_faction
	return SkillSystem.get_faction_skills() if id == current_faction else []

## 获取门派普攻配置
func get_auto_attack_config(faction_id: String = "") -> Dictionary:
	var id = faction_id if faction_id != "" else current_faction
	return _faction_data_instance.get_auto_attack(id)

## 获取大招配置
func get_ultimate_config(faction_id: String = "") -> Dictionary:
	var id = faction_id if faction_id != "" else current_faction
	return _faction_data_instance.get_ultimate(id)

## 增加大招充能（造成或受到伤害时调用）
func add_ultimate_charge(amount: float) -> void:
	if current_faction == "":
		return
	ultimate_charge = min(ultimate_charge + amount, ultimate_charge_max)
	ultimate_charge_changed.emit(ultimate_charge, ultimate_charge_max)
	if ultimate_charge >= ultimate_charge_max:
		ultimate_ready.emit()

## 检查大招是否就绪
func is_ultimate_ready() -> bool:
	return ultimate_charge >= ultimate_charge_max

## 使用大招
func use_ultimate(caster: Node2D) -> bool:
	if not is_ultimate_ready():
		return false
	
	var ult = get_ultimate_config()
	if ult.is_empty():
		return false
	
	ultimate_charge = 0.0
	ultimate_charge_changed.emit(ultimate_charge, ultimate_charge_max)
	
	# 根据效果类型执行
	match ult.get("effect_type", ""):
		"circle_aoe":
			_execute_ultimate_aoe(ult, caster)
		"self_heal":
			_execute_ultimate_heal(ult, caster)
	
	return true

## 执行大招AOE效果
func _execute_ultimate_aoe(ult: Dictionary, caster: Node2D) -> void:
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = caster.global_position
	
	effect.effect_type = "circle"
	effect.radius = ult.get("aoe_radius", 500.0)
	effect.damage = ult.get("damage", 0)
	effect.color = Color(ult.get("color", "#FFFFFF"))
	effect.lifetime = ult.get("duration", 1.0)
	
	caster.get_tree().current_scene.add_child(effect)

## 执行大招治疗效果
func _execute_ultimate_heal(ult: Dictionary, caster: Node2D) -> void:
	if caster.has_method("heal"):
		caster.heal(ult.get("heal_amount", 0))
