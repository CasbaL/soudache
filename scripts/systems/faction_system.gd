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

	# 根据门派执行不同大招
	match current_faction:
		SWORD:
			_execute_sword_ultimate(ult, caster)
		TALISMAN:
			_execute_talisman_ultimate(ult, caster)
		PILL:
			_execute_pill_ultimate(ult, caster)
		_:
			_execute_ultimate_aoe(ult, caster)

	return true

## 剑修大招：万剑归宗 - 多把飞剑从天而降攻击所有敌人
func _execute_sword_ultimate(ult: Dictionary, caster: Node2D) -> void:
	var scene = caster.get_tree().current_scene
	var enemies = caster.get_tree().get_nodes_in_group("enemies")
	var damage = ult.get("damage", 1000)
	var sword_count = maxi(enemies.size() * 3, 12)

	# 全屏闪白效果
	CombatFeedback.flash_screen_dark(0.3)

	# 飞剑逐把落下
	for i in sword_count:
		var target_pos: Vector2
		if enemies.size() > 0:
			var enemy = enemies[i % enemies.size()]
			if is_instance_valid(enemy):
				target_pos = enemy.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			else:
				target_pos = caster.global_position + Vector2(randf_range(-300, 300), randf_range(-300, 300))
		else:
			target_pos = caster.global_position + Vector2(randf_range(-300, 300), randf_range(-300, 300))

		# 创建飞剑视觉
		var sword = ColorRect.new()
		sword.size = Vector2(4, 20)
		sword.color = Color(1.0, 0.85, 0.0)
		sword.position = target_pos + Vector2(randf_range(-50, 50), -300)
		sword.rotation = deg_to_rad(randf_range(-15, 15))
		scene.add_child(sword)

		# 飞剑落下动画
		var tween = sword.create_tween()
		tween.tween_property(sword, "position:y", target_pos.y, 0.15)
		tween.tween_callback(func():
			# 落地伤害
			var effect_script = preload("res://scripts/systems/skill_effect.gd")
			var effect = Area2D.new()
			effect.set_script(effect_script)
			effect.position = sword.position
			effect.effect_type = "circle"
			effect.radius = 40.0
			effect.damage = damage / sword_count
			effect.color = Color(1.0, 0.85, 0.0, 0.5)
			effect.lifetime = 0.3
			scene.add_child(effect)
			sword.queue_free()
		)

		await caster.get_tree().create_timer(0.05).timeout

	# 屏幕震动
	CombatFeedback.shake_screen(12.0)

## 符修大招：天雷阵 - 随机位置落雷 + 定身
func _execute_talisman_ultimate(ult: Dictionary, caster: Node2D) -> void:
	var scene = caster.get_tree().current_scene
	var damage = ult.get("damage", 200)
	var dot_damage = ult.get("dot_damage", 200)
	var duration = ult.get("duration", 8.0)
	var strike_count = int(duration * 2)  # 每0.5秒一次

	# 全屏暗效果
	CombatFeedback.flash_screen_dark(0.5)

	for i in strike_count:
		if not is_instance_valid(caster):
			break

		# 随机落雷位置（以玩家为中心大范围）
		var offset = Vector2(randf_range(-350, 350), randf_range(-350, 350))
		var strike_pos = caster.global_position + offset

		# 雷电预警
		WarningIndicator.create_circle(scene, strike_pos, 60.0, 0.25, 0, "instant")

		await caster.get_tree().create_timer(0.25).timeout

		# 雷电效果
		var effect_script = preload("res://scripts/systems/skill_effect.gd")
		var effect = Area2D.new()
		effect.set_script(effect_script)
		effect.position = strike_pos
		effect.effect_type = "circle"
		effect.radius = 60.0
		effect.damage = damage
		effect.color = Color(0.3, 0.3, 1.0, 0.6)
		effect.lifetime = 0.4
		scene.add_child(effect)

		# 对区域内敌人施加定身
		for body in effect.get_overlapping_bodies():
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				SkillSystem.apply_stun(body, 1.0)

		CombatFeedback.shake_screen(5.0)

		await caster.get_tree().create_timer(0.5).timeout

## 丹修大招：九转还魂 - 全回复 + AOE伤害 + 临时护盾
func _execute_pill_ultimate(ult: Dictionary, caster: Node2D) -> void:
	var scene = caster.get_tree().current_scene
	var heal_amount = ult.get("heal_amount", 9999)

	# 全回复
	if caster.has_method("heal"):
		caster.heal(heal_amount)

	# AOE爆发伤害
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = caster.global_position
	effect.effect_type = "circle"
	effect.radius = 250.0
	effect.damage = 300
	effect.color = Color(0.2, 1.0, 0.2, 0.5)
	effect.lifetime = 1.0
	scene.add_child(effect)

	# 临时护盾
	SkillSystem.apply_shield(caster, 500, 10.0)

	# 视觉效果：绿色光环
	var ring = ColorRect.new()
	ring.size = Vector2(500, 500)
	ring.position = caster.global_position - ring.size / 2
	ring.color = Color(0.2, 1.0, 0.2, 0.15)
	ring.z_index = 50
	scene.add_child(ring)
	var tween = ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 2.0)
	tween.tween_callback(ring.queue_free)

	CombatFeedback.shake_screen(8.0)

## 通用AOE大招（备用）
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
