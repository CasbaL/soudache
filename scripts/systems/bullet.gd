## 敌人子弹脚本
## 用于Boss和远程敌人发射的弹幕
class_name Bullet
extends Area2D

# 子弹类型枚举
enum BulletType {
	NORMAL,      # 直线飞行
	HOMING,      # 追踪玩家
	ACCELERATING,# 加速飞行
	PIERCING,    # 穿透
	EXPLOSIVE    # 爆炸伤害
}

# 属性
var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var damage: int = 50
var color: Color = Color(1.0, 0.3, 0.2)  # 红橙色
var bullet_type: BulletType = BulletType.NORMAL
var lifetime: float = 5.0
var radius: float = 6.0

# 追踪参数
var homing_strength: float = 2.0  # 追踪转向速度(弧度/秒)
var _target: Node2D = null

# 加速参数
var acceleration: float = 100.0
var max_speed: float = 500.0

# 爆炸参数
var explosion_radius: float = 60.0
var explosion_color: Color = Color(1.0, 0.5, 0.0, 0.4)

# 穿透参数
var pierce_count: int = 3
var _pierce_hit: int = 0

# 内部变量
var _time_alive: float = 0.0
var _collision: CollisionShape2D
var _hit: bool = false

# 回收回调（由对象池设置）
var recycle_callback: Callable = Callable()

# 信号
signal bullet_hit(target: Node2D)

func _ready() -> void:
	# 创建碰撞形状
	var shape = CircleShape2D.new()
	shape.radius = radius
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	add_child(_collision)
	
	# 设置碰撞层（敌人子弹在第6层，检测第1层的玩家）
	collision_layer = 32  # 第6层
	collision_mask = 1    # 第1层（玩家）
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 旋转朝向
	rotation = direction.angle()
	
	# 请求重绘
	queue_redraw()

func _draw() -> void:
	# 绘制子弹圆形
	draw_circle(Vector2.ZERO, radius, color)
	# 绘制高光
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.3, Color(1, 1, 1, 0.5))

func _physics_process(delta: float) -> void:
	if _hit:
		return
	
	# 根据子弹类型更新方向
	match bullet_type:
		BulletType.HOMING:
			_update_homing(delta)
		BulletType.ACCELERATING:
			speed = min(speed + acceleration * delta, max_speed)
	
	# 移动
	position += direction * speed * delta
	
	# 生命周期
	_time_alive += delta
	if _time_alive >= lifetime:
		_recycle()

## 追踪更新
func _update_homing(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = _find_player()
		if not is_instance_valid(_target):
			return
	
	var to_target = (_target.global_position - global_position).normalized()
	var current_angle = direction.angle()
	var target_angle = to_target.angle()
	var new_angle = lerp_angle(current_angle, target_angle, homing_strength * delta)
	direction = Vector2.from_angle(new_angle)
	rotation = new_angle

## 查找玩家
func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

## 碰到物体（玩家）
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_hit_player(body)

## 碰到区域（玩家的受击区域）
func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Player:
		_hit_player(parent)

## 对玩家造成伤害
func _hit_player(player: Node2D) -> void:
	if not player.has_method("take_damage"):
		return
	
	player.take_damage(damage)
	bullet_hit.emit(player)
	
	match bullet_type:
		BulletType.PIERCING:
			_pierce_hit += 1
			if _pierce_hit >= pierce_count:
				_recycle()
		BulletType.EXPLOSIVE:
			_explode()
		_:
			_recycle()

## 爆炸效果
func _explode() -> void:
	# 检测爆炸范围内的玩家
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if global_position.distance_to(player.global_position) <= explosion_radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)
	
	# 创建爆炸视觉效果（简化版，仅显示一个短暂的圆形）
	_recycle()

## 设置追踪目标
func set_target(target: Node2D) -> void:
	_target = target

## 回收子弹（回到对象池）
func _recycle() -> void:
	if recycle_callback.is_valid():
		recycle_callback.call(self)
	else:
		queue_free()
