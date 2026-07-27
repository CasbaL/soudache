## 技能系统 - 自动加载单例
## 管理技能数据、冷却、效果生成
extends Node

# 技能数据
var skill_data: Dictionary = {}

# 当前选择的门派
var current_faction: String = "sword"

# 冷却状态 {skill_id: remaining_time}
var cooldowns: Dictionary = {}

# 护盾系统 {node_id: {amount, timer}}
var shields: Dictionary = {}

# DOT系统 {node_id: [{damage, remaining, interval_accum}]}
var dots: Dictionary = {}

# 技能释放信号
signal skill_cast(skill_id: String, slot: int)

func _ready() -> void:
	load_skills()

func _process(delta: float) -> void:
	# 更新冷却
	for skill_id in cooldowns:
		if cooldowns[skill_id] > 0:
			cooldowns[skill_id] -= delta
			if cooldowns[skill_id] < 0:
				cooldowns[skill_id] = 0
	
	# 更新DOT
	var dots_to_remove: Array = []
	for target_id in dots:
		var target = instance_from_id(target_id)
		if not is_instance_valid(target):
			dots_to_remove.append(target_id)
			continue
		
		var dot_list: Array = dots[target_id]
		var i = dot_list.size() - 1
		while i >= 0:
			var dot = dot_list[i]
			dot.remaining -= delta
			if dot.remaining <= 0:
				dot_list.remove_at(i)
			else:
				dot.interval_accum += delta
				if dot.interval_accum >= 1.0:
					dot.interval_accum -= 1.0
					if target.has_method("take_damage"):
						target.take_damage(dot.damage, false)
			i -= 1
		
		if dot_list.is_empty():
			dots_to_remove.append(target_id)
	
	for id in dots_to_remove:
		dots.erase(id)
	
	# 更新护盾
	var shields_to_remove: Array = []
	for target_id in shields:
		var shield = shields[target_id]
		shield.timer -= delta
		if shield.timer <= 0:
			shields_to_remove.append(target_id)
	
	for id in shields_to_remove:
		shields.erase(id)

## 加载技能数据
func load_skills() -> void:
	var file = FileAccess.open("res://data/skills.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			skill_data = json.data
		else:
			print("技能数据解析错误: ", json.get_error_message())
	else:
		print("无法打开技能数据文件")

## 获取当前门派的技能列表
func get_faction_skills() -> Array:
	if skill_data.has(current_faction):
		return skill_data[current_faction].get("skills", [])
	return []

## 获取指定槽位的技能
func get_skill_by_slot(slot: int) -> Dictionary:
	var skills = get_faction_skills()
	for skill in skills:
		if skill.get("slot", 0) == slot:
			return skill
	return {}

## 检查技能是否在冷却中
func is_on_cooldown(skill_id: String) -> bool:
	return cooldowns.get(skill_id, 0) > 0

## 获取剩余冷却时间
func get_cooldown_remaining(skill_id: String) -> float:
	return cooldowns.get(skill_id, 0.0)

## 使用技能
func use_skill(slot: int, caster: Node2D, direction: Vector2) -> bool:
	var skill = get_skill_by_slot(slot)
	if skill.is_empty():
		return false
	
	var skill_id = skill.get("id", "")
	
	# 检查冷却
	if is_on_cooldown(skill_id):
		return false
	
	# 设置冷却
	cooldowns[skill_id] = skill.get("cooldown", 0.0)
	
	# 检测技能组合
	var combo = check_combo(skill_id)
	var damage_multiplier = 1.0
	if not combo.is_empty():
		print("触发组合: %s - %s" % [combo.get("name", ""), combo.get("description", "")])
		if combo.get("effect", "") == "damage_boost":
			damage_multiplier = combo.get("value", 1.0)

	# 根据效果类型执行
	var effect_type = skill.get("effect_type", "")
	match effect_type:
		"projectile":
			create_projectile(skill, caster, direction)
		"line_aoe":
			create_line_aoe(skill, caster, direction)
		"circle_aoe":
			create_circle_aoe(skill, caster, direction)
		"shield":
			apply_shield(skill, caster)
		"self_heal":
			apply_heal(skill, caster)
		_:
			print("未知效果类型: ", effect_type)
	
	# 技能命中增加大招充能
	var skill_damage = skill.get("damage", 0)
	if skill_damage > 0:
		FactionSystem.add_ultimate_charge(skill_damage * damage_multiplier * 0.05)
	
	skill_cast.emit(skill_id, slot)
	return true

## 创建投射物
func create_projectile(skill: Dictionary, caster: Node2D, direction: Vector2) -> void:
	var projectile_scene = preload("res://scripts/systems/projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_scene)
	projectile.position = caster.global_position
	
	# 设置投射物属性
	projectile.direction = direction.normalized()
	projectile.speed = skill.get("projectile_speed", 300.0)
	projectile.damage = skill.get("damage", 0)
	projectile.color = Color(skill.get("projectile_color", "#FFFFFF"))
	projectile.stun_duration = skill.get("stun_duration", 0.0)
	projectile.dot_damage = skill.get("dot_damage", 0)
	projectile.dot_duration = skill.get("dot_duration", 0.0)
	
	# 添加到场景
	caster.get_tree().current_scene.add_child(projectile)

## 创建直线AOE
func create_line_aoe(skill: Dictionary, caster: Node2D, direction: Vector2) -> void:
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = caster.global_position + direction.normalized() * 50
	
	# 设置AOE属性
	effect.effect_type = "line"
	effect.length = skill.get("aoe_length", 200.0)
	effect.width = skill.get("aoe_width", 40.0)
	effect.damage = skill.get("damage", 0)
	effect.color = Color(skill.get("projectile_color", "#FFFFFF"))
	effect.rotation = direction.angle()
	effect.lifetime = 0.3
	
	# 添加到场景
	caster.get_tree().current_scene.add_child(effect)

## 创建圆形AOE
func create_circle_aoe(skill: Dictionary, caster: Node2D, direction: Vector2) -> void:
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = caster.global_position + direction.normalized() * 100
	
	# 设置AOE属性
	effect.effect_type = "circle"
	effect.radius = skill.get("aoe_radius", 100.0)
	effect.damage = skill.get("damage", 0)
	effect.color = Color(skill.get("projectile_color", "#FFFFFF"))
	effect.lifetime = 0.4
	
	# 添加到场景
	caster.get_tree().current_scene.add_child(effect)

## 应用护盾
func apply_shield(skill: Dictionary, caster: Node2D) -> void:
	var target_id = caster.get_instance_id()
	shields[target_id] = {
		"amount": skill.get("shield_amount", 0),
		"timer": skill.get("shield_duration", 5.0)
	}
	print("获得护盾: %d" % skill.get("shield_amount", 0))

## 应用治疗
func apply_heal(skill: Dictionary, caster: Node2D) -> void:
	if caster.has_method("heal"):
		caster.heal(skill.get("heal_amount", 0))
	print("回复生命: %d" % skill.get("heal_amount", 0))

## 对目标应用DOT
func apply_dot(target: Node2D, damage: float, duration: float) -> void:
	var target_id = target.get_instance_id()
	if not dots.has(target_id):
		dots[target_id] = []
	dots[target_id].append({
		"damage": damage,
		"remaining": duration,
		"interval_accum": 0.0
	})

## 对目标应用定身
func apply_stun(target: Node2D, duration: float) -> void:
	if target.has_method("apply_stun"):
		target.apply_stun(duration)
	else:
		# 简易定身：禁用物理处理
		var target_id = target.get_instance_id()
		target.set_physics_process(false)
		# 创建定时器恢复
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(func():
			target.set_physics_process(true)
			timer.queue_free()
		)
		target.add_child(timer)
		timer.start()

## 获取护盾剩余值
func get_shield_amount(target: Node2D) -> int:
	var target_id = target.get_instance_id()
	if shields.has(target_id):
		return shields[target_id].amount
	return 0

## 消耗护盾（被攻击时调用）
func absorb_damage(target: Node2D, damage: int) -> int:
	var target_id = target.get_instance_id()
	if not shields.has(target_id):
		return damage
	
	var shield = shields[target_id]
	if damage <= shield.amount:
		shield.amount -= damage
		return 0
	else:
		var remaining = damage - shield.amount
		shields.erase(target_id)
		return remaining

## 设置当前门派
func set_faction(faction: String) -> void:
	if skill_data.has(faction):
		current_faction = faction
		cooldowns.clear()

# ============================================================
# 技能组合系统
# ============================================================

# 最近使用的技能（用于组合检测）
var _recent_skills: Array = []
const COMBO_WINDOW: float = 3.0  # 组合窗口时间

# 组合定义：[技能A_id, 技能B_id] → 组合效果
const COMBOS: Dictionary = {
	"talisman_stun+sword_qi_slash": {
		"name": "定身剑阵",
		"description": "定身期间剑阵伤害+50%",
		"effect": "damage_boost",
		"value": 1.5,
	},
	"pill_shield+sword_fly_blade": {
		"name": "护盾冲锋",
		"description": "冲锋期间护盾吸收量翻倍",
		"effect": "shield_boost",
		"value": 2.0,
	},
	"talisman_thunder+talisman_fire": {
		"name": "雷火交加",
		"description": "水区域导电，伤害翻倍",
		"effect": "damage_boost",
		"value": 2.0,
	},
}

## 记录技能使用（用于组合检测）
func _record_skill_use(skill_id: String) -> void:
	var now = Time.get_unix_time_from_system()
	_recent_skills.append({"id": skill_id, "time": now})
	# 清理过期记录
	_recent_skills = _recent_skills.filter(func(s): return now - s.time < COMBO_WINDOW)

## 检测并返回组合效果
func check_combo(skill_id: String) -> Dictionary:
	_record_skill_use(skill_id)

	# 检查最近使用的技能是否形成组合
	for i in range(_recent_skills.size() - 1):
		var prev = _recent_skills[i]
		var combo_key = prev.id + "+" + skill_id
		if COMBOS.has(combo_key):
			return COMBOS[combo_key]
		# 也检查反向组合
		var reverse_key = skill_id + "+" + prev.id
		if COMBOS.has(reverse_key):
			return COMBOS[reverse_key]

	return {}
