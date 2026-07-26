## 子弹对象池
## 复用子弹实例，减少GC压力
class_name BulletPool
extends Node

# 配置
@export var pool_size: int = 50
var bullet_script: Script = preload("res://scripts/systems/bullet.gd")

# 池
var _available: Array = []
var _active: Array = []
var _scene_root: Node = null

func _ready() -> void:
	# 预创建子弹
	for i in pool_size:
		var bullet = _create_bullet()
		bullet.visible = false
		bullet.set_physics_process(false)
		_available.append(bullet)

func _process(_delta: float) -> void:
	# 清理已失效的活跃子弹
	var i = _active.size() - 1
	while i >= 0:
		if not is_instance_valid(_active[i]):
			_active.remove_at(i)
		i -= 1

## 创建子弹实例
func _create_bullet():
	var bullet = CharacterBody2D.new()
	bullet.set_script(bullet_script)
	bullet.recycle_callback = return_bullet
	add_child(bullet)
	return bullet

## 获取子弹
func get_bullet():
	var bullet
	
	if _available.size() > 0:
		bullet = _available.pop_back()
	else:
		# 池耗尽，创建新实例
		bullet = _create_bullet()
	
	# 重置状态
	bullet.visible = true
	bullet.set_physics_process(true)
	if "_hit" in bullet:
		bullet._hit = false
	if "_time_alive" in bullet:
		bullet._time_alive = 0.0
	if "_pierce_hit" in bullet:
		bullet._pierce_hit = 0
	bullet.position = Vector2.ZERO
	if "direction" in bullet:
		bullet.direction = Vector2.RIGHT
	if "speed" in bullet:
		bullet.speed = 200.0
	if "damage" in bullet:
		bullet.damage = 50
	if "color" in bullet:
		bullet.color = Color(1.0, 0.3, 0.2)
	if "lifetime" in bullet:
		bullet.lifetime = 5.0
	if "radius" in bullet:
		bullet.radius = 6.0
	bullet.rotation = 0.0
	bullet.modulate = Color.WHITE
	bullet.queue_redraw()
	
	_active.append(bullet)
	return bullet

## 回收子弹
func return_bullet(bullet) -> void:
	if not is_instance_valid(bullet):
		return
	
	bullet.visible = false
	bullet.set_physics_process(false)
	
	var idx = _active.find(bullet)
	if idx >= 0:
		_active.remove_at(idx)
	
	_available.append(bullet)

## 回收所有活跃子弹
func return_all() -> void:
	for bullet in _active:
		if is_instance_valid(bullet):
			bullet.visible = false
			bullet.set_physics_process(false)
			_available.append(bullet)
	_active.clear()

## 获取活跃子弹数量
func get_active_count() -> int:
	return _active.size()

## 获取可用子弹数量
func get_available_count() -> int:
	return _available.size()

## 创建子弹并配置
func spawn_bullet(pos: Vector2, dir: Vector2, cfg: Dictionary = {}):
	var bullet = get_bullet()
	
	bullet.position = pos
	if "direction" in bullet:
		bullet.direction = dir.normalized()
	if "speed" in bullet:
		bullet.speed = cfg.get("speed", 200.0)
	if "damage" in bullet:
		bullet.damage = cfg.get("damage", 50)
	if "color" in bullet:
		bullet.color = cfg.get("color", Color(1.0, 0.3, 0.2))
	if "lifetime" in bullet:
		bullet.lifetime = cfg.get("lifetime", 5.0)
	if "radius" in bullet:
		bullet.radius = cfg.get("radius", 6.0)
	if "homing_strength" in bullet:
		bullet.homing_strength = cfg.get("homing_strength", 2.0)
	if "acceleration" in bullet:
		bullet.acceleration = cfg.get("acceleration", 100.0)
	if "max_speed" in bullet:
		bullet.max_speed = cfg.get("max_speed", 500.0)
	if "explosion_radius" in bullet:
		bullet.explosion_radius = cfg.get("explosion_radius", 60.0)
	if "pierce_count" in bullet:
		bullet.pierce_count = cfg.get("pierce_count", 3)
	
	# 连接生命周期结束信号
	if not bullet.tree_exiting.is_connected(_on_bullet_exiting):
		bullet.tree_exiting.connect(_on_bullet_exiting.bind(bullet))
	
	return bullet

func _on_bullet_exiting(bullet) -> void:
	# 如果子弹被queue_free，从活跃列表移除
	var idx = _active.find(bullet)
	if idx >= 0:
		_active.remove_at(idx)
