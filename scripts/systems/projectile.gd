## 投射物脚本
## 用于飞行道具：剑气、符咒、毒丹等
extends Area2D

# 属性
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: int = 0
var color: Color = Color.WHITE
var stun_duration: float = 0.0
var dot_damage: float = 0.0
var dot_duration: float = 0.0
var lifetime: float = 5.0

# 内部变量
var _time_alive: float = 0.0
var _visual: ColorRect
var _collision: CollisionShape2D

func _ready() -> void:
	# 创建视觉
	_visual = ColorRect.new()
	_visual.size = Vector2(20, 8)
	_visual.color = color
	_visual.position = -_visual.size / 2
	add_child(_visual)
	
	# 创建碰撞
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 8)
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	add_child(_collision)
	
	# 设置碰撞层（投射物在第5层，检测第2层的敌人）
	collision_layer = 16  # 第5层
	collision_mask = 2    # 第2层（敌人）
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 旋转朝向
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# 移动
	position += direction * speed * delta
	
	# 生命周期
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

## 碰到物体
func _on_body_entered(body: Node2D) -> void:
	# 检查是否是敌人
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, false)
		
		# 应用定身
		if stun_duration > 0:
			SkillSystem.apply_stun(body, stun_duration)
		
		# 应用DOT
		if dot_damage > 0 and dot_duration > 0:
			SkillSystem.apply_dot(body, dot_damage, dot_duration)
		
		# 击中后消失
		queue_free()

## 碰到区域
func _on_area_entered(area: Area2D) -> void:
	# 检查区域的父节点是否是敌人
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage, false)
		
		if stun_duration > 0:
			SkillSystem.apply_stun(parent, stun_duration)
		
		if dot_damage > 0 and dot_duration > 0:
			SkillSystem.apply_dot(parent, dot_damage, dot_duration)
		
		queue_free()
