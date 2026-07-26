## 竹妖王 Boss
## 阶段1：竹叶扫射、毒息、竹刺
## 阶段2：召唤3个分身、根须陷阱
## 阶段3：全场竹风暴 + 易伤窗口
class_name BambooKing
extends BossEnemy

# 竹妖王特定参数
var clone_count: int = 3
var storm_damage: int = 30
var poison_dot_damage: int = 20
var poison_dot_duration: float = 5.0

func _ready() -> void:
	enemy_name = "竹妖王"
	max_health = 8000
	current_health = max_health
	attack_damage = 150
	defense = 50
	speed = 70.0
	attack_range = 80.0
	attack_cooldown = 0.6
	detect_range = 500.0
	
	phases = [
		{"name": "竹叶风暴", "healthRange": [100, 70], "attacks": ["leaf_sweep", "poison_breath", "bamboo_spike"]},
		{"name": "竹林幻影", "healthRange": [70, 40], "attacks": ["leaf_sweep", "poison_breath", "bamboo_spike", "bamboo_clone", "root_trap"]},
		{"name": "狂暴竹妖", "healthRange": [40, 0], "attacks": ["bamboo_storm", "leaf_sweep", "poison_breath", "bamboo_spike", "bamboo_clone", "root_trap"]}
	]
	
	drop_items = [
		{"id": "spirit_stone", "name": "灵石", "amount": [200, 300], "chance": 1.0},
		{"id": "bamboo_demon_core", "name": "竹妖内丹", "rarity": "blue", "chance": 1.0},
		{"id": "bamboo_demon_soul", "name": "竹妖王魂", "rarity": "purple", "chance": 0.3},
		{"id": "technique_fragment", "name": "功法残页", "amount": [2, 5], "chance": 0.5}
	]
	
	super._ready()
	_setup_boss_visual()

func _setup_boss_visual() -> void:
	if sprite and sprite.texture == null:
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(64, 64)
		color_rect.position = -color_rect.size / 2
		color_rect.color = Color(0.1, 0.5, 0.1)
		sprite.add_child(color_rect)
		sprite.region_enabled = false

## 竹妖王攻击执行
func execute_attack(attack_name: String) -> void:
	match attack_name:
		"leaf_sweep":
			_attack_leaf_sweep()
		"poison_breath":
			_attack_poison_breath()
		"bamboo_spike":
			_attack_bamboo_spike()
		"bamboo_clone":
			_attack_bamboo_clone()
		"root_trap":
			_attack_root_trap()
		"bamboo_storm":
			_attack_bamboo_storm()

## 阶段进入行为
func _on_phase_enter(phase: int) -> void:
	match phase:
		1:
			boss_announcement.emit("竹林幻影降临！")
		2:
			boss_announcement.emit("狂暴竹妖觉醒！")
			# 阶段3加速
			attack_cooldown = 0.4
			speed = 90.0

## 竹叶扫射 - 扇形AOE
func _attack_leaf_sweep() -> void:
	var base_dir = _get_direction_to_target()
	var leaf_count = 5
	var spread_angle = deg_to_rad(60)
	
	for i in leaf_count:
		var angle = base_dir.angle() - spread_angle / 2 + (spread_angle / (leaf_count - 1)) * i
		var dir = Vector2.from_angle(angle)
		_spawn_leaf_projectile(dir)
	
	print("%s: 竹叶扫射！" % enemy_name)

## 毒息 - 直线DOT
func _attack_poison_breath() -> void:
	var dir = _get_direction_to_target()
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = global_position + dir * 60
	effect.effect_type = "line"
	effect.length = 250.0
	effect.width = 50.0
	effect.damage = attack_damage / 2
	effect.color = Color(0.2, 0.8, 0.2, 0.4)
	effect.rotation = dir.angle()
	effect.lifetime = 0.8
	get_tree().current_scene.add_child(effect)
	
	# DOT效果
	for body in effect.get_overlapping_bodies():
		if body is Player:
			SkillSystem.apply_dot(body, poison_dot_damage, poison_dot_duration)
	
	print("%s: 毒息！" % enemy_name)

## 竹刺 - 圆形AOE
func _attack_bamboo_spike() -> void:
	var target_pos = target.global_position if target else global_position + Vector2.RIGHT * 100
	
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = target_pos
	effect.effect_type = "circle"
	effect.radius = 80.0
	effect.damage = attack_damage
	effect.color = Color(0.3, 0.7, 0.3, 0.4)
	effect.lifetime = 0.6
	get_tree().current_scene.add_child(effect)
	
	print("%s: 竹刺！" % enemy_name)

## 召唤分身
func _attack_bamboo_clone() -> void:
	summon_minions(clone_count, 120.0)
	boss_announcement.emit("分身现！")
	print("%s: 召唤竹妖分身！" % enemy_name)

## 根须陷阱 - 随机位置圆形AOE
func _attack_root_trap() -> void:
	var trap_count = 3
	for i in trap_count:
		var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
		var trap_pos = global_position + offset
		
		var effect_script = preload("res://scripts/systems/skill_effect.gd")
		var effect = Area2D.new()
		effect.set_script(effect_script)
		effect.position = trap_pos
		effect.effect_type = "circle"
		effect.radius = 60.0
		effect.damage = attack_damage / 2
		effect.color = Color(0.4, 0.2, 0.0, 0.4)
		effect.lifetime = 1.0
		get_tree().current_scene.add_child(effect)
	
	print("%s: 根须陷阱！" % enemy_name)

## 全场竹风暴（阶段3大招） + 易伤窗口
func _attack_bamboo_storm() -> void:
	boss_announcement.emit("竹风暴降临！")
	
	# 全屏风暴伤害
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(storm_damage)
	
	# 创建大范围视觉效果
	var effect_script = preload("res://scripts/systems/skill_effect.gd")
	var effect = Area2D.new()
	effect.set_script(effect_script)
	effect.position = global_position
	effect.effect_type = "circle"
	effect.radius = 400.0
	effect.damage = storm_damage
	effect.color = Color(0.1, 0.6, 0.1, 0.2)
	effect.lifetime = 1.5
	get_tree().current_scene.add_child(effect)
	
	print("%s: 全场竹风暴！" % enemy_name)
	
	# 风暴后进入易伤
	await get_tree().create_timer(1.5).timeout
	_start_vulnerability_window()

## 叶片投射物
func _spawn_leaf_projectile(dir: Vector2) -> void:
	var projectile_script = preload("res://scripts/systems/projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_script)
	projectile.position = global_position
	projectile.direction = dir
	projectile.speed = 200.0
	projectile.damage = attack_damage / 3
	projectile.color = Color(0.3, 0.8, 0.3)
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	get_tree().current_scene.add_child(projectile)

## 获取到目标的方向
func _get_direction_to_target() -> Vector2:
	if target:
		return (target.global_position - global_position).normalized()
	return Vector2.RIGHT
