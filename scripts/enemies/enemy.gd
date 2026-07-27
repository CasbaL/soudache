## 敌人基类
## 处理敌人AI、移动、攻击、受伤
class_name Enemy
extends CharacterBody2D

# AI状态枚举
enum AIState {
	IDLE,       # 空闲
	PATROL,     # 巡逻
	CHASE,      # 追击
	ATTACK,     # 攻击
	RETREAT,    # 后退（远程敌人用）
	STUNNED,    # 被定身
}

# 导出变量
@export var enemy_name: String = "竹妖"
@export var max_health: int = 200
@export var current_health: int = 200
@export var attack_damage: int = 50
@export var defense: int = 20
@export var speed: float = 100.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var detect_range: float = 200.0

# 掉落物
@export var drop_items: Array[Dictionary] = [
	{"id": "spirit_stone", "name": "灵石", "amount": [10, 30], "chance": 1.0},
	{"id": "herb", "name": "灵草", "amount": [1, 3], "chance": 0.5}
]

# 状态
var can_attack: bool = true
var is_dead: bool = false
var target: Node2D = null
var current_state: AIState = AIState.IDLE
var _stun_timer: float = 0.0

# 信号
signal health_changed(new_health: int)
signal died()
signal dropped_items(items: Array[Dictionary])

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var detect_area: Area2D = $DetectArea
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	# 初始化
	current_health = max_health
	
	# 连接信号
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	detect_area.body_entered.connect(_on_detect_area_body_entered)
	detect_area.body_exited.connect(_on_detect_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	# 设置计时器
	attack_timer.wait_time = attack_cooldown
	
	# 添加到敌人组
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 定身状态倒计时
	if current_state == AIState.STUNNED:
		_stun_timer -= delta
		if _stun_timer <= 0:
			_stun_timer = 0.0
			_change_state(AIState.CHASE if target else AIState.IDLE)
		return

	# 状态机
	match current_state:
		AIState.IDLE:
			_state_idle()
		AIState.PATROL:
			_state_patrol()
		AIState.CHASE:
			_state_chase()
		AIState.ATTACK:
			_state_attack()
		AIState.RETREAT:
			_state_retreat()

## 切换状态
func _change_state(new_state: AIState) -> void:
	current_state = new_state

## 空闲状态
func _state_idle() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	# 检测到目标时切换到追击
	if target:
		_change_state(AIState.CHASE)

## 巡逻状态
func _state_patrol() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if target:
		_change_state(AIState.CHASE)

## 追击状态
func _state_chase() -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	var distance = global_position.distance_to(target.global_position)

	# 进入攻击范围
	if distance <= attack_range:
		_change_state(AIState.ATTACK)
		return

	# 目标离开感知范围（1.5倍）
	if distance > detect_range * 1.5:
		target = null
		_change_state(AIState.IDLE)
		return

	# 移向目标
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	sprite.flip_h = velocity.x < 0

## 攻击状态
func _state_attack() -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	var distance = global_position.distance_to(target.global_position)

	# 目标离开攻击范围，追击
	if distance > attack_range * 1.2:
		_change_state(AIState.CHASE)
		return

	# 尝试攻击
	if can_attack:
		attack()

## 后退状态（远程敌人用）
func _state_retreat() -> void:
	if not target:
		_change_state(AIState.IDLE)
		return

	var distance = global_position.distance_to(target.global_position)

	# 后退到安全距离
	if distance >= attack_range * 0.8:
		_change_state(AIState.ATTACK)
		return

	# 远离目标
	var direction = (global_position - target.global_position).normalized()
	velocity = direction * speed * 0.7
	move_and_slide()
	sprite.flip_h = velocity.x < 0

## 施加定身
func apply_stun(duration: float) -> void:
	current_state = AIState.STUNNED
	_stun_timer = duration
	velocity = Vector2.ZERO

## 移向目标
func move_toward_target() -> void:
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# 更新朝向
	sprite.flip_h = velocity.x < 0

## 巡逻
func patrol() -> void:
	# 简单巡逻：随机移动
	velocity = Vector2.ZERO
	move_and_slide()

## 攻击
func attack() -> void:
	if not can_attack or is_dead:
		return
	
	can_attack = false
	attack_timer.start()
	
	# 播放攻击动画（如果存在）
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# 检测攻击区域内的玩家
	for body in attack_area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(attack_damage)

## 受伤（伤害已由攻击方通过公式计算）
func take_damage(damage: int, is_crit: bool = false) -> void:
	if is_dead:
		return

	current_health = max(0, current_health - damage)
	
	# 发送信号
	health_changed.emit(current_health)
	
	# 显示伤害数字
	show_damage_number(actual_damage, is_crit)
	
	# 播放受伤动画（如果存在）
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	# 设置目标为攻击者
	if target == null:
		target = get_tree().get_first_node_in_group("player")
	
	# 检查死亡
	if current_health <= 0:
		die()

## 死亡
func die() -> void:
	is_dead = true
	died.emit()
	
	# 掉落物品
	drop_loot()
	
	# 禁用碰撞
	set_physics_process(false)
	
	# 播放死亡动画（如果存在）
	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
	# 删除节点
	queue_free.call_deferred()

## 掉落物品
func drop_loot() -> void:
	var items: Array[Dictionary] = []
	
	for drop in drop_items:
		if randf() <= drop.chance:
			var amount = randi_range(drop.amount[0], drop.amount[1])
			items.append({
				"id": drop.id,
				"name": drop.name,
				"amount": amount
			})
	
	if items.size() > 0:
		dropped_items.emit(items)

## 显示伤害数字
func show_damage_number(damage: int, is_crit: bool = false) -> void:
	var type = "crit" if is_crit else "normal"
	DamageNumber.spawn(get_tree().current_scene, global_position, damage, type)

## 攻击计时器超时
func _on_attack_timer_timeout() -> void:
	can_attack = true

## 检测区域进入
func _on_detect_area_body_entered(body: Node2D) -> void:
	if body is Player:
		target = body

## 检测区域离开
func _on_detect_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null

## 攻击区域进入
func _on_attack_area_body_entered(_body: Node2D) -> void:
	# 在攻击区域内，可以攻击
	pass
