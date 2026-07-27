## 远程敌人
## 保持距离射击，玩家太近时逃跑
## 用于：竹妖射手
class_name RangedEnemy
extends Enemy

# 远程参数
@export var preferred_range_min: float = 150.0
@export var preferred_range_max: float = 200.0
@export var flee_range: float = 100.0
@export var projectile_speed: float = 250.0
@export var projectile_color: Color = Color(0.3, 0.8, 0.3)

func _ready() -> void:
	super._ready()
	_setup_visual()

func _setup_visual() -> void:
	if sprite and sprite.texture == null:
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(28, 28)
		color_rect.position = -color_rect.size / 2
		color_rect.color = Color(0.3, 0.7, 0.3)
		sprite.add_child(color_rect)
		sprite.region_enabled = false

## 追击状态（远程敌人覆盖：保持距离）
func _state_chase() -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	var distance = global_position.distance_to(target.global_position)

	# 太近了，后退
	if distance < flee_range:
		_change_state(AIState.RETREAT)
		return

	# 在射击范围内，攻击
	if distance <= preferred_range_max:
		_change_state(AIState.ATTACK)
		return

	# 目标离开感知范围
	if distance > detect_range * 1.5:
		target = null
		_change_state(AIState.IDLE)
		return

	# 移向目标
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	sprite.flip_h = velocity.x < 0

## 攻击状态（远程敌人覆盖：射击）
func _state_attack() -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	var distance = global_position.distance_to(target.global_position)

	# 太近了，后退
	if distance < flee_range:
		_change_state(AIState.RETREAT)
		return

	# 太远了，追击
	if distance > preferred_range_max * 1.3:
		_change_state(AIState.CHASE)
		return

	# 面朝目标
	sprite.flip_h = target.global_position.x < global_position.x

	# 射击
	if can_attack:
		can_attack = false
		attack_timer.start()
		_fire_projectile()

## 后退状态（远程敌人覆盖：后退到理想距离）
func _state_retreat() -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	var distance = global_position.distance_to(target.global_position)

	# 后退到理想距离
	if distance >= preferred_range_min:
		_change_state(AIState.ATTACK)
		return

	# 远离目标
	var direction = (global_position - target.global_position).normalized()
	velocity = direction * speed * 0.7
	move_and_slide()
	sprite.flip_h = velocity.x < 0

## 发射投射物
func _fire_projectile() -> void:
	var direction = (target.global_position - global_position).normalized()

	var projectile_scene = preload("res://scripts/systems/projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_scene)
	projectile.position = global_position
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = attack_damage
	projectile.color = projectile_color

	# 敌人投射物检测玩家
	projectile.collision_layer = 0
	projectile.collision_mask = 1  # 第1层（玩家）

	get_tree().current_scene.add_child(projectile)
