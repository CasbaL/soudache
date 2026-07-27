## 玩家角色控制器
## 处理移动、攻击、技能、闪避
class_name Player
extends CharacterBody2D

# 导出变量，可在编辑器中调整
@export var speed: float = 200.0
@export var max_health: int = 500
@export var current_health: int = 500
@export var attack_damage: int = 100
@export var defense: int = 50
@export var crit_rate: float = 0.05
@export var crit_damage: float = 1.5

# 闪避参数
@export var dodge_speed: float = 400.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.5

# 技能参数
@export var skill_1_cooldown: float = 5.0
@export var skill_2_cooldown: float = 8.0
@export var skill_3_cooldown: float = 12.0

# 状态
var is_dodging: bool = false
var is_invincible: bool = false
var can_dodge: bool = true
var can_use_skill_1: bool = true
var can_use_skill_2: bool = true
var can_use_skill_3: bool = true

# 闪避方向
var dodge_direction: Vector2 = Vector2.ZERO

# 虚拟摇杆输入
var joystick_direction: Vector2 = Vector2.ZERO

# 信号
signal health_changed(new_health: int)
signal died()
signal skill_used(skill_index: int)

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var dodge_timer: Timer = $DodgeTimer
@onready var skill_1_timer: Timer = $Skill1Timer
@onready var skill_2_timer: Timer = $Skill2Timer
@onready var skill_3_timer: Timer = $Skill3Timer
@onready var invincible_timer: Timer = $InvincibleTimer

# 门派普攻配置（由 _apply_faction_stats 设置）
var faction_attack_type: String = "melee_swing"
var faction_attack_range: float = 80.0
var faction_attack_speed: float = 0.3
var faction_attack_combo: int = 3
var faction_attack_combo_interval: float = 0.15
var faction_attack_cd_accum: float = 0.0
var faction_combo_count: int = 0

func _ready() -> void:
	# 初始化
	current_health = max_health
	add_to_group("player")
	
	# 连接信号
	dodge_timer.timeout.connect(_on_dodge_timer_timeout)
	skill_1_timer.timeout.connect(_on_skill_1_timer_timeout)
	skill_2_timer.timeout.connect(_on_skill_2_timer_timeout)
	skill_3_timer.timeout.connect(_on_skill_3_timer_timeout)
	invincible_timer.timeout.connect(_on_invincible_timer_timeout)
	
	# 应用门派基础属性
	_apply_faction_stats()
	
	# 从技能系统读取冷却时间
	dodge_timer.wait_time = dodge_cooldown
	var skill1 = SkillSystem.get_skill_by_slot(1)
	var skill2 = SkillSystem.get_skill_by_slot(2)
	var skill3 = SkillSystem.get_skill_by_slot(3)
	if not skill1.is_empty():
		skill_1_timer.wait_time = skill1.get("cooldown", skill_1_cooldown)
	if not skill2.is_empty():
		skill_2_timer.wait_time = skill2.get("cooldown", skill_2_cooldown)
	if not skill3.is_empty():
		skill_3_timer.wait_time = skill3.get("cooldown", skill_3_cooldown)
	
	# 应用装备属性加成
	_apply_equipment_stats()
	if has_node("/root/EquipmentSystem"):
		EquipmentSystem.equipment_changed.connect(_on_equipment_changed)

func _physics_process(delta: float) -> void:
	if is_dodging:
		# 闪避中，按闪避方向移动
		velocity = dodge_direction * dodge_speed
	else:
		# 正常移动：优先使用虚拟摇杆输入，其次键盘输入
		var input_vector = joystick_direction
		if input_vector == Vector2.ZERO:
			input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_vector * speed

		# 更新朝向
		if input_vector.x != 0:
			sprite.flip_h = input_vector.x < 0

	move_and_slide()

	# 自动攻击最近的敌人
	if not is_dodging:
		auto_attack(delta)

## 自动攻击（根据门派不同行为不同）
func auto_attack(delta: float) -> void:
	faction_attack_cd_accum += delta
	if faction_attack_cd_accum < faction_attack_speed:
		return
	
	var nearest_enemy = find_nearest_enemy()
	if nearest_enemy == null:
		return
	
	var dist = nearest_enemy.global_position.distance_to(global_position)
	if dist > faction_attack_range:
		return
	
	faction_attack_cd_accum = 0.0
	
	match faction_attack_type:
		"melee_swing":
			_attack_melee_swing(nearest_enemy)
		"ranged_projectile":
			_attack_ranged_projectile(nearest_enemy)
		"medium_throw":
			_attack_medium_throw(nearest_enemy)
		_:
			attack_enemy(nearest_enemy)

## 查找最近的敌人
func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var min_distance = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

## 攻击敌人（基础伤害计算）
func attack_enemy(enemy: Node2D, damage_mult: float = 1.0) -> void:
	var target_defense = enemy.get("defense") if "defense" in enemy else 0
	var result = GameManager.calculate_damage(attack_damage, damage_mult, target_defense, crit_rate, crit_damage)
	var damage = result.damage
	var is_crit = result.is_crit

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, is_crit)

	# 暴击反馈：屏幕震动
	if is_crit:
		CombatFeedback.shake_on_crit()

	# 攻击时增加大招充能
	FactionSystem.add_ultimate_charge(damage * 0.1)
	
	if animation_player.has_animation("attack"):
		animation_player.play("attack")

## 近战三连斩（剑修普攻）
func _attack_melee_swing(enemy: Node2D) -> void:
	faction_combo_count = (faction_combo_count + 1) % faction_attack_combo
	var mult = 1.0 if faction_combo_count < 2 else 1.5
	attack_enemy(enemy, mult)

## 远程投射物（符修普攻）
func _attack_ranged_projectile(enemy: Node2D) -> void:
	var aa = FactionSystem.get_auto_attack_config()
	var dir = (enemy.global_position - global_position).normalized()
	
	var projectile_scene = preload("res://scripts/systems/projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_scene)
	projectile.position = global_position
	projectile.direction = dir
	projectile.speed = aa.get("projectile_speed", 350.0)
	projectile.damage = int(attack_damage * aa.get("damage_multiplier", 0.8))
	projectile.color = Color(aa.get("projectile_color", "#4169E1"))
	
	get_tree().current_scene.add_child(projectile)
	
	if animation_player.has_animation("attack"):
		animation_player.play("attack")

## 中程投掷（丹修普攻）
func _attack_medium_throw(enemy: Node2D) -> void:
	var aa = FactionSystem.get_auto_attack_config()
	var dir = (enemy.global_position - global_position).normalized()
	
	var projectile_scene = preload("res://scripts/systems/projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_scene)
	projectile.position = global_position
	projectile.direction = dir
	projectile.speed = aa.get("projectile_speed", 280.0)
	projectile.damage = int(attack_damage * aa.get("damage_multiplier", 0.9))
	projectile.color = Color(aa.get("projectile_color", "#32CD32"))
	
	get_tree().current_scene.add_child(projectile)
	
	if animation_player.has_animation("attack"):
		animation_player.play("attack")

## 闪避
func dodge() -> void:
	if not can_dodge or is_dodging:
		return
	
	# 计算闪避方向
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector == Vector2.ZERO:
		dodge_direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	else:
		dodge_direction = input_vector.normalized()
	
	# 开始闪避
	is_dodging = true
	is_invincible = true
	can_dodge = false
	
	# 播放闪避动画（如果存在）
	if animation_player.has_animation("dodge"):
		animation_player.play("dodge")
	
	# 启动计时器
	dodge_timer.start()
	invincible_timer.start(dodge_duration)

## 使用技能1
func use_skill_1() -> void:
	var direction = _get_skill_direction()
	
	if SkillSystem.use_skill(1, self, direction):
		skill_used.emit(1)
		if animation_player.has_animation("skill_1"):
			animation_player.play("skill_1")

## 使用技能2
func use_skill_2() -> void:
	var direction = _get_skill_direction()
	
	if SkillSystem.use_skill(2, self, direction):
		skill_used.emit(2)
		if animation_player.has_animation("skill_2"):
			animation_player.play("skill_2")

## 使用技能3
func use_skill_3() -> void:
	var direction = _get_skill_direction()
	
	if SkillSystem.use_skill(3, self, direction):
		skill_used.emit(3)
		if animation_player.has_animation("skill_3"):
			animation_player.play("skill_3")

## 获取技能释放方向
func _get_skill_direction() -> Vector2:
	# 优先朝向最近的敌人
	var nearest = find_nearest_enemy()
	if nearest:
		return (nearest.global_position - global_position).normalized()
	
	# 否则朝向面朝方向
	if sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT

## 受伤（伤害已由攻击方通过公式计算，包含防御减免）
func take_damage(damage: int, is_crit: bool = false) -> void:
	if is_invincible:
		return

	# 护盾吸收
	var remaining_damage = SkillSystem.absorb_damage(self, damage)
	if remaining_damage <= 0:
		show_damage_number(damage, false, false, true)
		return

	# 直接应用伤害（防御已在攻击方计算）
	current_health = max(0, current_health - remaining_damage)

	# 受伤增加大招充能
	FactionSystem.add_ultimate_charge(remaining_damage * 0.15)

	# 发送信号
	health_changed.emit(current_health)

	# 显示伤害数字
	show_damage_number(remaining_damage, is_crit)

	# 战斗反馈：受击闪红 + 屏幕震动
	CombatFeedback.flash_hit_effect(self)
	CombatFeedback.shake_on_hit()

	# 播放受伤动画（如果存在）
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	# 短暂无敌
	is_invincible = true
	invincible_timer.start(0.5)
	
	# 检查死亡
	if current_health <= 0:
		die()

## 治疗
func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)
	show_damage_number(amount, false, true)

## 死亡
func die() -> void:
	died.emit()
	
	# 播放死亡动画（如果存在）
	if animation_player.has_animation("die"):
		animation_player.play("die")
	
	# 禁用输入
	set_physics_process(false)
	
	# 通知游戏管理器
	GameManager.game_over()

## 显示伤害数字
func show_damage_number(damage: int, is_crit: bool = false, is_heal: bool = false, is_shield: bool = false) -> void:
	var type = "normal"
	if is_shield:
		type = "shield"
	elif is_heal:
		type = "heal"
	elif is_crit:
		type = "crit"
	DamageNumber.spawn(get_tree().current_scene, global_position, damage, type)

## 闪避计时器超时
func _on_dodge_timer_timeout() -> void:
	is_dodging = false
	can_dodge = true

## 技能1计时器超时
func _on_skill_1_timer_timeout() -> void:
	can_use_skill_1 = true

## 技能2计时器超时
func _on_skill_2_timer_timeout() -> void:
	can_use_skill_2 = true

## 技能3计时器超时
func _on_skill_3_timer_timeout() -> void:
	can_use_skill_3 = true

## 无敌计时器超时
func _on_invincible_timer_timeout() -> void:
	is_invincible = false

## 装备变化时重新应用属性
func _on_equipment_changed(_slot: int) -> void:
	_apply_equipment_stats()

## 应用门派基础属性
func _apply_faction_stats() -> void:
	var faction_id = FactionSystem.get_current_faction()
	if faction_id == "":
		# 未选择门派，使用默认值
		return
	
	var stats = FactionSystem._faction_data_instance.get_stats(faction_id)
	max_health = stats.get("max_health", 500)
	current_health = max_health
	attack_damage = stats.get("attack", 100)
	defense = stats.get("defense", 50)
	speed = stats.get("speed", 200.0)
	crit_rate = stats.get("crit_rate", 0.05)
	crit_damage = stats.get("crit_damage", 1.5)
	dodge_speed = stats.get("dodge_speed", 400.0)
	
	# 普攻配置
	var aa = FactionSystem._faction_data_instance.get_auto_attack(faction_id)
	faction_attack_type = aa.get("type", "melee_swing")
	faction_attack_range = stats.get("attack_range", 80.0)
	faction_attack_speed = aa.get("attack_speed", stats.get("attack_speed", 0.3))
	faction_attack_combo = aa.get("combo_hits", 1)
	faction_attack_combo_interval = aa.get("combo_interval", 0.15)
	
	# 更新技能冷却
	var skill1 = SkillSystem.get_skill_by_slot(1)
	var skill2 = SkillSystem.get_skill_by_slot(2)
	var skill3 = SkillSystem.get_skill_by_slot(3)
	if not skill1.is_empty() and skill_1_timer:
		skill_1_timer.wait_time = skill1.get("cooldown", skill_1_cooldown)
	if not skill2.is_empty() and skill_2_timer:
		skill_2_timer.wait_time = skill2.get("cooldown", skill_2_cooldown)
	if not skill3.is_empty() and skill_3_timer:
		skill_3_timer.wait_time = skill3.get("cooldown", skill_3_cooldown)
	
	health_changed.emit(current_health)

## 应用装备属性加成（重置为基础值后叠加）
func _apply_equipment_stats() -> void:
	# 门派基础值
	var base_attack := 100
	var base_defense := 50
	var base_max_health := 500
	var base_crit := 0.05
	
	var faction_id = FactionSystem.get_current_faction()
	if faction_id != "":
		var stats = FactionSystem._faction_data_instance.get_stats(faction_id)
		base_attack = stats.get("attack", 100)
		base_defense = stats.get("defense", 50)
		base_max_health = stats.get("max_health", 500)
		base_crit = stats.get("crit_rate", 0.05)
	elif has_node("/root/GameManager"):
		base_attack = GameManager.player_data.get("attack", 100)
		base_defense = GameManager.player_data.get("defense", 50)
		base_max_health = GameManager.player_data.get("max_health", 500)
		base_crit = GameManager.player_data.get("crit_rate", 0.05)

	# 重置为基础值
	attack_damage = base_attack
	defense = base_defense
	max_health = base_max_health
	crit_rate = base_crit

	# 叠加装备加成
	if has_node("/root/EquipmentSystem"):
		EquipmentSystem.apply_stats_to_player(self)

	current_health = min(current_health, max_health)
	health_changed.emit(current_health)

## 使用大招
func use_ultimate() -> void:
	if FactionSystem.is_ultimate_ready():
		FactionSystem.use_ultimate(self)
		if animation_player.has_animation("skill_3"):
			animation_player.play("skill_3")

## 设置虚拟摇杆输入
func set_joystick_input(direction: Vector2) -> void:
	joystick_direction = direction

## 输入处理
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge"):
		dodge()
	elif event.is_action_pressed("skill_1"):
		use_skill_1()
	elif event.is_action_pressed("skill_2"):
		use_skill_2()
	elif event.is_action_pressed("skill_3"):
		use_skill_3()
	elif event.is_action_pressed("ultimate"):
		use_ultimate()
