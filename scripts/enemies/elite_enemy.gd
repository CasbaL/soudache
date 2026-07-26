## 精英敌人
## 有伤害护盾，护盾在未受伤5秒后恢复
## 用于：竹妖精英、火焰巨人、机关傀儡
class_name EliteEnemy
extends Enemy

# 护盾参数
@export var shield_max: int = 300
var shield_current: int = 0
var shield_regen_delay: float = 5.0
var _time_since_last_hit: float = 0.0
var _shield_regen_ready: bool = false

# 护盾视觉
var _shield_visual: ColorRect

# 精英光环视觉
var _glow_visual: ColorRect

signal shield_changed(new_shield: int)
signal shield_broken()
signal shield_restored()

func _ready() -> void:
	super._ready()
	
	shield_current = shield_max
	_setup_visual()
	_setup_shield_visual()

func _setup_visual() -> void:
	if sprite and sprite.texture == null:
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(40, 40)
		color_rect.position = -color_rect.size / 2
		match enemy_name:
			"竹妖精英":
				color_rect.color = Color(0.1, 0.4, 0.1)
			"火焰巨人":
				color_rect.color = Color(0.7, 0.1, 0.05)
				color_rect.size = Vector2(50, 50)
				color_rect.position = -color_rect.size / 2
			"天机将军":
				color_rect.color = Color(0.4, 0.4, 0.5)
				color_rect.size = Vector2(50, 50)
				color_rect.position = -color_rect.size / 2
			_:
				color_rect.color = Color(0.3, 0.3, 0.3)
		sprite.add_child(color_rect)
		sprite.region_enabled = false
	
	# 精英发光效果
	_glow_visual = ColorRect.new()
	_glow_visual.size = Vector2(56, 56)
	_glow_visual.position = -_glow_visual.size / 2
	_glow_visual.color = Color(1, 0.8, 0.2, 0.15)
	_glow_visual.z_index = -1
	add_child(_glow_visual)

func _setup_shield_visual() -> void:
	_shield_visual = ColorRect.new()
	_shield_visual.size = Vector2(48, 48)
	_shield_visual.position = -_shield_visual.size / 2
	_shield_visual.color = Color(0.3, 0.6, 1.0, 0.3)
	_shield_visual.z_index = 1
	_shield_visual.visible = shield_current > 0
	add_child(_shield_visual)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# 更新护盾恢复计时
	if shield_current < shield_max:
		_time_since_last_hit += delta
		if _time_since_last_hit >= shield_regen_delay and not _shield_regen_ready:
			_shield_regen_ready = true
			_regen_shield()
	
	# 标准AI
	super._physics_process(delta)

## 护盾恢复
func _regen_shield() -> void:
	shield_current = shield_max
	_shield_visual.visible = true
	shield_restored.emit()
	print("%s 护盾已恢复" % enemy_name)

## 受伤（覆盖基类，加入护盾逻辑）
func take_damage(damage: int, is_crit: bool = false) -> void:
	if is_dead:
		return
	
	# 护盾吸收
	var remaining_damage = damage
	if shield_current > 0:
		if remaining_damage <= shield_current:
			shield_current -= remaining_damage
			remaining_damage = 0
			show_damage_number(damage, is_crit, true)
		else:
			remaining_damage -= shield_current
			shield_current = 0
			_shield_visual.visible = false
			shield_broken.emit()
			print("%s 护盾被击破！" % enemy_name)
	
	shield_changed.emit(shield_current)
	
	# 重置护盾恢复计时
	_time_since_last_hit = 0.0
	_shield_regen_ready = false
	
	# 如果还有剩余伤害，交给基类处理
	if remaining_damage > 0:
		super.take_damage(remaining_damage, is_crit)
	else:
		# 即使没穿透护盾也要设置目标
		if target == null:
			target = get_tree().get_first_node_in_group("player")

## 显示伤害数字（带护盾标识）
func show_damage_number(damage: int, is_crit: bool = false, absorbed_by_shield: bool = false) -> void:
	if absorbed_by_shield:
		print("%s 护盾吸收: %d" % [enemy_name, damage])
	elif is_crit:
		print("%s 受到暴击: %d" % [enemy_name, damage])
	else:
		print("%s 受到伤害: %d" % [enemy_name, damage])
