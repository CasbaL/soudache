## 房间过渡控制器
## 管理房间之间的切换逻辑
class_name RoomTransitionController
extends RefCounted

# 房间尺寸（与 RoomData/MapRenderer 一致）
const ROOM_WIDTH: int = 720
const ROOM_HEIGHT: int = 1280
const WALL_THICKNESS: int = 12
const DOOR_WIDTH: int = 80

## 根据方向获取玩家进入新房间后的位置
static func get_entry_position(direction: String) -> Vector2:
	match direction:
		"north":
			# 从北边进入 → 出现在北门附近
			return Vector2(ROOM_WIDTH / 2.0, WALL_THICKNESS + 40)
		"south":
			# 从南边进入 → 出现在南门附近
			return Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - WALL_THICKNESS - 40)
		"east":
			# 从东边进入 → 出现在东门附近
			return Vector2(ROOM_WIDTH - WALL_THICKNESS - 40, ROOM_HEIGHT / 2.0)
		"west":
			# 从西边进入 → 出现在西门附近
			return Vector2(WALL_THICKNESS + 40, ROOM_HEIGHT / 2.0)
		_:
			return Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0)

## 根据方向获取门的触发区域位置和大小
static func get_door_trigger_rect(direction: String) -> Rect2:
	var door_center: Vector2
	var trigger_size: Vector2

	match direction:
		"north":
			door_center = Vector2(ROOM_WIDTH / 2.0, 0)
			trigger_size = Vector2(DOOR_WIDTH, 30)
		"south":
			door_center = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT)
			trigger_size = Vector2(DOOR_WIDTH, 30)
		"east":
			door_center = Vector2(ROOM_WIDTH, ROOM_HEIGHT / 2.0)
			trigger_size = Vector2(30, DOOR_WIDTH)
		"west":
			door_center = Vector2(0, ROOM_HEIGHT / 2.0)
			trigger_size = Vector2(30, DOOR_WIDTH)

	return Rect2(door_center - trigger_size / 2, trigger_size)

## 获取反方向
static func opposite_direction(direction: String) -> String:
	match direction:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
	return ""
