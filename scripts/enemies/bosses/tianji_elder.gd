## 天机老人 Boss
## 阶段1：机关箭（5连射）、符文陷阱、召唤2傀儡
## 阶段2：符文护盾、符文传送、符文爆发
## 阶段3：天机阵（全场）、傀儡合体 + 易伤窗口
class_name TianjiElder
extends BossEnemy

# 天机老人特定参数
var arrow_burst_count: int = 5
var arrow_burst_interval: float = 0.15
var rune_shield_amount: int = 5000
var rune_shield_current: int = 0
var puppet_count: int = 2
var array_damage: int = 80

# 符文护盾视觉
var _rune_shield_visual: ColorRect

func _ready() -> void:
	enemy_name = "天机老人"
	max_health = 25000
	current_health = max_health
	attack_damage = 400
	defense = 120
	speed = 100.0
	attack_range = 150.0
	attack_cooldown = 0.4
	detect_range = 500.0
	
	phases = [
		{"name": "机关术", "healthRange": [100, 70], "attacks": ["mechanism_arrow", "rune_trap", "mechanism_summon"]},
		{"name": "符文之力", "healthRange": [70, 40], "attacks": ["mechanism_arrow", "rune_trap", "rune_shield", "rune_teleport", "rune_burst"]},
		{"name": "天机狂暴", "healthRange": [40, 0], "attacks": ["tianji_array", "mechanism_merge", "rune_shield", "rune_teleport", "rune_burst", "mechanism_arrow"]}
	]
	
	drop_items = [
		{"id": "spirit_stone", "name": "灵石", "amount": [1000, 1500], "chance": 1.0},
		{"id": "tianji_core", "name": "天机老人内丹", "rarity": "gold", "chance": 1.0},
		{"id": "tianji_scroll", "name": "天机秘卷", "rarity": "gold", "chance": 0.2},
		{"id": "technique_fragment", "name": "功法残页", "amount": [5, 10], "chance": 0.8}
	]
	
	super._ready()
	_setup_boss_visual()

func _setup_boss_visual() -> void:
	if sprite and sprite.texture == null:
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(68, 68)
		color_rect.position = -color_rect.size / 2
		color_rect.color = Color(0.3, 0.3, 0.5)
		sprite.add_child(color_rect)
		sprite.region_enabled = false

## 天机老人攻击执行
func execute_attack(attack_name: String) -> void:
	match attack_name:
		"mechanism_arrow":
			_attack_mechanism_arrow()
		"rune_trap":
			_attack_rune_trap()
		"mechanism_summon":
			_attack_mechanism_summon()
		"rune_shield":
			_attack_rune_shield()
		"rune_teleport":
			_attack_rune_teleport()
		"rune_burst":
			_attack_rune_burst()
		"tianji_array":
			_attack_tianji_array()
		"mechanism_merge":
			_attack_mechanism_merge()

## 阶段进入行为
func _on_phase_enter(phase: int) -> void:
	match phase:
		1:
			boss_announcement.emit("符文之力觉醒！")
		2:
			boss_announcement.emit("天机狂暴！")
			attack_cooldown = 0.25
			speed = 120.0

## 机关箭 - 5连射
func _attack_mechanism_arrow() -> void:
	var dir = _get_direction_to_target()
	
	for i in arrow_burst_count:
		var spread = deg_to_rad(randf_range(-5, 5))
		var arrow_dir = dir.rotated(spread)
		_spawn_arrow_projectile(arrow_dir)
		
		if i < arrow_burst_count - 1:
			await get_tree().create_timer(arrow_burst_interval).timeout
	
	print("%s: 机关箭5连射！" % enemy_name)

## 符文陷阱 - 定身效果（带预警）
func _attack_rune_trap() -> void:
	var target_pos = target.global_position if target else global_position + Vector2.RIGHT * 100
	# 预警：黄色控制
	WarningIndicator.create_circle(get_tree().current_scene, target_pos, 70.0, 0.5, 0, "control")

	await get_tree().create_timer(0.5).timeout

	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = target_pos
	effect.effect_type = "circle"
	effect.radius = 70.0
	effect.damage = attack_damage / 4
	effect.color = Color(0.5, 0.3, 0.8, 0.4)
	effect.lifetime = 1.5
	get_tree().current_scene.add_child(effect)

	# 对区域内玩家施加定身
	for body in effect.get_overlapping_bodies():
		if body is Player:
			SkillSystem.apply_stun(body, 2.0)

	print("%s: 符文陷阱！" % enemy_name)

## 召唤傀儡
func _attack_mechanism_summon() -> void:
	summon_minions(puppet_count, 150.0)
	boss_announcement.emit("机关傀儡现身！")
	print("%s: 召唤机关傀儡！" % enemy_name)

## 符文护盾 - 吸收5000伤害
func _attack_rune_shield() -> void:
	rune_shield_current = rune_shield_amount
	
	# 创建护盾视觉
	if _rune_shield_visual:
		_rune_shield_visual.queue_free()
	
	_rune_shield_visual = ColorRect.new()
	_rune_shield_visual.size = Vector2(80, 80)
	_rune_shield_visual.position = -_rune_shield_visual.size / 2
	_rune_shield_visual.color = Color(0.4, 0.2, 0.8, 0.3)
	_rune_shield_visual.z_index = 2
	add_child(_rune_shield_visual)
	
	boss_announcement.emit("符文护盾！")
	print("%s: 符文护盾 - 吸收 %d 伤害！" % [enemy_name, rune_shield_amount])

## 符文传送 - 传送到玩家附近
func _attack_rune_teleport() -> void:
	if not target:
		return
	
	# 传送到玩家周围随机位置
	var angle = randf() * TAU
	var offset = Vector2.from_angle(angle) * randf_range(80, 150)
	var new_pos = target.global_position + offset
	
	# 传送视觉效果
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	global_position = new_pos
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	print("%s: 符文传送！" % enemy_name)

## 符文爆发 - 圆形AOE（带预警）
func _attack_rune_burst() -> void:
	# 预警：圆形
	WarningIndicator.create_circle(get_tree().current_scene, global_position, 180.0, 0.4, 0, "instant")

	await get_tree().create_timer(0.4).timeout

	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = global_position
	effect.effect_type = "circle"
	effect.radius = 180.0
	effect.damage = attack_damage / 2
	effect.color = Color(0.6, 0.3, 0.9, 0.4)
	effect.lifetime = 0.8
	get_tree().current_scene.add_child(effect)

	print("%s: 符文爆发！" % enemy_name)

## 天机阵 - 全屏攻击（带预警）
func _attack_tianji_array() -> void:
	boss_announcement.emit("天机阵！")
	# 预警：大范围圆形
	WarningIndicator.create_circle(get_tree().current_scene, global_position, 450.0, 0.8, 0, "area")

	await get_tree().create_timer(0.8).timeout

	# 全屏伤害
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(array_damage)

	# 大范围视觉效果
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = global_position
	effect.effect_type = "circle"
	effect.radius = 450.0
	effect.damage = array_damage
	effect.color = Color(0.3, 0.2, 0.7, 0.2)
	effect.lifetime = 2.0
	get_tree().current_scene.add_child(effect)

	# 多段伤害
	for i in 3:
		await get_tree().create_timer(0.5).timeout
		if player and player.has_method("take_damage"):
			player.take_damage(array_damage / 3)

	print("%s: 天机阵！" % enemy_name)

## 傀儡合体 - 召唤巨型傀儡
func _attack_mechanism_merge() -> void:
	boss_announcement.emit("傀儡合体！")
	
	# 召唤增强版小怪
	for i in 2:
		var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		var spawn_pos = global_position + offset
		
		var spawner = get_node_or_null("/root/EnemySpawner")
		if spawner and spawner.has_method("spawn_enemy"):
			# 使用精英怪作为合体傀儡
			spawner.spawn_enemy("mechanism_general", spawn_pos)
	
	# 合体后进入易伤
	await get_tree().create_timer(2.0).timeout
	_start_vulnerability_window()
	
	print("%s: 傀儡合体！" % enemy_name)

## 受伤（覆盖，处理符文护盾）
func take_damage(damage: int, is_crit: bool = false) -> void:
	if is_dead:
		return
	
	# 符文护盾吸收
	var remaining_damage = damage
	if rune_shield_current > 0:
		if remaining_damage <= rune_shield_current:
			rune_shield_current -= remaining_damage
			remaining_damage = 0
			print("符文护盾吸收: %d (剩余: %d)" % [damage, rune_shield_current])
		else:
			remaining_damage -= rune_shield_current
			rune_shield_current = 0
			if _rune_shield_visual:
				_rune_shield_visual.queue_free()
				_rune_shield_visual = null
			print("符文护盾被击破！")
	
	if remaining_damage > 0:
		super.take_damage(remaining_damage, is_crit)
	else:
		# 设置目标
		if target == null:
			target = get_tree().get_first_node_in_group("player")

## 生成箭矢投射物
func _spawn_arrow_projectile(dir: Vector2) -> void:
	var projectile_script = preload("res://scripts/systems/projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_script)
	projectile.position = global_position
	projectile.direction = dir
	projectile.speed = 350.0
	projectile.damage = attack_damage / 4
	projectile.color = Color(0.6, 0.6, 0.8)
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	get_tree().current_scene.add_child(projectile)

## 获取到目标的方向
func _get_direction_to_target() -> Vector2:
	if target:
		return (target.global_position - global_position).normalized()
	return Vector2.RIGHT
