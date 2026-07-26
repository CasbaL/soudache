## 资源物品
## 可收集的资源（灵石、灵草、矿石等）
class_name ResourceItem
extends Area2D

# 物品数据
@export var item_id: String = "spirit_stone"
@export var item_name: String = "灵石"
@export var item_amount: int = 10
@export var collect_range: float = 50.0

# 动画参数
@export var float_amplitude: float = 5.0
@export var float_speed: float = 2.0
@export var collect_speed: float = 300.0

# 状态
var is_collecting: bool = false
var target_position: Vector2 = Vector2.ZERO
var base_y: float = 0.0

# 信号
signal collected(item_id: String, amount: int)

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var collect_timer: Timer = $CollectTimer

func _ready() -> void:
	# 初始化
	base_y = position.y
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	collect_timer.timeout.connect(_on_collect_timer_timeout)
	
	# 设置碰撞层
	collision_layer = 4  # 资源层
	collision_mask = 1   # 玩家层

func _process(_delta: float) -> void:
	if is_collecting:
		# 飞向玩家
		var direction = (target_position - global_position).normalized()
		global_position += direction * collect_speed * _delta
		
		# 检查是否到达
		if global_position.distance_to(target_position) < 10:
			collect()
	else:
		# 浮动动画
		position.y = base_y + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_amplitude

## 收集
func collect() -> void:
	collected.emit(item_id, item_amount)
	queue_free.call_deferred()

## 开始收集（飞向玩家）
func start_collect(player_position: Vector2) -> void:
	is_collecting = true
	target_position = player_position
	
	# 禁用碰撞
	collision.set_deferred("disabled", true)

## 玩家进入收集范围
func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_collecting:
		# 添加到背包
		var item_data = {
			"id": item_id,
			"name": item_name,
			"amount": item_amount
		}
		
		if GameManager.add_to_inventory(item_data):
			# 收集成功，飞向玩家
			start_collect(body.global_position)
		else:
			# 背包已满
			print("背包已满，无法收集 %s" % item_name)

## 收集计时器超时
func _on_collect_timer_timeout() -> void:
	# 超时自动消失
	queue_free.call_deferred()
