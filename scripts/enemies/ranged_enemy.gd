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

# 射击计时器
var shoot_timer: Timer

func _ready() -> void:
	super._ready()
	
	# 创建射击计时器
	shoot_timer = Timer.new()
	shoot_timer.wait_time = attack_cooldown
	shoot_timer.one_shot = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(func(): can_attack = true)
	
	_setup_visual()

func _setup_visual() -> void:
	if sprite and sprite.texture == null:
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(28, 28)
		color_rect.position = -color_rect.size / 2
		color_rect.color = Color(0.3, 0.7, 0.3)
		sprite.add_child(color_rect)
		sprite.region_enabled = false

## 远程AI逻辑
func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	
	if target:
		var distance = global_position.distance_to(target.global_position)
		
		if distance < flee_range:
			# 太近了，逃跑
			_flee_from_target()
		elif distance >= preferred_range_min and distance <= preferred_range_max:
			# 在理想射击距离，射击
			_shoot_at_target()
		elif distance < preferred_range_min:
			# 偏近，后退
			_flee_from_target()
		else:
			# 太远，靠近
			move_toward_target()
	else:
		patrol()

## 逃离目标
func _flee_from_target() -> void:
	var direction = (global_position - target.global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	sprite.flip_h = velocity.x < 0

## 向目标射击
func _shoot_at_target() -> void:
	# 面朝目标
	sprite.flip_h = target.global_position.x < global_position.x
	
	if not can_attack or is_dead:
		return
	
	can_attack = false
	shoot_timer.start()
	
	# 创建投射物
	_fire_projectile()

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
