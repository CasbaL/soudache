## 大地图生成器
## 在连续大地图上生成区域、兴趣点、敌人和资源配置
class_name MapGenerator
extends RefCounted

# 预加载脚本
var _MapZoneScript = load("res://scripts/systems/map_zone.gd")

# ============================================================
# 层配置
# ============================================================

# 地图尺寸（像素）
const LAYER_MAP_SIZES: Dictionary = {
	1: Vector2i(3000, 3000),
	2: Vector2i(4000, 4000),
	3: Vector2i(5000, 5000),
}

# 区域配置
const ZONE_RADIUS_MIN: float = 200.0
const ZONE_RADIUS_MAX: float = 400.0
const ZONE_SPACING: float = 500.0  # 区域之间最小间距

# 每层区域数量
const LAYER_ZONE_COUNTS: Dictionary = {
	1: {"combat": 8, "resource": 4, "elite": 2, "npc": 2, "hazard": 2},
	2: {"combat": 12, "resource": 5, "elite": 3, "npc": 2, "hazard": 3},
	3: {"combat": 15, "resource": 6, "elite": 4, "npc": 3, "hazard": 4},
}

# ============================================================
# 生成状态
# ============================================================

var _zones: Dictionary = {}  # { id }
var _zone_counter: int = 0
var _layer: int = 1
var _map_size: Vector2i = Vector2i.ZERO
var _spawn_position: Vector2 = Vector2.ZERO
var _boss_position: Vector2 = Vector2.ZERO
var _extract_positions: Array[Vector2] = []

# ============================================================
# 公共接口
# ============================================================

## 生成指定层的大地图
func generate_layer(layer_num: int) -> Dictionary:
	_layer = layer_num
	_zones.clear()
	_zone_counter = 0
	_map_size = LAYER_MAP_SIZES.get(layer_num, Vector2i(3000, 3000))
	_spawn_position = Vector2.ZERO
	_boss_position = Vector2.ZERO
	_extract_positions.clear()

	# 步骤1：设置出生点和Boss位置
	_setup_key_positions()

	# 步骤2：生成战斗区域
	_generate_zones()

	# 步骤3：验证可达性
	_verify_zone_spacing()

	print("[MapGenerator] 大地图生成完成: %dx%d, %d 个区域" % [_map_size.x, _map_size.y, _zones.size()])

	return {
		"zones": _zones.duplicate(),
		"map_size": _map_size,
		"spawn_position": _spawn_position,
		"boss_position": _boss_position,
		"extract_positions": _extract_positions.duplicate(),
		"layer": _layer,
	}

# ============================================================
# 步骤1：设置关键位置
# ============================================================

func _setup_key_positions() -> void:
	# 出生点：左上角区域
	_spawn_position = Vector2(_map_size.x * 0.1, _map_size.y * 0.1)

	# Boss位置：地图中心
	_boss_position = Vector2(_map_size.x * 0.5, _map_size.y * 0.5)

	# 撤离点：分散在地图各处（2-3个）
	var extract_count = randi_range(2, 3)
	var extract_angles = []
	for i in range(extract_count):
		extract_angles.append(TAU * i / extract_count + randf_range(-0.3, 0.3))

	for angle in extract_angles:
		var dist = _map_size.x * randf_range(0.3, 0.45)
		var pos = _boss_position + Vector2(cos(angle), sin(angle)) * dist
		# 确保在地图范围内
		pos.x = clampf(pos.x, 200, _map_size.x - 200)
		pos.y = clampf(pos.y, 200, _map_size.y - 200)
		_extract_positions.append(pos)

# ============================================================
# 步骤2：生成区域
# ============================================================

func _generate_zones() -> void:
	var zone_counts = LAYER_ZONE_COUNTS.get(_layer, LAYER_ZONE_COUNTS[1])

	# 创建出生点区域
	var spawn_zone = _create_zone(_MapZoneScript.ZoneType.SPAWN, _spawn_position)
	spawn_zone.radius = 350.0
	spawn_zone.difficulty = 0
	spawn_zone.layer_theme = _get_layer_theme_name()

	# 创建Boss区域
	var boss_zone = _create_zone(_MapZoneScript.ZoneType.BOSS, _boss_position)
	boss_zone.radius = 400.0
	boss_zone.difficulty = 5
	boss_zone.layer_theme = _get_layer_theme_name()
	boss_zone.enemies = [{"enemy_id": _get_boss_id(), "count": 1}]

	# 创建撤离点区域
	for extract_pos in _extract_positions:
		var extract_zone = _create_zone(_MapZoneScript.ZoneType.EXTRACT, extract_pos)
		extract_zone.radius = 250.0
		extract_zone.has_extraction_point = true
		extract_zone.difficulty = 0

	# 生成战斗区域
	for i in range(zone_counts.get("combat", 8)):
		var pos = _find_random_zone_position()
		var zone = _create_zone(_MapZoneScript.ZoneType.COMBAT, pos)
		zone.difficulty = randi_range(1, 3)
		zone.layer_theme = _get_layer_theme_name()
		_assign_combat_enemies(zone)

	# 生成资源区域
	for i in range(zone_counts.get("resource", 4)):
		var pos = _find_random_zone_position()
		var zone = _create_zone(_MapZoneScript.ZoneType.RESOURCE, pos)
		zone.difficulty = 0
		zone.layer_theme = _get_layer_theme_name()
		_assign_resource_items(zone)

	# 生成精英区域
	for i in range(zone_counts.get("elite", 2)):
		var pos = _find_random_zone_position()
		var zone = _create_zone(_MapZoneScript.ZoneType.ELITE, pos)
		zone.difficulty = randi_range(3, 5)
		zone.layer_theme = _get_layer_theme_name()
		_assign_elite_enemies(zone)

	# 生成NPC区域
	for i in range(zone_counts.get("npc", 2)):
		var pos = _find_random_zone_position()
		var zone = _create_zone(_MapZoneScript.ZoneType.NPC, pos)
		zone.has_npc = true
		zone.difficulty = 0
		_assign_npc_data(zone)

	# 生成危险区域
	for i in range(zone_counts.get("hazard", 2)):
		var pos = _find_random_zone_position()
		var zone = _create_zone(_MapZoneScript.ZoneType.HAZARD, pos)
		zone.difficulty = randi_range(2, 4)
		zone.layer_theme = _get_layer_theme_name()

# ============================================================
# 区域生成辅助
# ============================================================

func _create_zone(type, center: Vector2) -> Variant:
	_zone_counter += 1
	var zone = _MapZoneScript.new("zone_%03d" % _zone_counter, type, center)
	_zones[zone.id] = zone
	return zone

func _find_random_zone_position() -> Vector2:
	var max_attempts = 50
	for _i in range(max_attempts):
		var pos = Vector2(
			randf_range(_map_size.x * 0.15, _map_size.x * 0.85),
			randf_range(_map_size.y * 0.15, _map_size.y * 0.85)
		)

		# 检查与现有区域的间距
		if _is_position_valid(pos):
			return pos

	# 如果找不到合适位置，使用随机位置
	return Vector2(
		randf_range(200, _map_size.x - 200),
		randf_range(200, _map_size.y - 200)
	)

func _is_position_valid(pos: Vector2) -> bool:
	# 不能太靠近出生点
	if pos.distance_to(_spawn_position) < ZONE_SPACING * 1.5:
		return false

	# 不能太靠近Boss
	if pos.distance_to(_boss_position) < ZONE_SPACING * 1.5:
		return false

	# 不能太靠近撤离点
	for extract_pos in _extract_positions:
		if pos.distance_to(extract_pos) < ZONE_SPACING:
			return false

	# 不能太靠近其他区域
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if pos.distance_to(zone.center) < ZONE_SPACING:
			return false

	return true

# ============================================================
# 步骤3：验证区域间距
# ============================================================

func _verify_zone_spacing() -> void:
	# 检查所有区域是否在地图范围内
	for zone_id in _zones:
		var zone = _zones[zone_id]
		zone.center.x = clampf(zone.center.x, zone.radius, _map_size.x - zone.radius)
		zone.center.y = clampf(zone.center.y, zone.radius, _map_size.y - zone.radius)

# ============================================================
# 敌人/资源分配
# ============================================================

func _assign_combat_enemies(zone) -> void:
	var layer_enemies = _get_layer_enemy_types()
	var count = randi_range(3, 6)
	var enemy_type = layer_enemies[randi() % layer_enemies.size()]
	zone.enemies = [{"enemy_id": enemy_type, "count": count}]

	# 偶尔添加第二种敌人
	if randf() < 0.3:
		var second_type = layer_enemies[randi() % layer_enemies.size()]
		if second_type != enemy_type:
			zone.enemies.append({"enemy_id": second_type, "count": randi_range(1, 3)})

func _assign_elite_enemies(zone) -> void:
	var layer_enemies = _get_layer_enemy_types()
	var elite_type = _get_layer_elite_type()

	# 精英 + 小怪
	zone.enemies = [
		{"enemy_id": elite_type, "count": randi_range(1, 2)},
		{"enemy_id": layer_enemies[0], "count": randi_range(3, 5)}
	]

func _assign_resource_items(zone) -> void:
	var resource_types = _get_layer_resource_types()
	var count = randi_range(3, 8)
	var res_type = resource_types[randi() % resource_types.size()]
	zone.resources = [{"resource_id": res_type, "name": _get_resource_name(res_type), "amount": count}]

func _assign_npc_data(zone) -> void:
	var npc_types = ["merchant", "mystic", "trapped_cultivator"]
	zone.npc_type = npc_types[randi() % npc_types.size()]
	match zone.npc_type:
		"merchant":
			zone.npc_dialogue = "道友，要买点什么？"
		"mystic":
			zone.npc_dialogue = "想试试运气吗？"
		"trapped_cultivator":
			zone.npc_dialogue = "道友救我！"

# ============================================================
# 层数据查询
# ============================================================

func _get_layer_theme_name() -> String:
	match _layer:
		1: return "幽竹林"
		2: return "火焰山"
		3: return "天机阁"
	return "未知"

func _get_boss_id() -> String:
	match _layer:
		1: return "bamboo_king"
		2: return "fire_demon"
		3: return "tianji_elder"
	return ""

func _get_layer_enemy_types() -> Array:
	match _layer:
		1: return ["bamboo_spirit", "bamboo_archer"]
		2: return ["fire_spirit", "fire_giant"]
		3: return ["mechanism_beast", "mechanism_general"]
	return ["bamboo_spirit"]

func _get_layer_elite_type() -> String:
	match _layer:
		1: return "bamboo_elite"
		2: return "fire_giant"
		3: return "mechanism_general"
	return "bamboo_elite"

func _get_layer_resource_types() -> Array:
	match _layer:
		1: return ["spirit_stone", "herb", "ore", "chest"]
		2: return ["spirit_stone", "fire_crystal", "ore", "chest"]
		3: return ["spirit_stone", "gear", "ore", "chest"]
	return ["spirit_stone"]

func _get_resource_name(resource_id: String) -> String:
	match resource_id:
		"spirit_stone": return "灵石"
		"herb": return "灵草"
		"ore": return "矿石"
		"chest": return "宝箱"
		"fire_crystal": return "火晶石"
		"gear": return "齿轮"
		"technique_fragment": return "功法残页"
		"equipment": return "装备"
	return "未知"

# ============================================================
# 公共查询
# ============================================================

func get_zones() -> Dictionary:
	return _zones

func get_spawn_position() -> Vector2:
	return _spawn_position

func get_boss_position() -> Vector2:
	return _boss_position

func get_extract_positions() -> Array[Vector2]:
	return _extract_positions

func get_map_size() -> Vector2i:
	return _map_size

func get_zone_at_position(world_pos: Vector2):
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if zone.contains_point(world_pos):
			return zone
	return null

func get_nearest_zone(pos: Vector2, type = null):
	var best_zone = null
	var best_dist = 999999.0

	for zone_id in _zones:
		var zone = _zones[zone_id]
		if type != null and zone.type != type:
			continue
		var dist = pos.distance_to(zone.center)
		if dist < best_dist:
			best_dist = dist
			best_zone = zone

	return best_zone
