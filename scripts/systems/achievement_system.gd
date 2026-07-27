## 成就系统 - 自动加载单例
## 追踪和管理游戏成就
extends Node

# 成就定义
const ACHIEVEMENTS: Dictionary = {
	"first_extract": {
		"name": "初出茅庐",
		"description": "第一次成功撤离",
		"icon": "🏃",
		"reward": {"spirit_stone": 100},
	},
	"layer1_clear": {
		"name": "竹林征服者",
		"description": "通关第1层",
		"icon": "🎋",
		"reward": {"spirit_stone": 200},
	},
	"layer2_clear": {
		"name": "火焰行者",
		"description": "通关第2层",
		"icon": "🔥",
		"reward": {"spirit_stone": 500},
	},
	"layer3_clear": {
		"name": "天机破阵者",
		"description": "通关第3层",
		"icon": "⚙️",
		"reward": {"spirit_stone": 1000},
	},
	"boss_no_hit": {
		"name": "无伤通关",
		"description": "不受伤击败任意Boss",
		"icon": "✨",
		"reward": {"spirit_stone": 500},
	},
	"full_set": {
		"name": "套装大师",
		"description": "装备任意3件套",
		"icon": "👑",
		"reward": {"spirit_stone": 300},
	},
	"max_enhance": {
		"name": "锻造之王",
		"description": "将任意装备强化到+10",
		"icon": "⚒️",
		"reward": {"spirit_stone": 800},
	},
	"all_factions": {
		"name": "三修之道",
		"description": "使用3个不同门派各完成一次撤离",
		"icon": "🎭",
		"reward": {"spirit_stone": 1000},
	},
	"speed_run": {
		"name": "风驰电掣",
		"description": "在3分钟内完成一次撤离",
		"icon": "⚡",
		"reward": {"spirit_stone": 300},
	},
	"hoarder": {
		"name": "仓鼠",
		"description": "仓库中同时拥有10000灵石",
		"icon": "💰",
		"reward": {"spirit_stone": 200},
	},
}

# 已解锁的成就 { achievement_id: timestamp }
var unlocked: Dictionary = {}

# 统计数据
var stats: Dictionary = {
	"total_extracts": 0,
	"total_deaths": 0,
	"total_enemies_killed": 0,
	"total_damage_dealt": 0,
	"total_damage_taken": 0,
	"fastest_extract_time": 999999.0,
	"factions_played": [],
}

signal achievement_unlocked(achievement_id: String, achievement: Dictionary)

func _ready() -> void:
	# 连接信号
	GameManager.game_state_changed.connect(_on_game_state_changed)

## 检查并解锁成就
func check_achievement(achievement_id: String) -> bool:
	if achievement_id in unlocked:
		return false
	if achievement_id not in ACHIEVEMENTS:
		return false

	# 检查条件
	var can_unlock = false
	match achievement_id:
		"first_extract":
			can_unlock = stats.total_extracts >= 1
		"layer1_clear":
			can_unlock = GameManager.current_layer > 1
		"layer2_clear":
			can_unlock = GameManager.current_layer > 2
		"layer3_clear":
			can_unlock = GameManager.current_layer > 3
		"hoarder":
			can_unlock = GameManager.storage.get("spirit_stone", 0) >= 10000

	if can_unlock:
		_unlock(achievement_id)
	return can_unlock

## 解锁成就
func _unlock(achievement_id: String) -> void:
	var achievement = ACHIEVEMENTS[achievement_id]
	unlocked[achievement_id] = Time.get_unix_time_from_system()

	# 发放奖励
	var reward = achievement.get("reward", {})
	for resource_id in reward:
		GameManager.add_to_storage(resource_id, reward[resource_id])

	print("🏆 成就解锁: %s - %s" % [achievement.get("name", ""), achievement.get("description", "")])
	achievement_unlocked.emit(achievement_id, achievement)

## 记录统计
func record_extract(time_seconds: float) -> void:
	stats.total_extracts += 1
	if time_seconds < stats.fastest_extract_time:
		stats.fastest_extract_time = time_seconds

	# 记录门派
	var faction = FactionSystem.get_current_faction()
	if faction not in stats.factions_played:
		stats.factions_played.append(faction)

	# 检查相关成就
	check_achievement("first_extract")
	if time_seconds <= 180.0:
		check_achievement("speed_run")
	if stats.factions_played.size() >= 3:
		check_achievement("all_factions")

func record_death() -> void:
	stats.total_deaths += 1

func record_enemy_kill() -> void:
	stats.total_enemies_killed += 1

## 游戏状态变化回调
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.VICTORY:
			var elapsed = Time.get_unix_time_from_system() - _session_start_time
			record_extract(elapsed)
		GameManager.GameState.GAME_OVER:
			record_death()

# 会话开始时间
var _session_start_time: float = 0.0

## 开始新会话（进入探索时调用）
func start_session() -> void:
	_session_start_time = Time.get_unix_time_from_system()

## 获取已解锁成就列表
func get_unlocked_achievements() -> Array:
	var result = []
	for achievement_id in unlocked:
		var achievement = ACHIEVEMENTS[achievement_id].duplicate()
		achievement["id"] = achievement_id
		achievement["unlocked_at"] = unlocked[achievement_id]
		result.append(achievement)
	return result

## 获取所有成就（含解锁状态）
func get_all_achievements() -> Array:
	var result = []
	for achievement_id in ACHIEVEMENTS:
		var achievement = ACHIEVEMENTS[achievement_id].duplicate()
		achievement["id"] = achievement_id
		achievement["unlocked"] = achievement_id in unlocked
		achievement["unlocked_at"] = unlocked.get(achievement_id, 0)
		result.append(achievement)
	return result

## 序列化
func serialize() -> Dictionary:
	return {
		"unlocked": unlocked.duplicate(),
		"stats": stats.duplicate(),
	}

## 反序列化
func deserialize(data: Dictionary) -> void:
	unlocked = data.get("unlocked", {}).duplicate()
	stats = data.get("stats", {}).duplicate()
