## 房间数据类
## 存储房间的类型、位置、连接、敌人、资源等信息
class_name RoomData
extends RefCounted

# 房间类型枚举
enum RoomType {
	START,
	COMBAT,
	RESOURCE,
	EVENT,
	ELITE,
	BOSS,
	EXTRACT,
	SECRET
}

# 房间尺寸（像素）= 一个地图格子
const ROOM_WIDTH: int = 720
const ROOM_HEIGHT: int = 1280

# 房间内布局区域（相对于房间左上角的像素偏移）
const FLOOR_MARGIN: int = 40
const WALL_THICKNESS: int = 8

# 基础属性
var id: String = ""
var type: RoomType = RoomType.COMBAT
var grid_pos: Vector2i = Vector2i.ZERO
var size: Vector2i = Vector2i(1, 1)  # 网格单位，默认1x1

# 连接关系（存储连接到的房间ID）
var connections: Array[String] = []

# 敌人配置：Array of { "enemy_id": String, "count": int }
var enemies: Array[Dictionary] = []

# 资源配置：Array of { "resource_id": String, "name": String, "amount": int }
var resources: Array[Dictionary] = []

# 模板ID（用于查找详细模板）
var template_id: String = ""

# 难度等级（1-5）
var difficulty: int = 1

# 层主题
var layer_theme: String = ""

# 已清除标记
var is_cleared: bool = false

# 特殊标记
var has_extraction_point: bool = false
var has_npc: bool = false
var npc_dialogue: String = ""
var is_secret_visible: bool = false  # 隐藏房间是否已显现

# 信号
signal room_cleared()
signal room_entered()

## 构造函数
func _init(p_id: String = "", p_type: RoomType = RoomType.COMBAT, p_grid_pos: Vector2i = Vector2i.ZERO) -> void:
	id = p_id
	type = p_type
	grid_pos = p_grid_pos

## 获取房间在世界坐标中的矩形（像素）
func get_world_rect() -> Rect2:
	var pixel_pos = Vector2(grid_pos.x * ROOM_WIDTH, grid_pos.y * ROOM_HEIGHT)
	return Rect2(pixel_pos, Vector2(ROOM_WIDTH * size.x, ROOM_HEIGHT * size.y))

## 获取房间中心的世界坐标
func get_world_center() -> Vector2:
	var rect = get_world_rect()
	return rect.get_center()

## 获取房间地板区域（去掉边距）
func get_floor_rect() -> Rect2:
	var world_rect = get_world_rect()
	return Rect2(
		world_rect.position + Vector2(FLOOR_MARGIN, FLOOR_MARGIN),
		world_rect.size - Vector2(FLOOR_MARGIN * 2, FLOOR_MARGIN * 2)
	)

## 添加连接
func connect_to(other_room_id: String) -> void:
	if other_room_id not in connections:
		connections.append(other_room_id)

## 断开连接
func disconnect_from(other_room_id: String) -> void:
	connections.erase(other_room_id)

## 是否与指定房间相邻（网格距离=1）
func is_adjacent_to(other: RoomData) -> bool:
	var diff = grid_pos - other.grid_pos
	return (abs(diff.x) + abs(diff.y)) == 1

## 获取相邻方向到另一个房间
func get_direction_to(other: RoomData) -> String:
	var diff = other.grid_pos - grid_pos
	if diff.x > 0:
		return "east"
	elif diff.x < 0:
		return "west"
	elif diff.y > 0:
		return "south"
	elif diff.y < 0:
		return "north"
	return ""

## 标记房间已清除
func mark_cleared() -> void:
	if not is_cleared:
		is_cleared = true
		room_cleared.emit()

## 进入房间
func enter() -> void:
	room_entered.emit()

## 获取房间类型的中文名称
func get_type_name() -> String:
	match type:
		RoomType.START:
			return "起始"
		RoomType.COMBAT:
			return "战斗"
		RoomType.RESOURCE:
			return "资源"
		RoomType.EVENT:
			return "事件"
		RoomType.ELITE:
			return "精英"
		RoomType.BOSS:
			return "Boss"
		RoomType.EXTRACT:
			return "撤离"
		RoomType.SECRET:
			return "隐藏"
	return "未知"

## 获取总敌人数量
func get_total_enemy_count() -> int:
	var total = 0
	for e in enemies:
		total += e.get("count", 0)
	return total

## 转为字典（用于序列化/调试）
func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": RoomType.keys()[type],
		"grid_pos": {"x": grid_pos.x, "y": grid_pos.y},
		"connections": connections.duplicate(),
		"enemies": enemies.duplicate(),
		"resources": resources.duplicate(),
		"template_id": template_id,
		"difficulty": difficulty,
		"is_cleared": is_cleared,
		"has_extraction_point": has_extraction_point,
		"has_npc": has_npc,
	}

## 从字典恢复（用于反序列化）
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	type = RoomType.get(data.get("type", "COMBAT"), RoomType.COMBAT)
	var gp = data.get("grid_pos", {})
	grid_pos = Vector2i(gp.get("x", 0), gp.get("y", 0))
	connections.assign(data.get("connections", []))
	enemies.assign(data.get("enemies", []))
	resources.assign(data.get("resources", []))
	template_id = data.get("template_id", "")
	difficulty = data.get("difficulty", 1)
	is_cleared = data.get("is_cleared", false)
	has_extraction_point = data.get("has_extraction_point", false)
	has_npc = data.get("has_npc", false)
