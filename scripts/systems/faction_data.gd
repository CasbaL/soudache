## 门派数据定义
## 加载 factions.json 并提供查询接口
class_name FactionData
extends RefCounted

# 缓存
static var _data: Dictionary = {}
static var _loaded: bool = false

## 确保数据已加载
static func _ensure_loaded() -> void:
	if _loaded:
		return
	var file = FileAccess.open("res://data/factions.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_data = json.data
	_loaded = true

## 获取所有门派ID列表
static func get_all_faction_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for key in _data:
		ids.append(key)
	return ids

## 获取门派定义
static func get_faction(faction_id: String) -> Dictionary:
	_ensure_loaded()
	return _data.get(faction_id, {})

## 获取门派基础属性
static func get_stats(faction_id: String) -> Dictionary:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return faction.get("stats", {})

## 获取门派普攻配置
static func get_auto_attack(faction_id: String) -> Dictionary:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return faction.get("auto_attack", {})

## 获取门派大招配置
static func get_ultimate(faction_id: String) -> Dictionary:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return faction.get("ultimate", {})

## 获取门派名称
static func get_name(faction_id: String) -> String:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return faction.get("name", "")

## 获取门派标题
static func get_title(faction_id: String) -> String:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return faction.get("title", "")

## 获取门派描述
static func get_description(faction_id: String) -> String:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return faction.get("description", "")

## 获取门派颜色
static func get_color(faction_id: String) -> Color:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return Color(faction.get("color", "#FFFFFF"))

## 获取门派标签
static func get_tags(faction_id: String) -> Array:
	_ensure_loaded()
	var faction = _data.get(faction_id, {})
	return faction.get("tags", [])
