## 开放世界地图系统
## 单一大地图，分散敌人、资源点、NPC
## 参考三角洲行动的地图设计风格
class_name OpenWorldMap
extends Node2D

# ============================================================
# 地图配置
# ============================================================

# 地图尺寸（像素）
const MAP_WIDTH: int = 3000
const MAP_HEIGHT: int = 3000

# 区域尺寸（用于划分不同功能区）
const ZONE_SIZE: int = 600

# 瓦片尺寸
const TILE_SIZE: int = 32

# ============================================================
# 区域类型
# ============================================================

enum ZoneType {
	SPAWN,          # 出生点（安全区）
	COMBAT,         # 战斗区
	RESOURCE,       # 资源区
	ELITE,          # 精英区
	BOSS,           # Boss区
	EXTRACT,        # 撤离点
	NPC,            # NPC区
	SAFE            # 安全区
}

# ============================================================
# 区域配置
# ============================================================

# 区域数据
var _zones: Array[Dictionary] = []

# 敌人生成点
var _enemy_spawns: Array[Vector2] = []

# 资源生成点
var _resource_spawns: Array[Vector2] = []

# NPC位置
var _npc_positions: Array[Vector2] = []

# 撤离点
var _extract_points: Array[Vector2] = []

# Boss位置
var _boss_position: Vector2 = Vector2.ZERO

# ============================================================
# 节点引用
# ============================================================

var terrain_layer: Node2D = null
var decoration_layer: Node2D = null
var entity_layer: Node2D = null
var minimap: Control = null

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	# 获取子节点引用
	terrain_layer = get_node_or_null("TerrainLayer")
	decoration_layer = get_node_or_null("DecorationLayer")
	entity_layer = get_node_or_null("EntityLayer")
	minimap = get_node_or_null("Minimap")
	
	print("[OpenWorldMap] 节点引用: terrain=%s, decoration=%s, entity=%s" % [
		str(terrain_layer), str(decoration_layer), str(entity_layer)
	])
	
	_generate_map()
	_spawn_entities()

## 生成地图
func _generate_map() -> void:
	print("[OpenWorldMap] 开始生成地图...")
	
	# 划分区域
	_divide_zones()
	
	# 生成地形
	_generate_terrain()
	
	# 生成装饰物
	_generate_decorations()
	
	print("[OpenWorldMap] 地图生成完成: %dx%d" % [MAP_WIDTH, MAP_HEIGHT])

## 划分区域
func _divide_zones() -> void:
	# 清空区域
	_zones.clear()
	
	# 计算区域数量
	var zones_x = MAP_WIDTH / ZONE_SIZE
	var zones_y = MAP_HEIGHT / ZONE_SIZE
	
	# 定义区域布局（参考三角洲地图风格）
	# 中心：Boss区
	# 四角：资源区
	# 边缘：精英区
	# 中间：战斗区
	# 入口：出生点+撤离点
	
	for y in range(zones_y):
		for x in range(zones_x):
			var zone_pos = Vector2(x * ZONE_SIZE, y * ZONE_SIZE)
			var zone_center = zone_pos + Vector2(ZONE_SIZE / 2, ZONE_SIZE / 2)
			
			var zone_type = _get_zone_type(x, y, zones_x, zones_y)
			
			_zones.append({
				"type": zone_type,
				"position": zone_pos,
				"center": zone_center,
				"grid_pos": Vector2i(x, y)
			})
			
			# 根据区域类型设置生成点
			match zone_type:
				ZoneType.SPAWN:
					# 出生点在左上角
					pass
				ZoneType.COMBAT:
					# 战斗区随机生成敌人
					for i in range(randi_range(3, 6)):
						_enemy_spawns.append(zone_center + Vector2(
							randf_range(-ZONE_SIZE * 0.4, ZONE_SIZE * 0.4),
							randf_range(-ZONE_SIZE * 0.4, ZONE_SIZE * 0.4)
						))
				ZoneType.RESOURCE:
					# 资源区生成资源点
					for i in range(randi_range(5, 10)):
						_resource_spawns.append(zone_center + Vector2(
							randf_range(-ZONE_SIZE * 0.4, ZONE_SIZE * 0.4),
							randf_range(-ZONE_SIZE * 0.4, ZONE_SIZE * 0.4)
						))
				ZoneType.ELITE:
					# 精英区生成精英敌人
					_enemy_spawns.append(zone_center)
					_resource_spawns.append(zone_center + Vector2(100, 0))
					_resource_spawns.append(zone_center + Vector2(-100, 0))
				ZoneType.BOSS:
					# Boss区
					_boss_position = zone_center
				ZoneType.EXTRACT:
					# 撤离点
					_extract_points.append(zone_center)
				ZoneType.NPC:
					# NPC区
					_npc_positions.append(zone_center)

## 获取区域类型
func _get_zone_type(x: int, y: int, max_x: int, max_y: int) -> ZoneType:
	# 中心区域：Boss
	var center_x = max_x / 2
	var center_y = max_y / 2
	if abs(x - center_x) <= 1 and abs(y - center_y) <= 1:
		return ZoneType.BOSS
	
	# 四角：资源区
	if (x <= 1 or x >= max_x - 2) and (y <= 1 or y >= max_y - 2):
		return ZoneType.RESOURCE
	
	# 边缘中间：精英区
	if (x <= 1 or x >= max_x - 2) or (y <= 1 or y >= max_y - 2):
		if randf() < 0.5:
			return ZoneType.ELITE
		return ZoneType.RESOURCE
	
	# 入口区域：出生点
	if x == 0 and y == 0:
		return ZoneType.SPAWN
	
	# 撤离点：右下角区域
	if x >= max_x - 2 and y >= max_y - 2:
		return ZoneType.EXTRACT
	
	# NPC区域（随机）
	if randf() < 0.1:
		return ZoneType.NPC
	
	# 其他区域：战斗区
	return ZoneType.COMBAT

## 生成地形
func _generate_terrain() -> void:
	if not terrain_layer:
		print("[OpenWorldMap] TerrainLayer 不存在，跳过地形生成")
		return
	
	# 使用简单的颜色块表示不同区域
	for zone in _zones:
		var zone_type = zone.type
		var pos = zone.position
		
		# 根据区域类型选择颜色
		var color: Color
		match zone_type:
			ZoneType.SPAWN:
				color = Color(0.2, 0.6, 0.2)  # 绿色（安全）
			ZoneType.COMBAT:
				color = Color(0.3, 0.3, 0.2)  # 暗黄色（战斗）
			ZoneType.RESOURCE:
				color = Color(0.2, 0.4, 0.3)  # 深绿色（资源）
			ZoneType.ELITE:
				color = Color(0.5, 0.2, 0.2)  # 暗红色（精英）
			ZoneType.BOSS:
				color = Color(0.6, 0.1, 0.1)  # 红色（Boss）
			ZoneType.EXTRACT:
				color = Color(0.2, 0.5, 0.6)  # 蓝色（撤离）
			ZoneType.NPC:
				color = Color(0.4, 0.3, 0.5)  # 紫色（NPC）
			_:
				color = Color(0.25, 0.25, 0.2)  # 默认
		
		# 创建区域色块
		var zone_rect = ColorRect.new()
		zone_rect.color = color
		zone_rect.position = pos
		zone_rect.size = Vector2(ZONE_SIZE, ZONE_SIZE)
		terrain_layer.add_child(zone_rect)
		
		# 添加网格线
		_draw_grid_lines(pos, ZONE_SIZE)

## 绘制网格线
func _draw_grid_lines(pos: Vector2, size: int) -> void:
	var grid_color = Color(0.15, 0.15, 0.15, 0.3)
	var grid_step = 60
	
	# 水平线
	for y in range(0, size, grid_step):
		var line = Line2D.new()
		line.add_point(Vector2(pos.x, pos.y + y))
		line.add_point(Vector2(pos.x + size, pos.y + y))
		line.default_color = grid_color
		line.width = 1.0
		terrain_layer.add_child(line)
	
	# 垂直线
	for x in range(0, size, grid_step):
		var line = Line2D.new()
		line.add_point(Vector2(pos.x + x, pos.y))
		line.add_point(Vector2(pos.x + x, pos.y + size))
		line.default_color = grid_color
		line.width = 1.0
		terrain_layer.add_child(line)

## 生成装饰物
func _generate_decorations() -> void:
	if not decoration_layer:
		print("[OpenWorldMap] DecorationLayer 不存在，跳过装饰生成")
		return
	
	# 在地图上随机生成装饰物（树木、岩石等）
	var decoration_count = 200
	
	for i in range(decoration_count):
		var pos = Vector2(
			randf_range(0, MAP_WIDTH),
			randf_range(0, MAP_HEIGHT)
		)
		
		# 创建装饰物（简单的形状）
		var decoration = _create_random_decoration()
		decoration.position = pos
		decoration_layer.add_child(decoration)

## 创建随机装饰物
func _create_random_decoration() -> Node2D:
	var decoration = Node2D.new()
	
	# 随机选择装饰类型
	var type = randi() % 3
	
	match type:
		0:  # 树木
			var trunk = ColorRect.new()
			trunk.color = Color(0.4, 0.3, 0.2)
			trunk.size = Vector2(8, 20)
			trunk.position = Vector2(-4, -20)
			decoration.add_child(trunk)
			
			var crown = ColorRect.new()
			crown.color = Color(0.2, 0.5, 0.2)
			crown.size = Vector2(24, 24)
			crown.position = Vector2(-12, -44)
			decoration.add_child(crown)
		
		1:  # 岩石
			var rock = ColorRect.new()
			rock.color = Color(0.4, 0.4, 0.4)
			rock.size = Vector2(16, 12)
			rock.position = Vector2(-8, -12)
			decoration.add_child(rock)
		
		2:  # 灌木
			var bush = ColorRect.new()
			bush.color = Color(0.3, 0.45, 0.25)
			bush.size = Vector2(20, 14)
			bush.position = Vector2(-10, -14)
			decoration.add_child(bush)
	
	return decoration

# ============================================================
# 实体生成
# ============================================================

## 生成实体
func _spawn_entities() -> void:
	print("[OpenWorldMap] 开始生成实体...")
	print("[OpenWorldMap] 敌人生成点: %d" % _enemy_spawns.size())
	print("[OpenWorldMap] 资源生成点: %d" % _resource_spawns.size())
	print("[OpenWorldMap] NPC位置: %d" % _npc_positions.size())
	print("[OpenWorldMap] 撤离点: %d" % _extract_points.size())
	print("[OpenWorldMap] Boss位置: %s" % str(_boss_position))
	
	# 生成敌人
	_spawn_enemies()
	
	# 生成资源
	_spawn_resources()
	
	# 生成NPC
	_spawn_npcs()
	
	# 生成撤离点
	_spawn_extract_points()
	
	# 生成Boss
	_spawn_boss()
	
	print("[OpenWorldMap] 实体生成完成")

## 生成敌人
func _spawn_enemies() -> void:
	var enemy_spawner = get_node_or_null("/root/EnemySpawner")
	if not enemy_spawner:
		print("[OpenWorldMap] EnemySpawner 不存在")
		return
	
	for spawn_pos in _enemy_spawns:
		# 随机选择敌人类型
		var enemy_types = ["bamboo_spirit", "bamboo_archer"]
		var enemy_id = enemy_types[randi() % enemy_types.size()]
		
		var enemy = enemy_spawner.spawn_enemy(enemy_id, spawn_pos, entity_layer)
		if enemy:
			print("[OpenWorldMap] 生成敌人: %s at %s" % [enemy_id, str(spawn_pos)])

## 生成资源
func _spawn_resources() -> void:
	for spawn_pos in _resource_spawns:
		# 随机选择资源类型
		var resource_types = ["spirit_stone", "herb", "ore"]
		var resource_id = resource_types[randi() % resource_types.size()]
		
		var resource = _create_resource_node(resource_id, spawn_pos)
		entity_layer.add_child(resource)

## 创建资源节点
func _create_resource_node(resource_id: String, pos: Vector2) -> Node2D:
	var resource = Area2D.new()
	resource.position = pos
	resource.collision_layer = 4  # 第3层（资源）
	resource.collision_mask = 1   # 检测第1层（玩家）
	
	# 视觉
	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	
	match resource_id:
		"spirit_stone":
			sprite.color = Color(0.3, 0.6, 1.0)  # 蓝色
		"herb":
			sprite.color = Color(0.2, 0.8, 0.2)  # 绿色
		"ore":
			sprite.color = Color(0.6, 0.4, 0.2)  # 棕色
		_:
			sprite.color = Color(0.5, 0.5, 0.5)  # 灰色
	
	resource.add_child(sprite)
	
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	resource.add_child(collision)
	
	# 设置元数据
	resource.set_meta("resource_id", resource_id)
	resource.set_meta("resource_name", _get_resource_name(resource_id))
	
	# 连接信号
	resource.body_entered.connect(_on_resource_body_entered.bind(resource))
	
	return resource

## 获取资源名称
func _get_resource_name(resource_id: String) -> String:
	match resource_id:
		"spirit_stone":
			return "灵石"
		"herb":
			return "灵草"
		"ore":
			return "矿石"
		_:
			return "未知"

## 资源被收集
func _on_resource_body_entered(body: Node2D, resource: Node2D) -> void:
	if body is Player:
		var resource_id = resource.get_meta("resource_id", "")
		var resource_name = resource.get_meta("resource_name", "")
		var amount = randi_range(1, 5)
		
		# 添加到背包
		var item_data = {
			"id": resource_id,
			"name": resource_name,
			"amount": amount
		}
		
		if GameManager.add_to_inventory(item_data):
			print("[OpenWorldMap] 收集资源: %s x%d" % [resource_name, amount])
			# 移除资源节点
			_resource_spawns.erase(resource.position)
			resource.queue_free()

## 生成NPC
func _spawn_npcs() -> void:
	for npc_pos in _npc_positions:
		var npc = _create_npc_node("merchant", npc_pos)
		entity_layer.add_child(npc)

## 创建NPC节点
func _create_npc_node(npc_type: String, pos: Vector2) -> Node2D:
	var npc = Area2D.new()
	npc.position = pos
	npc.collision_layer = 2  # 第2层（NPC）
	npc.collision_mask = 1   # 检测第1层（玩家）
	
	# 视觉
	var sprite = ColorRect.new()
	sprite.size = Vector2(20, 30)
	sprite.position = Vector2(-10, -30)
	sprite.color = Color(0.8, 0.6, 0.2)  # 金色（NPC）
	npc.add_child(sprite)
	
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 30)
	collision.shape = shape
	npc.add_child(collision)
	
	# 名称标签
	var label = Label.new()
	label.text = "商人"
	label.position = Vector2(-15, -50)
	label.add_theme_font_size_override("font_size", 12)
	npc.add_child(label)
	
	# 设置元数据
	npc.set_meta("npc_type", npc_type)
	
	# 连接信号
	npc.body_entered.connect(_on_npc_body_entered.bind(npc))
	
	return npc

## NPC交互
func _on_npc_body_entered(body: Node2D, npc: Node2D) -> void:
	if body is Player:
		var npc_type = npc.get_meta("npc_type", "")
		print("[OpenWorldMap] 与NPC交互: %s" % npc_type)
		# 这里可以触发NPC对话或商店界面

## 生成撤离点
func _spawn_extract_points() -> void:
	for extract_pos in _extract_points:
		var extract = _create_extract_node(extract_pos)
		entity_layer.add_child(extract)

## 创建撤离点节点
func _create_extract_node(pos: Vector2) -> Node2D:
	var extract = Area2D.new()
	extract.position = pos
	extract.collision_layer = 8  # 第4层（撤离点）
	extract.collision_mask = 1   # 检测第1层（玩家）
	
	# 视觉
	var sprite = ColorRect.new()
	sprite.size = Vector2(40, 40)
	sprite.position = Vector2(-20, -40)
	sprite.color = Color(0.2, 0.8, 0.8)  # 青色（撤离点）
	extract.add_child(sprite)
	
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	collision.shape = shape
	extract.add_child(collision)
	
	# 名称标签
	var label = Label.new()
	label.text = "撤离点"
	label.position = Vector2(-20, -60)
	label.add_theme_font_size_override("font_size", 14)
	extract.add_child(label)
	
	# 连接信号
	extract.body_entered.connect(_on_extract_body_entered.bind(extract))
	
	return extract

## 撤离点交互
func _on_extract_body_entered(body: Node2D, _extract: Node2D) -> void:
	if body is Player:
		print("[OpenWorldMap] 到达撤离点，准备撤离")
		# 这里触发撤离逻辑
		GameManager.victory()

## 生成Boss
func _spawn_boss() -> void:
	if _boss_position == Vector2.ZERO:
		return
	
	var enemy_spawner = get_node_or_null("/root/EnemySpawner")
	if not enemy_spawner:
		return
	
	var boss = enemy_spawner.spawn_boss("bamboo_king", _boss_position)
	if boss:
		# 将Boss移动到entity_layer
		if boss.get_parent():
			boss.get_parent().remove_child(boss)
		entity_layer.add_child(boss)
		print("[OpenWorldMap] 生成Boss: 竹妖王 at %s" % str(_boss_position))

# ============================================================
# 查询接口
# ============================================================

## 获取地图尺寸
func get_map_size() -> Vector2:
	return Vector2(MAP_WIDTH, MAP_HEIGHT)

## 获取所有敌人生成点
func get_enemy_spawns() -> Array[Vector2]:
	return _enemy_spawns

## 获取所有资源生成点
func get_resource_spawns() -> Array[Vector2]:
	return _resource_spawns

## 获取所有NPC位置
func get_npc_positions() -> Array[Vector2]:
	return _npc_positions

## 获取所有撤离点
func get_extract_points() -> Array[Vector2]:
	return _extract_points

## 获取Boss位置
func get_boss_position() -> Vector2:
	return _boss_position

## 获取区域信息
func get_zone_at_position(world_pos: Vector2) -> Dictionary:
	for zone in _zones:
		var zone_rect = Rect2(zone.position, Vector2(ZONE_SIZE, ZONE_SIZE))
		if zone_rect.has_point(world_pos):
			return zone
	return {}

## 获取区域类型名称
func get_zone_type_name(zone_type: ZoneType) -> String:
	match zone_type:
		ZoneType.SPAWN:
			return "出生点"
		ZoneType.COMBAT:
			return "战斗区"
		ZoneType.RESOURCE:
			return "资源区"
		ZoneType.ELITE:
			return "精英区"
		ZoneType.BOSS:
			return "Boss区"
		ZoneType.EXTRACT:
			return "撤离点"
		ZoneType.NPC:
			return "NPC区"
		ZoneType.SAFE:
			return "安全区"
		_:
			return "未知"
