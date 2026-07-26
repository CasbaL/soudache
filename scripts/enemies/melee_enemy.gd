## 近战敌人
## 标准近战AI：追踪 → 接近后攻击
## 用于：竹妖、火灵、机关兽
class_name MeleeEnemy
extends Enemy

func _ready() -> void:
	super._ready()
	_setup_visual()

func _setup_visual() -> void:
	# 用彩色矩形代替精灵图
	if sprite and sprite.texture == null:
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(32, 32)
		color_rect.position = -color_rect.size / 2
		match enemy_name:
			"竹妖":
				color_rect.color = Color(0.2, 0.6, 0.2)
			"火灵":
				color_rect.color = Color(0.9, 0.3, 0.1)
			"机关兽":
				color_rect.color = Color(0.5, 0.5, 0.6)
			_:
				color_rect.color = Color(0.4, 0.4, 0.4)
		sprite.add_child(color_rect)
		sprite.region_enabled = false

## 近战AI：追到攻击范围内就攻击
func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	
	if target:
		var distance = global_position.distance_to(target.global_position)
		
		if distance <= attack_range:
			attack()
		else:
			move_toward_target()
	else:
		patrol()
