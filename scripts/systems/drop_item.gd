## 掉落物实体
## 敌人死亡后掉落的物品，玩家接近自动拾取
class_name DropItem
extends Area2D

# 掉落物数据
var item_id: String = ""
var item_name: String = ""
var item_amount: int = 1
var item_rarity: String = "white"

# 稀有度颜色
const RARITY_COLORS: Dictionary = {
	"white": Color(0.8, 0.8, 0.8),
	"green": Color(0.2, 0.8, 0.2),
	"blue": Color(0.2, 0.4, 1.0),
	"purple": Color(0.6, 0.2, 0.8),
	"gold": Color(1.0, 0.8, 0.0),
}

# 动画参数
var _target_pos: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _gravity: float = 400.0
var _is_landed: bool = false
var _bounce_count: int = 0
var _max_bounces: int = 2

# 自动拾取
var _can_pickup: bool = false
var _pickup_delay: float = 0.3

func _ready() -> void:
	# 碰撞设置
	collision_layer = 0
	collision_mask = 1  # 检测玩家

	# 连接信号
	body_entered.connect(_on_body_entered)

	# 延迟后可拾取
	await get_tree().create_timer(_pickup_delay).timeout
	_can_pickup = true

func _physics_process(delta: float) -> void:
	if _is_landed:
		return

	# 抛物线运动
	_velocity.y += _gravity * delta
	position += _velocity * delta

	# 简单的地面碰撞（假设地面在初始位置下方）
	if position.y >= _target_pos.y:
		position.y = _target_pos.y
		_bounce_count += 1
		if _bounce_count >= _max_bounces:
			_is_landed = true
			_velocity = Vector2.ZERO
		else:
			_velocity.y = -_velocity.y * 0.4
			_velocity.x *= 0.6

## 初始化掉落物
func setup(id: String, name_val: String, amount: int, rarity: String = "white") -> void:
	item_id = id
	item_name = name_val
	item_amount = amount
	item_rarity = rarity

	# 设置视觉
	_setup_visual()

## 设置视觉效果
func _setup_visual() -> void:
	var color = RARITY_COLORS.get(item_rarity, Color.WHITE)

	# 物品图标（简单的颜色方块）
	var icon = ColorRect.new()
	icon.size = Vector2(12, 12)
	icon.position = -icon.size / 2
	icon.color = color
	add_child(icon)

	# 稀有度光晕（紫色以上）
	if item_rarity in ["purple", "gold"]:
		var glow = ColorRect.new()
		glow.size = Vector2(18, 18)
		glow.position = -glow.size / 2
		glow.color = Color(color.r, color.g, color.b, 0.3)
		glow.z_index = -1
		add_child(glow)

## 弹出动画
func pop_out(from_pos: Vector2) -> void:
	position = from_pos
	_target_pos = from_pos + Vector2(randf_range(-30, 30), randf_range(10, 30))

	# 随机弹出方向
	var angle = randf_range(-PI * 0.8, -PI * 0.2)
	var force = randf_range(150, 250)
	_velocity = Vector2(cos(angle), sin(angle)) * force

## 玩家拾取
func _on_body_entered(body: Node2D) -> void:
	if not _can_pickup:
		return
	if not body is Player:
		return

	# 添加到背包
	var item = {
		"id": item_id,
		"name": item_name,
		"amount": item_amount,
	}
	if GameManager.add_to_inventory(item):
		# 拾取动画
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_property(self, "position:y", position.y - 20, 0.15)
		tween.tween_callback(queue_free)
	else:
		# 背包满了
		print("背包已满，无法拾取 %s" % item_name)

## 工厂方法：创建掉落物
static func create_drop(parent: Node, from_pos: Vector2, id: String, name_val: String, amount: int, rarity: String = "white") -> DropItem:
	var drop = DropItem.new()
	drop.setup(id, name_val, amount, rarity)
	parent.add_child(drop)
	drop.pop_out(from_pos)
	return drop
