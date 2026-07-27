## 环境危害系统
## 管理房间内的环境危害元素（熔岩、陷阱、机关等）
class_name HazardSystem
extends Node2D

# 危害类型
enum HazardType {
	SPIKE_TRAP,     # 竹刺陷阱
	LAVA,           # 熔岩地面
	FIRE_WALL,      # 火焰墙
	ERUPTION,       # 火山喷发
	ARROW_TRAP,     # 机关箭
	GEAR_TRAP,      # 齿轮陷阱
	RUNE_TRAP,      # 符文陷阱（定身）
	MOVING_WALL,    # 移动墙壁
}

# 危害配置
const HAZARD_CONFIGS: Dictionary = {
	HazardType.SPIKE_TRAP: {
		"damage": 50,
		"interval": 2.0,
		"color": Color(0.6, 0.3, 0.1, 0.6),
		"size": Vector2(40, 40),
		"effect": "damage",
	},
	HazardType.LAVA: {
		"damage": 30,
		"interval": 1.0,
		"color": Color(0.9, 0.2, 0.0, 0.4),
		"size": Vector2(80, 80),
		"effect": "damage",
	},
	HazardType.FIRE_WALL: {
		"damage": 40,
		"interval": 0.5,
		"color": Color(1.0, 0.4, 0.0, 0.5),
		"size": Vector2(20, 100),
		"effect": "damage",
	},
	HazardType.ERUPTION: {
		"damage": 60,
		"interval": 3.0,
		"color": Color(1.0, 0.3, 0.0, 0.7),
		"size": Vector2(60, 60),
		"effect": "damage",
	},
	HazardType.ARROW_TRAP: {
		"damage": 40,
		"interval": 2.0,
		"color": Color(0.5, 0.5, 0.5, 0.6),
		"size": Vector2(30, 30),
		"effect": "damage",
	},
	HazardType.GEAR_TRAP: {
		"damage": 50,
		"interval": 1.5,
		"color": Color(0.4, 0.4, 0.5, 0.6),
		"size": Vector2(50, 50),
		"effect": "damage",
	},
	HazardType.RUNE_TRAP: {
		"damage": 30,
		"interval": 3.0,
		"color": Color(0.5, 0.3, 0.8, 0.5),
		"size": Vector2(50, 50),
		"effect": "stun",
		"stun_duration": 2.0,
	},
	HazardType.MOVING_WALL: {
		"damage": 35,
		"interval": 1.0,
		"color": Color(0.3, 0.3, 0.4, 0.7),
		"size": Vector2(40, 80),
		"effect": "damage",
	},
}

# 活跃的危害区域
var _hazards: Array[Dictionary] = []

## 在指定位置创建危害
func create_hazard(type: HazardType, pos: Vector2) -> Area2D:
	var config = HAZARD_CONFIGS.get(type, {})
	if config.is_empty():
		return null

	var hazard = Area2D.new()
	hazard.position = pos
	hazard.collision_layer = 0
	hazard.collision_mask = 1  # 检测玩家

	# 视觉
	var visual = ColorRect.new()
	visual.size = config.get("size", Vector2(40, 40))
	visual.position = -visual.size / 2
	visual.color = config.get("color", Color(1, 0, 0, 0.5))
	hazard.add_child(visual)

	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = config.get("size", Vector2(40, 40))
	collision.shape = shape
	hazard.add_child(collision)

	# 设置元数据
	hazard.set_meta("hazard_type", type)
	hazard.set_meta("damage", config.get("damage", 0))
	hazard.set_meta("interval", config.get("interval", 1.0))
	hazard.set_meta("effect", config.get("effect", "damage"))
	hazard.set_meta("stun_duration", config.get("stun_duration", 0.0))
	hazard.set_meta("last_hit_time", 0.0)

	# 连接信号
	hazard.body_entered.connect(_on_body_entered.bind(hazard))
	hazard.body_exited.connect(_on_body_exited.bind(hazard))

	add_child(hazard)
	_hazards.append({"node": hazard, "players_inside": []})

	return hazard

## 批量创建危害
func create_hazards(type: HazardType, positions: Array) -> void:
	for pos in positions:
		create_hazard(type, pos)

## 玩家进入危害区域
func _on_body_entered(body: Node2D, hazard: Area2D) -> void:
	if body is Player:
		for h in _hazards:
			if h.node == hazard:
				if body not in h.players_inside:
					h.players_inside.append(body)
				break

## 玩家离开危害区域
func _on_body_exited(body: Node2D, hazard: Area2D) -> void:
	if body is Player:
		for h in _hazards:
			if h.node == hazard:
				h.players_inside.erase(body)
				break

func _process(delta: float) -> void:
	var now = Time.get_unix_time_from_system()

	for h in _hazards:
		if not is_instance_valid(h.node):
			continue
		var hazard = h.node
		var interval = hazard.get_meta("interval", 1.0)
		var last_hit = hazard.get_meta("last_hit_time", 0.0)

		if now - last_hit < interval:
			continue

		for player in h.players_inside:
			if not is_instance_valid(player):
				continue
			var damage = hazard.get_meta("damage", 0)
			var effect = hazard.get_meta("effect", "damage")

			if effect == "stun":
				var stun_dur = hazard.get_meta("stun_duration", 2.0)
				player.apply_stun(stun_dur)
				player.take_damage(damage)
			else:
				player.take_damage(damage)

			hazard.set_meta("last_hit_time", now)

## 清除所有危害
func clear_all() -> void:
	for h in _hazards:
		if is_instance_valid(h.node):
			h.node.queue_free()
	_hazards.clear()
