## 区域数据类
## 大地图中的功能区域：战斗区、资源区、Boss区、撤离点等
class_name MapZone
extends RefCounted

# 区域类型枚举
enum ZoneType {
	SPAWN,      # 出生点（安全区）
	COMBAT,     # 战斗区
	RESOURCE,   # 资源区
	ELITE,      # 精英区
	BOSS,       # Boss区
	EXTRACT,    # 撤离点
	NPC,        # NPC区
	HAZARD      # 危险区（环境危害）
}

# 基础属性
var id: String = ""
var type: ZoneType = ZoneType.COMBAT
var center: Vector2 = Vector2.ZERO     # 世界坐标中心
var radius: float = 300.0              # 区域半径（像素）
var grid_pos: Vector2i = Vector2i.ZERO # 网格位置（用于区域划分）

# 难度等级（1-5）
var difficulty: int = 1

# 层主题
var layer_theme: String = ""

# 敌人配置：Array of { "enemy_id": String, "count": int }
var enemies: Array = []

# 资源配置：Array of { "resource_id": String, "name": String, "amount": int }
var resources: Array = []

# 已清除标记
var is_cleared: bool = false

# 特殊标记
var has_extraction_point: bool = false
var has_npc: bool = false
var npc_type: String = ""
var npc_dialogue: String = ""

# 模板ID
var template_id: String = ""

# 信号
signal zone_cleared
signal zone_entered

## 构造函数
func _init(p_id: String = "", p_type: ZoneType = ZoneType.COMBAT, p_center: Vector2 = Vector2.ZERO):
	id = p_id
	type = p_type
	center = p_center

## 获取区域在世界坐标中的矩形
func get_world_rect() -> Rect2:
	return Rect2(
		center - Vector2(radius, radius),
		Vector2(radius * 2, radius * 2)
	)

## 标记区域已清除
func mark_cleared() -> void:
	if not is_cleared:
		is_cleared = true
		zone_cleared.emit()

## 进入区域
func enter() -> void:
	zone_entered.emit()

## 获取区域类型的中文名称
func get_type_name() -> String:
	match type:
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
		ZoneType.HAZARD:
			return "危险区"
	return "未知"

## 获取总敌人数量
func get_total_enemy_count() -> int:
	var total = 0
	for e in enemies:
		total += e.get("count", 0)
	return total

## 检查点是否在区域内
func contains_point(point: Vector2) -> bool:
	return center.distance_to(point) <= radius

## 获取区域内随机位置
func get_random_position() -> Vector2:
	var angle = randf() * TAU
	var dist = randf() * radius * 0.8  # 留20%边距
	return center + Vector2(cos(angle), sin(angle)) * dist

## 转为字典（用于序列化/调试）
func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": ZoneType.keys()[type],
		"center": {"x": center.x, "y": center.y},
		"radius": radius,
		"difficulty": difficulty,
		"enemies": enemies.duplicate(),
		"resources": resources.duplicate(),
		"is_cleared": is_cleared,
		"has_extraction_point": has_extraction_point,
		"has_npc": has_npc,
	}

## 从字典恢复（用于反序列化）
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	type = ZoneType.get(data.get("type", "COMBAT"), ZoneType.COMBAT)
	var c = data.get("center", {})
	center = Vector2(c.get("x", 0), c.get("y", 0))
	radius = data.get("radius", 300.0)
	difficulty = data.get("difficulty", 1)
	enemies.assign(data.get("enemies", []))
	resources.assign(data.get("resources", []))
	is_cleared = data.get("is_cleared", false)
	has_extraction_point = data.get("has_extraction_point", false)
	has_npc = data.get("has_npc", false)
