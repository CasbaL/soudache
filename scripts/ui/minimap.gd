## 小地图
## 显示房间布局、玩家位置、敌人位置
extends Control

# 配置
@export var map_size: Vector2 = Vector2(150, 150)
@export var world_size: Vector2 = Vector2(720, 1280)  # 世界大小

# 绘制颜色
const BG_COLOR = Color(0.1, 0.1, 0.1, 0.8)
const WALL_COLOR = Color(0.5, 0.45, 0.4)
const PLAYER_COLOR = Color(0.2, 0.8, 1.0)  # 青色
const ENEMY_COLOR = Color(1.0, 0.3, 0.3)   # 红色
const RESOURCE_COLOR = Color(0.3, 1.0, 0.3) # 绿色

# 缩放比例
var _scale: Vector2

func _ready() -> void:
	custom_minimum_size = map_size
	size = map_size
	_scale = map_size / world_size

func _draw() -> void:
	# 背景
	draw_rect(Rect2(Vector2.ZERO, map_size), BG_COLOR)
	
	# 边框
	draw_rect(Rect2(Vector2.ZERO, map_size), WALL_COLOR, false, 2.0)
	
	# 绘制房间区域（中央石板地）
	var room_rect = Rect2(
		Vector2(60, 150) * _scale,
		Vector2(600, 900) * _scale
	)
	draw_rect(room_rect, WALL_COLOR, false, 1.0)
	
	# 绘制敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var pos = enemy.global_position * _scale
			draw_circle(pos, 3.0, ENEMY_COLOR)
	
	# 绘制资源（绿色小点）
	for node in get_tree().get_nodes_in_group("resources"):
		if is_instance_valid(node):
			var pos = node.global_position * _scale
			draw_circle(pos, 2.0, RESOURCE_COLOR)
	
	# 绘制玩家（最后绘制，确保在最上层）
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var pos = player.global_position * _scale
		draw_circle(pos, 5.0, PLAYER_COLOR)
		draw_arc(pos, 7.0, 0, TAU, 16, Color.WHITE, 1.0)

func _process(_delta: float) -> void:
	# 每帧重绘（追踪玩家和敌人位置）
	queue_redraw()
