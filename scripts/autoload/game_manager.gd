## 游戏管理器 - 自动加载单例
## 管理游戏全局状态
extends Node

# 游戏状态
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

# 当前状态
var current_state: GameState = GameState.MENU

# 当前层数
var current_layer: int = 1

# 玩家数据
var player_data: Dictionary = {
	"health": 500,
	"max_health": 500,
	"attack": 100,
	"defense": 50,
	"crit_rate": 0.05,
	"crit_damage": 1.5,
	"speed": 200.0
}

# 背包数据
var inventory: Array[Dictionary] = []
var max_inventory_size: int = 10

# 装备快捷引用（与 EquipmentSystem 同步）
var equipped_items: Dictionary = {}  # {slot: EquipmentData}

# 持久化资源（洞府仓库，跨局保留）
var storage: Dictionary = {
	"spirit_stone": 0,
	"herb": 0,
	"ore": 0,
	"artifact_spirit": 0,
}

# 信号
signal game_state_changed(new_state: GameState)
signal player_health_changed(new_health: int)
signal inventory_changed()
signal layer_changed(new_layer: int)
signal storage_changed()

func _ready() -> void:
	# 连接装备变化信号
	if has_node("/root/EquipmentSystem"):
		EquipmentSystem.equipment_changed.connect(_on_equipment_changed)

## 装备变化回调，同步引用
func _on_equipment_changed(_slot: int) -> void:
	equipped_items = EquipmentSystem.equipped.duplicate()

## 获取含装备加成的总攻击力
func get_total_attack() -> int:
	var bonus = EquipmentSystem.get_total_stats()
	return int(player_data.attack + bonus.attack)

## 获取含装备加成的总防御力
func get_total_defense() -> int:
	var bonus = EquipmentSystem.get_total_stats()
	return int(player_data.defense + bonus.defense)

## 获取含装备加成的总生命值
func get_total_max_health() -> int:
	var bonus = EquipmentSystem.get_total_stats()
	return int(player_data.max_health + bonus.health)

## 获取含装备加成的总暴击率
func get_total_crit_rate() -> float:
	var bonus = EquipmentSystem.get_total_stats()
	return player_data.crit_rate + bonus.crit_rate

## 开始新游戏
func start_new_game() -> void:
	current_state = GameState.PLAYING
	current_layer = 1
	
	# 重置玩家数据（选择门派后会被覆盖）
	player_data = {
		"health": 500,
		"max_health": 500,
		"attack": 100,
		"defense": 50,
		"crit_rate": 0.05,
		"crit_damage": 1.5,
		"speed": 200.0
	}
	
	# 清空背包
	inventory.clear()
	
	game_state_changed.emit(current_state)

## 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		if is_inside_tree():
			get_tree().paused = true
		game_state_changed.emit(current_state)

## 恢复游戏
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		if is_inside_tree():
			get_tree().paused = false
		game_state_changed.emit(current_state)

## 游戏结束
func game_over() -> void:
	if current_state == GameState.GAME_OVER or current_state == GameState.VICTORY:
		return  # 防止重复触发
	current_state = GameState.GAME_OVER
	game_state_changed.emit(current_state)
	print("游戏结束！丢失本轮物资")
	_handle_death()

## 处理死亡：慢动作 → 陨落结算 → 返回洞府
func _handle_death() -> void:
	# 慢动作效果
	Engine.time_scale = 0.3
	await Engine.get_main_loop().create_timer(0.6).timeout  # 实际 0.6s，游戏内 0.18s
	Engine.time_scale = 1.0

	# 保留宝库物品，丢失其余背包
	var lost_count := inventory.size()
	if has_node("/root/TreasureVaultSystem"):
		TreasureVaultSystem.process_extraction()
	inventory.clear()
	inventory_changed.emit()
	print("陨落！丢失 %d 件物品" % lost_count)

	# 等待结算界面显示后返回洞府
	await Engine.get_main_loop().create_timer(3.0).timeout
	SceneTransition.go_to_haven()

## 胜利（成功撤离）
func victory() -> void:
	if current_state == GameState.VICTORY or current_state == GameState.GAME_OVER:
		return  # 防止重复触发
	current_state = GameState.VICTORY
	game_state_changed.emit(current_state)

	# 根据层数给予撤离奖励
	_give_extraction_rewards()

	# 保存物资到仓库
	save_inventory_to_storage()
	print("成功撤离！物资已保存")
	# 延迟后返回洞府
	_handle_extraction()

## 根据层数给予撤离奖励
func _give_extraction_rewards() -> void:
	var bonus_stone = 0
	var bonus_herb = 0
	var bonus_ore = 0
	match current_layer:
		1:
			bonus_stone = randi_range(50, 100)
			bonus_herb = randi_range(5, 10)
			bonus_ore = randi_range(5, 10)
		2:
			bonus_stone = randi_range(150, 300)
			bonus_herb = randi_range(15, 30)
			bonus_ore = randi_range(15, 30)
		3:
			bonus_stone = randi_range(400, 800)
			bonus_herb = randi_range(40, 80)
			bonus_ore = randi_range(40, 80)

	storage["spirit_stone"] = storage.get("spirit_stone", 0) + bonus_stone
	storage["herb"] = storage.get("herb", 0) + bonus_herb
	storage["ore"] = storage.get("ore", 0) + bonus_ore
	storage_changed.emit()
	print("撤离奖励: 灵石+%d, 灵草+%d, 矿石+%d" % [bonus_stone, bonus_herb, bonus_ore])

## 处理撤离：延迟后返回洞府
func _handle_extraction() -> void:
	await Engine.get_main_loop().create_timer(1.5).timeout
	SceneTransition.go_to_haven()

## 玩家受伤（伤害已由攻击方通过公式计算）
func player_take_damage(damage: int) -> void:
	player_data.health = max(0, player_data.health - damage)
	player_health_changed.emit(player_data.health)

	if player_data.health <= 0:
		game_over()

## 玩家治疗
func player_heal(amount: int) -> void:
	player_data.health = min(player_data.max_health, player_data.health + amount)
	player_health_changed.emit(player_data.health)

## 添加物品到背包
func add_to_inventory(item: Dictionary) -> bool:
	if inventory.size() >= max_inventory_size:
		print("背包已满！")
		return false
	
	inventory.append(item)
	inventory_changed.emit()
	return true

## 从背包移除物品
func remove_from_inventory(index: int) -> Dictionary:
	if index < 0 or index >= inventory.size():
		return {}
	
	var item = inventory[index]
	inventory.remove_at(index)
	inventory_changed.emit()
	return item

## 保存背包到仓库（撤离时调用）
func save_inventory_to_storage() -> void:
	# 1. 将资源类物品存入仓库
	deposit_inventory_resources()
	
	# 2. 处理宝库物品（完全保护）
	if has_node("/root/TreasureVaultSystem"):
		var vault_result = TreasureVaultSystem.process_extraction()
		print("宝库物品已保护: %d 件" % vault_result.get("vault_items", {}).size())
	
	# 3. 处理剩余背包物品（非资源类，如装备）
	# 装备会保留，但如果有宝库可以存入珍稀装备
	if has_node("/root/TreasureVaultSystem"):
		for i in range(inventory.size() - 1, -1, -1):
			var item = inventory[i]
			if TreasureVaultSystem.can_store_item(item):
				if TreasureVaultSystem.store_item(item):
					inventory.remove_at(i)
					print("珍稀物品已存入宝库: %s" % item.get("name", ""))
	
	print("撤离完成！仓库资源已保存，剩余背包物品: %d 件" % inventory.size())
	inventory_changed.emit()

## 统一伤害计算（百分比减伤公式）
## 返回 { "damage": int, "is_crit": bool }
static func calculate_damage(base_attack: int, skill_mult: float,
							  target_defense: int, crit_rate: float,
							  crit_damage: float) -> Dictionary:
	var is_crit = randf() < crit_rate
	var crit_mult = crit_damage if is_crit else 1.0
	var defense_reduction = 1.0 - (float(target_defense) / (float(target_defense) + 100.0))
	var raw = base_attack * skill_mult * defense_reduction * crit_mult
	var final_damage = maxi(1, roundi(raw))
	return {"damage": final_damage, "is_crit": is_crit}

## 计算战斗力
func get_combat_power() -> int:
	var base = (
		player_data.attack * 1.0 +
		player_data.defense * 0.5 +
		player_data.max_health * 0.2 +
		player_data.crit_rate * 1000 +
		player_data.crit_damage * 100
	)
	# 装备加成
	var equip_bonus = 0
	if has_node("/root/EquipmentSystem"):
		var stats = EquipmentSystem.get_total_stats()
		equip_bonus = int(stats.attack * 1.0 + stats.defense * 0.5 + stats.health * 0.2)
	# 境界加成
	var realm_bonus = 0
	if has_node("/root/RealmSystem"):
		var realm_stats = RealmSystem.get_realm_bonus()
		realm_bonus = int(realm_stats.get("attack", 0) * 0.5 + realm_stats.get("defense", 0) * 0.3)
	return int(base + equip_bonus + realm_bonus)

## 获取推荐层数（基于战斗力）
func get_recommended_layer() -> int:
	var cp = get_combat_power()
	if cp < 2000:
		return 1
	elif cp < 6000:
		return 2
	else:
		return 3

## 进入下一层
func go_to_next_layer() -> void:
	current_layer += 1
	layer_changed.emit(current_layer)
	
	if current_layer > 3:
		# 通关
		victory()
	else:
		# 加载下一层地图
		print("进入第 %d 层" % current_layer)
		# TODO: 生成新地图

# ─── 持久化资源（仓库）操作 ───

## 向仓库添加资源
func add_to_storage(resource_id: String, amount: int) -> void:
	storage[resource_id] = storage.get(resource_id, 0) + amount
	storage_changed.emit()

## 从仓库取出资源到背包，返回实际取出数量（0表示失败）
func withdraw_from_storage(resource_id: String, amount: int) -> int:
	var available: int = storage.get(resource_id, 0)
	if available < amount:
		return 0
	storage[resource_id] = available - amount
	storage_changed.emit()
	return amount

## 将背包中的资源类物品存入仓库
func deposit_inventory_resources() -> void:
	for i in range(inventory.size() - 1, -1, -1):
		var item: Dictionary = inventory[i]
		var item_id: String = item.get("id", "")
		if item_id in ["spirit_stone", "herb", "ore", "artifact_spirit"]:
			var amount: int = item.get("amount", 1)
			add_to_storage(item_id, amount)
			inventory.remove_at(i)
	inventory_changed.emit()

## 获取含建筑加成的最大仓库容量
func get_storage_capacity() -> Dictionary:
	var warehouse_level: int = 1
	if has_node("/root/BuildingSystem"):
		warehouse_level = BuildingSystem.get_building_level("warehouse")
	var caps := [
		{"spirit_stone": 5000, "herb": 200, "ore": 200},
		{"spirit_stone": 10000, "herb": 500, "ore": 500},
		{"spirit_stone": 20000, "herb": 1000, "ore": 1000},
		{"spirit_stone": 50000, "herb": 2000, "ore": 2000},
		{"spirit_stone": 100000, "herb": 5000, "ore": 5000},
	]
	return caps[clampi(warehouse_level - 1, 0, caps.size() - 1)]
