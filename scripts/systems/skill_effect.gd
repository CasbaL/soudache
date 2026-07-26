## 技能效果脚本
## 用于AOE范围伤害：直线AOE、圆形AOE等
extends Area2D

# 属性
var effect_type: String = "line"  # "line" or "circle"
var length: float = 200.0
var width: float = 40.0
var radius: float = 100.0
var damage: int = 0
var color: Color = Color.WHITE
var lifetime: float = 0.5

# 内部变量
var _time_alive: float = 0.0
var _visual
var _collision: CollisionShape2D
var _has_damaged: bool = false

func _ready() -> void:
	# 创建碰撞形状
	_collision = CollisionShape2D.new()
	add_child(_collision)
	
	if effect_type == "line":
		_setup_line_aoe()
	else:
		_setup_circle_aoe()
	
	# 设置碰撞层（检测第2层的敌人）
	collision_layer = 0
	collision_mask = 2  # 第2层（敌人）
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	
	# 立即检测已有重叠
	_damage_overlapping()

func _setup_line_aoe() -> void:
	var shape = RectangleShape2D.new()
	shape.size = Vector2(length, width)
	_collision.shape = shape
	
	# 创建视觉
	_visual = ColorRect.new()
	_visual.size = Vector2(length, width)
	_visual.color = Color(color.r, color.g, color.b, 0.3)
	_visual.position = -_visual.size / 2
	add_child(_visual)

func _setup_circle_aoe() -> void:
	var shape = CircleShape2D.new()
	shape.radius = radius
	_collision.shape = shape
	
	# 创建视觉（用多个小矩形模拟圆形）
	_visual = Node2D.new()
	add_child(_visual)
	
	# 简单的圆形指示器
	var segments = 16
	for i in segments:
		var angle = (TAU / segments) * i
		var rect = ColorRect.new()
		rect.size = Vector2(radius * 0.3, 4)
		rect.color = Color(color.r, color.g, color.b, 0.3)
		rect.position = Vector2(cos(angle), sin(angle)) * radius * 0.7 - rect.size / 2
		rect.rotation = angle
		_visual.add_child(rect)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

## 对重叠的敌人造成伤害
func _damage_overlapping() -> void:
	if _has_damaged:
		return
	_has_damaged = true
	
	for body in get_overlapping_bodies():
		_apply_damage(body)

## 碰到物体
func _on_body_entered(body: Node2D) -> void:
	_apply_damage(body)

## 对目标应用伤害
func _apply_damage(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, false)
