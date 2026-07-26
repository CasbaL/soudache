## 存档管理器 - 自动加载单例
## 管理游戏存档的保存和加载
extends Node

# 存档路径
const SAVE_PATH = "user://savegame.dat"
const BACKUP_PATH = "user://savegame_backup.dat"

# 当前存档版本
const SAVE_VERSION = 1

# 存档数据
var save_data: Dictionary = {}

func _ready() -> void:
	# 尝试加载存档
	load_game()

## 保存游戏
func save_game() -> bool:
	# 构建存档数据
	save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {
			"name": "玩家",
			"level": 1,
			"realm": "liangqi",
			"exp": 0,
			"health": GameManager.player_data.health,
			"max_health": GameManager.player_data.max_health,
			"attack": GameManager.player_data.attack,
			"defense": GameManager.player_data.defense
		},
		"inventory": GameManager.inventory,
		"storage": GameManager.storage,
		"buildings": BuildingSystem.serialize() if has_node("/root/BuildingSystem") else {},
		"realm": RealmSystem.serialize() if has_node("/root/RealmSystem") else {},
		"alchemy": AlchemySystem.serialize() if has_node("/root/AlchemySystem") else {},
		"crafting": CraftingSystem.serialize() if has_node("/root/CraftingSystem") else {},
		"equipment": EquipmentSystem.serialize(),
		"progress": {
			"current_layer": GameManager.current_layer,
			"max_layer_reached": GameManager.current_layer
		}
	}
	
	# 保存到文件
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("保存失败：无法打开文件")
		return false
	
	file.store_var(save_data)
	file.close()
	
	# 创建备份
	_create_backup()
	
	print("游戏已保存")
	return true

## 加载游戏
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("没有找到存档")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("加载失败：无法打开文件")
		return false
	
	save_data = file.get_var()
	file.close()
	
	# 验证版本
	if not save_data.has("version") or save_data.version != SAVE_VERSION:
		print("存档版本不匹配，尝试迁移...")
		return _migrate_save(save_data)
	
	# 恢复游戏状态
	_restore_game_state()
	
	print("游戏已加载")
	return true

## 恢复游戏状态
func _restore_game_state() -> void:
	if save_data.has("player"):
		var player = save_data.player
		GameManager.player_data.health = player.get("health", 500)
		GameManager.player_data.max_health = player.get("max_health", 500)
		GameManager.player_data.attack = player.get("attack", 100)
		GameManager.player_data.defense = player.get("defense", 50)
	
	if save_data.has("inventory"):
		GameManager.inventory = save_data.inventory
	
	if save_data.has("storage"):
		for key in save_data.storage:
			GameManager.storage[key] = save_data.storage[key]
	
	if save_data.has("buildings") and has_node("/root/BuildingSystem"):
		BuildingSystem.deserialize(save_data.buildings)
	
	if save_data.has("realm") and has_node("/root/RealmSystem"):
		RealmSystem.deserialize(save_data.realm)
	
	if save_data.has("alchemy") and has_node("/root/AlchemySystem"):
		AlchemySystem.deserialize(save_data.alchemy)
	
	if save_data.has("crafting") and has_node("/root/CraftingSystem"):
		CraftingSystem.deserialize(save_data.crafting)
	
	if save_data.has("equipment"):
		EquipmentSystem.deserialize(save_data.equipment)
	
	if save_data.has("progress"):
		GameManager.current_layer = save_data.progress.get("current_layer", 1)

## 创建备份
func _create_backup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_PATH, BACKUP_PATH)

## 迁移存档
func _migrate_save(old_data: Dictionary) -> bool:
	# 简单迁移：保留能识别的数据
	print("存档迁移完成")
	save_data = old_data
	save_data.version = SAVE_VERSION
	_restore_game_state()
	return true

## 删除存档
func delete_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if FileAccess.file_exists(SAVE_PATH):
			dir.remove(SAVE_PATH)
		if FileAccess.file_exists(BACKUP_PATH):
			dir.remove(BACKUP_PATH)
		print("存档已删除")

## 检查存档是否存在
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
