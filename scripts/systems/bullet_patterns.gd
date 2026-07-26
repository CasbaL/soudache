## 弹幕模式生成器
## 提供Boss和敌人常用的弹幕模式
class_name BulletPatterns
extends Node

# 引用子弹池
var bullet_pool = null

# 子弹脚本引用
var _bullet_script = preload("res://scripts/systems/bullet.gd")
var _pool_script = preload("res://scripts/systems/bullet_pool.gd")

# 默认子弹配置
var default_bullet_config: Dictionary = {
	"speed": 200.0,
	"damage": 50,
	"color": Color(1.0, 0.3, 0.2),
	"lifetime": 5.0,
	"radius": 8.0,
}

func _ready() -> void:
	# 创建子弹池
	bullet_pool = _pool_script.new()
	add_child(bullet_pool)

## 扇形弹幕
func fan_shot(origin: Vector2, target: Vector2, count: int = 5, spread_angle: float = 60.0, cfg: Dictionary = {}) -> Array:
	var merged_cfg = default_bullet_config.duplicate()
	merged_cfg.merge(cfg)
	
	var base_dir = (target - origin).normalized()
	var base_angle = base_dir.angle()
	var half_spread = deg_to_rad(spread_angle / 2.0)
	var bullets: Array = []
	
	for i in count:
		var angle_offset = 0.0
		if count > 1:
			angle_offset = -half_spread + (spread_angle / (count - 1)) * i
		
		var dir = Vector2.from_angle(base_angle + angle_offset)
		var bullet = bullet_pool.spawn_bullet(origin, dir, merged_cfg)
		bullets.append(bullet)
	
	return bullets

## 连射弹幕
func burst_shot(origin: Vector2, target: Vector2, count: int = 3, interval: float = 0.15, cfg: Dictionary = {}) -> Array:
	var merged_cfg = default_bullet_config.duplicate()
	merged_cfg.merge(cfg)
	
	var dir = (target - origin).normalized()
	var bullets: Array = []
	
	for i in count:
		var delay = interval * i
		var timer = get_tree().create_timer(delay)
		timer.timeout.connect(func():
			var bullet = bullet_pool.spawn_bullet(origin, dir, merged_cfg)
			bullets.append(bullet)
		)
	
	return bullets

## 瞄准弹幕
func aimed_shot(origin: Vector2, target: Node2D, cfg: Dictionary = {}):
	var merged_cfg = default_bullet_config.duplicate()
	merged_cfg.merge(cfg)
	
	var dir = (target.global_position - origin).normalized()
	var bullet = bullet_pool.spawn_bullet(origin, dir, merged_cfg)
	
	return bullet

## 圆形弹幕
func ring(origin: Vector2, count: int = 12, cfg: Dictionary = {}) -> Array:
	var merged_cfg = default_bullet_config.duplicate()
	merged_cfg.merge(cfg)
	
	var bullets: Array = []
	var angle_step = TAU / count
	
	for i in count:
		var angle = angle_step * i
		var dir = Vector2.from_angle(angle)
		var bullet = bullet_pool.spawn_bullet(origin, dir, merged_cfg)
		bullets.append(bullet)
	
	return bullets

## 随机散射
func random_scatter(origin: Vector2, count: int = 8, spread: float = 360.0, cfg: Dictionary = {}) -> Array:
	var merged_cfg = default_bullet_config.duplicate()
	merged_cfg.merge(cfg)
	
	var bullets: Array = []
	var half_spread = deg_to_rad(spread / 2.0)
	
	for i in count:
		var angle = randf_range(-half_spread, half_spread)
		var dir = Vector2.from_angle(angle)
		var speed_var = merged_cfg["speed"] * randf_range(0.8, 1.2)
		var bullet_cfg = merged_cfg.duplicate()
		bullet_cfg["speed"] = speed_var
		var bullet = bullet_pool.spawn_bullet(origin, dir, bullet_cfg)
		bullets.append(bullet)
	
	return bullets

## 回收所有子弹
func clear_all_bullets() -> void:
	if bullet_pool:
		bullet_pool.return_all()

## 获取当前活跃子弹数
func get_active_bullet_count() -> int:
	if bullet_pool:
		return bullet_pool.get_active_count()
	return 0
