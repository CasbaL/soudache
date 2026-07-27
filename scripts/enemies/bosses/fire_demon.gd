## 火魔 Boss
## 阶段1：火球三连射、火焰吐息、岩浆地面
## 阶段2：火焰领域（光环伤害）、火焰冲锋
## 阶段3：陨石雨、火焰爆炸 + 易伤窗口
class_name FireDemon
extends BossEnemy

# 火魔特定参数
var fireball_count: int = 3
var fireball_spread: float = 15.0
var domain_damage: int = 40
var domain_radius: float = 150.0
var meteor_count: int = 8
var magma_dot_damage: int = 30
var magma_dot_duration: float = 4.0

# 领域视觉
var _domain_visual: Node2D
var _domain_active: bool = false

func _ready() -> void:
	enemy_name = "火魔"
	max_health = 15000
	current_health = max_health
	attack_damage = 250
	defense = 80
	speed = 90.0
	attack_range = 120.0
	attack_cooldown = 0.5
	detect_range = 500.0
	
	phases = [
		{"name": "火焰风暴", "healthRange": [100, 70], "attacks": ["fire_ball", "fire_breath", "magma_ground"]},
		{"name": "火焰领域", "healthRange": [70, 40], "attacks": ["fire_ball", "fire_breath", "magma_ground", "fire_domain", "fire_charge"]},
		{"name": "火焰狂暴", "healthRange": [40, 0], "attacks": ["fire_meteor", "fire_explosion", "fire_ball", "fire_breath", "fire_domain", "fire_charge"]}
	]
	
	drop_items = [
		{"id": "spirit_stone", "name": "灵石", "amount": [500, 800], "chance": 1.0},
		{"id": "fire_demon_core", "name": "火魔内丹", "rarity": "purple", "chance": 1.0},
		{"id": "fire_demon_soul", "name": "火魔之魂", "rarity": "gold", "chance": 0.25},
		{"id": "technique_fragment", "name": "功法残页", "amount": [3, 6], "chance": 0.6}
	]
	
	super._ready()
	_setup_boss_visual()

func _setup_boss_visual() -> void:
	if sprite and sprite.texture == null:
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(72, 72)
		color_rect.position = -color_rect.size / 2
		color_rect.color = Color(0.9, 0.2, 0.05)
		sprite.add_child(color_rect)
		sprite.region_enabled = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# 领域持续伤害
	if _domain_active and target:
		var distance = global_position.distance_to(target.global_position)
		if distance <= domain_radius:
			# 每秒伤害
			if Engine.get_process_frames() % 60 == 0:
				if target.has_method("take_damage"):
					target.take_damage(domain_damage)

## 火魔攻击执行
func execute_attack(attack_name: String) -> void:
	match attack_name:
		"fire_ball":
			_attack_fire_ball()
		"fire_breath":
			_attack_fire_breath()
		"magma_ground":
			_attack_magma_ground()
		"fire_domain":
			_attack_fire_domain()
		"fire_charge":
			_attack_fire_charge()
		"fire_meteor":
			_attack_fire_meteor()
		"fire_explosion":
			_attack_fire_explosion()

## 阶段进入行为
func _on_phase_enter(phase: int) -> void:
	match phase:
		1:
			boss_announcement.emit("火焰领域展开！")
		2:
			boss_announcement.emit("火焰狂暴！")
			attack_cooldown = 0.3
			speed = 110.0

## 火球三连射
func _attack_fire_ball() -> void:
	var base_dir = _get_direction_to_target()
	
	for i in fireball_count:
		var angle_offset = deg_to_rad(-fireball_spread + fireball_spread * i)
		var dir = base_dir.rotated(angle_offset)
		_spawn_fire_projectile(dir, 300.0, attack_damage / 3)
	
	print("%s: 火球三连射！" % enemy_name)

## 火焰吐息 - 锥形AOE（带预警）
func _attack_fire_breath() -> void:
	var dir = _get_direction_to_target()
	# 预警：直线
	WarningIndicator.create_line(get_tree().current_scene, global_position + dir * 80, dir, 200.0, 80.0, 0.4, 0, "line")

	await get_tree().create_timer(0.4).timeout

	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = global_position + dir * 80
	effect.effect_type = "line"
	effect.length = 200.0
	effect.width = 80.0
	effect.damage = attack_damage / 2
	effect.color = Color(1.0, 0.5, 0.0, 0.4)
	effect.rotation = dir.angle()
	effect.lifetime = 0.6
	get_tree().current_scene.add_child(effect)

	print("%s: 火焰吐息！" % enemy_name)

## 岩浆地面 - 圆形DOT区域（带预警）
func _attack_magma_ground() -> void:
	var target_pos = target.global_position if target else global_position + Vector2.RIGHT * 100
	# 预警：紫色持续区域
	WarningIndicator.create_circle(get_tree().current_scene, target_pos, 100.0, 0.5, 0, "area")

	await get_tree().create_timer(0.5).timeout

	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = target_pos
	effect.effect_type = "circle"
	effect.radius = 100.0
	effect.damage = attack_damage / 4
	effect.color = Color(1.0, 0.3, 0.0, 0.4)
	effect.lifetime = 3.0
	get_tree().current_scene.add_child(effect)

	# 对区域内玩家施加DOT
	for body in effect.get_overlapping_bodies():
		if body is Player:
			SkillSystem.apply_dot(body, magma_dot_damage, magma_dot_duration)

	print("%s: 岩浆地面！" % enemy_name)

## 火焰领域 - 持续光环伤害
func _attack_fire_domain() -> void:
	_domain_active = true
	boss_announcement.emit("火焰领域！")
	
	# 创建领域视觉
	_domain_visual = Node2D.new()
	add_child(_domain_visual)
	
	var segments = 24
	for i in segments:
		var angle = (TAU / segments) * i
		var rect = ColorRect.new()
		rect.size = Vector2(domain_radius * 0.15, 6)
		rect.color = Color(1.0, 0.4, 0.0, 0.2)
		rect.position = Vector2(cos(angle), sin(angle)) * domain_radius * 0.8 - rect.size / 2
		rect.rotation = angle
		_domain_visual.add_child(rect)
	
	# 5秒后关闭领域
	await get_tree().create_timer(5.0).timeout
	_domain_active = false
	if _domain_visual:
		_domain_visual.queue_free()
		_domain_visual = null
	
	print("%s: 火焰领域结束" % enemy_name)

## 火焰冲锋 - 直线冲刺
func _attack_fire_charge() -> void:
	if not target:
		return
	
	var dir = _get_direction_to_target()
	boss_announcement.emit("火焰冲锋！")
	
	# 冲刺动画
	var tween = create_tween()
	var target_pos = global_position + dir * 300
	tween.tween_property(self, "global_position", target_pos, 0.3)
	
	# 冲刺路径上的伤害
	await tween.finished
	
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = global_position
	effect.effect_type = "line"
	effect.length = 300.0
	effect.width = 60.0
	effect.damage = attack_damage
	effect.color = Color(1.0, 0.2, 0.0, 0.4)
	effect.rotation = dir.angle()
	effect.lifetime = 0.4
	get_tree().current_scene.add_child(effect)
	
	print("%s: 火焰冲锋！" % enemy_name)

## 陨石雨（阶段3大招，带预警）
func _attack_fire_meteor() -> void:
	boss_announcement.emit("陨石雨降临！")

	for i in meteor_count:
		var offset = Vector2(randf_range(-300, 300), randf_range(-300, 300))
		var meteor_pos = global_position + offset

		# 预警：圆形
		WarningIndicator.create_circle(get_tree().current_scene, meteor_pos, 70.0, 0.3, 0, "instant")

		await get_tree().create_timer(0.2).timeout

		var effect_script = preload("res://scripts/systems/skill_effect.gd")
		var effect = Area2D.new()
		effect.set_script(effect_script)
		effect.position = meteor_pos
		effect.effect_type = "circle"
		effect.radius = 70.0
		effect.damage = attack_damage / 2
		effect.color = Color(1.0, 0.3, 0.0, 0.5)
		effect.lifetime = 0.8
		get_tree().current_scene.add_child(effect)

	print("%s: 陨石雨！" % enemy_name)

## 火焰爆炸（阶段3大招）+ 易伤窗口
func _attack_fire_explosion() -> void:
	boss_announcement.emit("火焰爆炸！")
	
	# 全屏伤害
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)
	
	# 大范围视觉
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = global_position
	effect.effect_type = "circle"
	effect.radius = 350.0
	effect.damage = attack_damage / 2
	effect.color = Color(1.0, 0.1, 0.0, 0.3)
	effect.lifetime = 1.2
	get_tree().current_scene.add_child(effect)
	
	print("%s: 火焰爆炸！" % enemy_name)
	
	# 爆炸后易伤
	await get_tree().create_timer(1.2).timeout
	_start_vulnerability_window()

## 生成火焰投射物
func _spawn_fire_projectile(dir: Vector2, spd: float, dmg: int) -> void:
	var projectile_script = preload("res://scripts/systems/projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_script)
	projectile.position = global_position
	projectile.direction = dir
	projectile.speed = spd
	projectile.damage = dmg
	projectile.color = Color(1.0, 0.4, 0.0)
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	get_tree().current_scene.add_child(projectile)

## 获取到目标的方向
func _get_direction_to_target() -> Vector2:
	if target:
		return (target.global_position - global_position).normalized()
	return Vector2.RIGHT
