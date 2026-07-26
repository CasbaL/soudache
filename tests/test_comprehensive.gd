## 综合自动化测试
## 覆盖所有核心系统的功能验证
## 运行方式：godot --headless --path <project> scenes/tests/test_comprehensive.tscn
extends Node

# ─── 测试框架 ───────────────────────────────────────────────
var _total_pass: int = 0
var _total_fail: int = 0
var _current_suite: String = ""
var _suite_pass: int = 0
var _suite_fail: int = 0
var _failures: Array[String] = []

func _begin_suite(name: String) -> void:
	_current_suite = name
	_suite_pass = 0
	_suite_fail = 0
	print("\n─── %s ───" % name)

func _check(condition: bool, description: String) -> void:
	if condition:
		_suite_pass += 1
		print("  [PASS] %s" % description)
	else:
		_suite_fail += 1
		_failures.append("%s > %s" % [_current_suite, description])
		print("  [FAIL] %s" % description)

func _check_eq(actual, expected, description: String) -> void:
	_check(actual == expected, "%s (expected %s, got %s)" % [description, str(expected), str(actual)])

func _check_range(value: float, min_val: float, max_val: float, description: String) -> void:
	_check(value >= min_val and value <= max_val, "%s (%.1f in [%.1f, %.1f])" % [description, value, min_val, max_val])

func _end_suite() -> void:
	_total_pass += _suite_pass
	_total_fail += _suite_fail
	print("  → %d pass, %d fail" % [_suite_pass, _suite_fail])

# ─── 主流程 ───────────────────────────────────────────────
func _ready() -> void:
	print("=== 综合自动化测试 ===")
	await get_tree().process_frame  # 等待 autoload 初始化
	await get_tree().process_frame

	# 重置所有系统状态
	_reset_all_states()

	# 运行测试
	_run_game_manager_tests()
	_run_skill_system_tests()
	_run_equipment_system_tests()
	_run_enhance_system_tests()
	_run_faction_system_tests()
	_run_building_system_tests()
	_run_realm_system_tests()
	_run_enemy_spawner_tests()
	_run_inventory_integration_tests()
	_run_save_load_tests()

	# 输出总结
	_print_summary()

	# 退出
	if _total_fail > 0:
		print("\n退出码: 1 (有失败)")
	else:
		print("\n退出码: 0 (全部通过)")
	get_tree().quit(0 if _total_fail == 0 else 1)

func _reset_all_states() -> void:
	# GameManager
	GameManager.current_state = GameManager.GameState.MENU
	GameManager.current_layer = 1
	GameManager.inventory.clear()
	GameManager.storage.clear()
	GameManager.player_data = {
		"health": 500, "max_health": 500,
		"attack": 100, "defense": 50,
		"crit_rate": 0.05, "crit_damage": 1.5,
		"speed": 200.0
	}

	# EquipmentSystem
	for slot in EquipmentSystem.Slot.values():
		EquipmentSystem.equipped[slot] = null

	# BuildingSystem
	for id in BuildingSystem.ALL_BUILDINGS:
		BuildingSystem.building_levels[id] = 1

	# RealmSystem
	RealmSystem.current_realm = 0

	# FactionSystem
	FactionSystem.current_faction = ""
	FactionSystem.ultimate_charge = 0.0

# ═══════════════════════════════════════════════════════════
# 1. GameManager 测试
# ═══════════════════════════════════════════════════════════
func _run_game_manager_tests() -> void:
	_begin_suite("GameManager")

	# 初始状态
	_check_eq(GameManager.current_state, GameManager.GameState.MENU, "初始状态 MENU")

	# 开始新游戏
	GameManager.start_new_game()
	_check_eq(GameManager.current_state, GameManager.GameState.PLAYING, "start_new_game → PLAYING")
	_check_eq(GameManager.current_layer, 1, "start_new_game 重置层数为1")

	# 背包操作
	var item1 = {"id": "spirit_stone", "name": "灵石", "amount": 10}
	var item2 = {"id": "herb", "name": "灵草", "amount": 5}

	var added1 = GameManager.add_to_inventory(item1)
	_check(added1, "添加物品1成功")
	_check_eq(GameManager.inventory.size(), 1, "背包大小1")

	var added2 = GameManager.add_to_inventory(item2)
	_check(added2, "添加物品2成功")
	_check_eq(GameManager.inventory.size(), 2, "背包大小2")

	# 移除物品
	var removed = GameManager.remove_from_inventory(0)
	_check_eq(removed.get("id", ""), "spirit_stone", "移除物品正确")
	_check_eq(GameManager.inventory.size(), 1, "背包大小减1")

	# 背包溢出
	GameManager.inventory.clear()
	for i in GameManager.max_inventory_size:
		GameManager.add_to_inventory({"id": "item_%d" % i})
	var overflow = GameManager.add_to_inventory({"id": "overflow"})
	_check(not overflow, "背包满时添加失败")
	_check_eq(GameManager.inventory.size(), GameManager.max_inventory_size, "背包不超过上限")

	# 仓库存取
	GameManager.storage.clear()
	GameManager.add_to_storage("spirit_stone", 100)
	_check_eq(GameManager.storage.get("spirit_stone", 0), 100, "仓库存入灵石100")

	GameManager.add_to_storage("spirit_stone", 50)
	_check_eq(GameManager.storage.get("spirit_stone", 0), 150, "仓库存入后累加")

	var withdrawn = GameManager.withdraw_from_storage("spirit_stone", 30)
	_check(withdrawn, "仓库取出成功")
	_check_eq(GameManager.storage.get("spirit_stone", 0), 120, "仓库取出后减少")

	# 取出超过库存
	var over_withdraw = GameManager.withdraw_from_storage("spirit_stone", 999)
	_check_eq(over_withdraw, 0, "取出超过库存返回0")

	# 玩家受伤
	GameManager.player_data.health = 500
	GameManager.player_take_damage(100)
	_check_eq(GameManager.player_data.health, 450, "玩家受伤 100→450")

	# 玩家治疗
	GameManager.player_heal(30)
	_check_eq(GameManager.player_data.health, 480, "玩家治疗 450→480")

	# 治疗不超过最大值
	GameManager.player_heal(999)
	_check_eq(GameManager.player_data.health, 500, "治疗不超过max_health")

	# 战斗力计算
	var power = GameManager.get_combat_power()
	_check(power > 0, "战斗力大于0")

	# 暂停/恢复
	GameManager.pause_game()
	_check_eq(GameManager.current_state, GameManager.GameState.PAUSED, "暂停后状态 PAUSED")

	GameManager.resume_game()
	_check_eq(GameManager.current_state, GameManager.GameState.PLAYING, "恢复后状态 PLAYING")

	# 游戏结束
	GameManager.game_over()
	_check_eq(GameManager.current_state, GameManager.GameState.GAME_OVER, "game_over 状态")

	# 胜利
	GameManager.victory()
	_check_eq(GameManager.current_state, GameManager.GameState.VICTORY, "victory 状态")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 2. SkillSystem 测试
# ═══════════════════════════════════════════════════════════
func _run_skill_system_tests() -> void:
	_begin_suite("SkillSystem")

	# 设置门派
	SkillSystem.set_faction("sword")

	# 获取技能
	var skills = SkillSystem.get_faction_skills()
	_check_eq(skills.size(), 3, "剑修有3个技能")

	# 技能数据
	var skill1 = SkillSystem.get_skill_by_slot(1)
	_check(not skill1.is_empty(), "技能槽1非空")
	_check_eq(skill1.get("slot", 0), 1, "技能1的slot=1")

	var skill2 = SkillSystem.get_skill_by_slot(2)
	_check(not skill2.is_empty(), "技能槽2非空")
	_check(skill2.get("cooldown", 0) > 0, "技能2有冷却时间")

	# 切换门派
	SkillSystem.set_faction("talisman")
	var talisman_skills = SkillSystem.get_faction_skills()
	_check_eq(talisman_skills.size(), 3, "符修有3个技能")

	# 丹修
	SkillSystem.set_faction("pill")
	var pill_skills = SkillSystem.get_faction_skills()
	_check_eq(pill_skills.size(), 3, "丹修有3个技能")

	# 无效门派不改变当前门派
	var prev_faction = SkillSystem.current_faction
	SkillSystem.set_faction("invalid_faction")
	_check_eq(SkillSystem.current_faction, prev_faction, "无效门派不改变当前门派")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3. EquipmentSystem 测试
# ═══════════════════════════════════════════════════════════
func _run_equipment_system_tests() -> void:
	_begin_suite("EquipmentSystem")

	# 重置
	for slot in EquipmentSystem.Slot.values():
		EquipmentSystem.equipped[slot] = null

	# 创建装备数据（手动构建，不依赖 EquipmentData 类）
	var equip_script = preload("res://scripts/systems/equipment_data.gd")
	var weapon = equip_script.new({
		"id": "test_sword",
		"name": "测试剑",
		"type": "weapon",
		"rarity": "green",
		"attack": 80,
		"crit_rate": 0.05
	})

	# 装备
	var old = EquipmentSystem.equip_item(weapon, EquipmentSystem.Slot.WEAPON)
	_check(old == null, "首次装备无旧装备")

	var equipped = EquipmentSystem.get_equipped(EquipmentSystem.Slot.WEAPON)
	_check(equipped != null, "装备后可获取")
	_check_eq(equipped.id, "test_sword", "装备ID正确")

	# 属性汇总
	var stats = EquipmentSystem.get_total_stats()
	_check(stats.attack >= 80, "武器攻击计入总属性")

	# 替换装备
	var weapon2 = equip_script.new({
		"id": "test_sword2",
		"name": "测试剑2",
		"type": "weapon",
		"rarity": "blue",
		"attack": 150
	})
	var old2 = EquipmentSystem.equip_item(weapon2, EquipmentSystem.Slot.WEAPON)
	_check(old2 != null, "替换装备返回旧装备")
	_check_eq(old2.id, "test_sword", "旧装备ID正确")

	# 类型不匹配
	var armor = equip_script.new({
		"id": "test_armor",
		"name": "测试甲",
		"type": "armor",
		"rarity": "white",
		"defense": 30
	})
	var mismatch = EquipmentSystem.equip_item(armor, EquipmentSystem.Slot.WEAPON)
	_check(mismatch == null, "类型不匹配装备失败")

	# 正确装备防具
	EquipmentSystem.equip_item(armor, EquipmentSystem.Slot.ARMOR)
	var armor_equipped = EquipmentSystem.get_equipped(EquipmentSystem.Slot.ARMOR)
	_check(armor_equipped != null, "防具装备成功")

	# 卸下
	var unequipped = EquipmentSystem.unequip_item(EquipmentSystem.Slot.WEAPON)
	_check(unequipped != null, "卸下成功")
	_check(EquipmentSystem.get_equipped(EquipmentSystem.Slot.WEAPON) == null, "卸下后为空")

	# 序列化/反序列化
	EquipmentSystem.equip_item(weapon2, EquipmentSystem.Slot.WEAPON)
	var serialized = EquipmentSystem.serialize()
	_check(serialized.size() > 0, "序列化有数据")

	# 清空后反序列化
	for s in EquipmentSystem.Slot.values():
		EquipmentSystem.equipped[s] = null
	EquipmentSystem.deserialize(serialized)
	var restored = EquipmentSystem.get_equipped(EquipmentSystem.Slot.WEAPON)
	_check(restored != null, "反序列化恢复装备")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 4. EnhanceSystem 测试
# ═══════════════════════════════════════════════════════════
func _run_enhance_system_tests() -> void:
	_begin_suite("EnhanceSystem")

	# 成功率
	_check_eq(EnhanceSystem.get_success_rate(0), 1.0, "+1成功率100%")
	_check_eq(EnhanceSystem.get_success_rate(4), 0.70, "+5成功率70%")
	_check_eq(EnhanceSystem.get_success_rate(9), 0.20, "+10成功率20%")
	_check_eq(EnhanceSystem.get_success_rate(14), 0.03, "+15成功率3%")

	# 无效等级
	_check_eq(EnhanceSystem.get_success_rate(-1), 0.0, "负等级成功率0")
	_check_eq(EnhanceSystem.get_success_rate(15), 0.0, "超限等级成功率0")

	# 材料消耗
	var cost0 = EnhanceSystem.get_material_cost(0)
	_check(cost0.has("ling_shi"), "+1消耗灵石")
	_check(cost0.has("qi_ling"), "+1消耗器灵")

	var cost10 = EnhanceSystem.get_material_cost(10)
	_check(cost10.ling_shi > cost0.ling_shi, "+11灵石消耗高于+1")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 5. FactionSystem 测试
# ═══════════════════════════════════════════════════════════
func _run_faction_system_tests() -> void:
	_begin_suite("FactionSystem")

	# 选择门派
	FactionSystem.select_faction("sword")
	_check_eq(FactionSystem.current_faction, "sword", "选择剑修")
	_check_eq(GameManager.player_data.attack, 200, "剑修攻击力200")
	_check_eq(GameManager.player_data.max_health, 500, "剑修生命500")

	# 切换门派
	FactionSystem.select_faction("talisman")
	_check_eq(FactionSystem.current_faction, "talisman", "切换到符修")
	_check_eq(GameManager.player_data.attack, 250, "符修攻击力250")

	FactionSystem.select_faction("pill")
	_check_eq(FactionSystem.current_faction, "pill", "切换到丹修")
	_check_eq(GameManager.player_data.max_health, 600, "丹修生命600")

	# 大招充能
	FactionSystem.ultimate_charge = 0.0
	FactionSystem.add_ultimate_charge(50)
	_check_eq(FactionSystem.ultimate_charge, 50.0, "充能50")

	FactionSystem.add_ultimate_charge(60)
	_check_eq(FactionSystem.ultimate_charge, 100.0, "充能到上限100")

	_check(FactionSystem.is_ultimate_ready(), "大招就绪")

	# 大招配置
	var ult = FactionSystem.get_ultimate_config()
	_check(not ult.is_empty(), "大招配置非空")
	_check(ult.has("name"), "大招有名称")

	# 普攻配置
	var aa = FactionSystem.get_auto_attack_config()
	_check(not aa.is_empty(), "普攻配置非空")
	_check(aa.has("type"), "普攻有类型")

	# 无效门派
	FactionSystem.select_faction("invalid")
	_check_eq(FactionSystem.current_faction, "pill", "无效门派不改变当前")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 6. BuildingSystem 测试
# ═══════════════════════════════════════════════════════════
func _run_building_system_tests() -> void:
	_begin_suite("BuildingSystem")

	# 9栋建筑
	_check_eq(BuildingSystem.ALL_BUILDINGS.size(), 9, "有9栋建筑")

	# 初始等级
	for id in BuildingSystem.ALL_BUILDINGS:
		_check_eq(BuildingSystem.get_building_level(id), 1, "%s 初始等级1" % id)

	# 最大等级
	_check_eq(BuildingSystem.MAX_LEVEL, 5, "最大等级5")

	# 效率加成
	var bonus1 = BuildingSystem.get_building_bonus("alchemy_furnace")
	_check_eq(bonus1, 1.0, "Lv1效率1.0")

	# 升级消耗
	var cost2 = BuildingSystem._get_upgrade_cost_for_level("alchemy_furnace", 2)
	_check(cost2.has("spirit_stone"), "Lv2消耗灵石")
	_check(cost2.has("ore"), "Lv2消耗矿石")

	var cost5 = BuildingSystem._get_upgrade_cost_for_level("alchemy_furnace", 5)
	_check(cost5.has("artifact_spirit"), "Lv5消耗器灵")

	# 升级（需要资源）
	GameManager.storage.clear()
	GameManager.add_to_storage("spirit_stone", 99999)
	GameManager.add_to_storage("ore", 99999)
	GameManager.add_to_storage("herb", 99999)
	GameManager.add_to_storage("artifact_spirit", 99999)

	var upgraded = BuildingSystem.upgrade_building("alchemy_furnace")
	_check(upgraded, "升级成功")
	_check_eq(BuildingSystem.get_building_level("alchemy_furnace"), 2, "升级后等级2")

	# 序列化
	var saved = BuildingSystem.serialize()
	_check(saved.has("alchemy_furnace"), "序列化包含炼丹炉")

	# 反序列化
	for id in BuildingSystem.ALL_BUILDINGS:
		BuildingSystem.building_levels[id] = 1
	BuildingSystem.deserialize(saved)
	_check_eq(BuildingSystem.get_building_level("alchemy_furnace"), 2, "反序列化恢复等级")

	# 资源不足时升级失败
	GameManager.storage.clear()
	var fail_up = BuildingSystem.upgrade_building("forge")
	_check(not fail_up, "资源不足升级失败")

	# 满级检查
	BuildingSystem.building_levels["forge"] = 5
	_check(BuildingSystem.is_max_level("forge"), "满级检查")
	_check(not BuildingSystem.can_upgrade("forge"), "满级不可升级")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 7. RealmSystem 测试
# ═══════════════════════════════════════════════════════════
func _run_realm_system_tests() -> void:
	_begin_suite("RealmSystem")

	# 5个境界
	_check_eq(RealmSystem.REALM_NAMES.size(), 5, "5个境界")
	_check_eq(RealmSystem.REALM_NAMES[0], "炼气", "境界0=炼气")
	_check_eq(RealmSystem.REALM_NAMES[4], "化神", "境界4=化神")

	# 初始境界
	RealmSystem.current_realm = 0
	_check_eq(RealmSystem.get_realm_index(), 0, "初始境界索引0")
	_check_eq(RealmSystem.get_realm_name(), "炼气", "初始境界名")

	# 境界加成
	var bonus0 = RealmSystem.get_realm_bonus()
	_check(bonus0.has("attack"), "炼气有攻击加成")

	# 累积加成
	RealmSystem.current_realm = 2
	var total_bonus = RealmSystem.get_total_realm_bonus()
	_check(total_bonus.attack > bonus0.attack, "累积加成大于单境界")

	# 突破消耗
	var cost1 = RealmSystem.ADVANCE_COSTS[1]
	_check(cost1.has("spirit_stone"), "筑基消耗灵石")

	var cost4 = RealmSystem.ADVANCE_COSTS[4]
	_check(cost4.has("artifact_spirit"), "化神消耗器灵")

	# 最大境界检查
	RealmSystem.current_realm = 4
	_check(RealmSystem.is_max_realm(), "化神是最大境界")

	RealmSystem.current_realm = 0
	_check(not RealmSystem.is_max_realm(), "炼气不是最大境界")

	# 修炼室限制
	BuildingSystem.building_levels["training_room"] = 1
	var max_allowed = RealmSystem.get_max_allowed_realm()
	_check_eq(max_allowed, 0, "Lv1修炼室限炼气")

	BuildingSystem.building_levels["training_room"] = 3
	max_allowed = RealmSystem.get_max_allowed_realm()
	_check_eq(max_allowed, 2, "Lv3修炼室限金丹")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 8. EnemySpawner 测试
# ═══════════════════════════════════════════════════════════
func _run_enemy_spawner_tests() -> void:
	_begin_suite("EnemySpawner")

	# 数据加载
	_check(EnemySpawner._enemy_data.size() > 0, "敌人数据已加载")
	_check(EnemySpawner._enemy_data.has("layer1"), "有第1层数据")
	_check(EnemySpawner._enemy_data.has("layer2"), "有第2层数据")
	_check(EnemySpawner._enemy_data.has("layer3"), "有第3层数据")

	# 注册表
	_check(EnemySpawner._enemy_registry.has("bamboo_spirit"), "竹妖已注册")
	_check(EnemySpawner._enemy_registry.has("fire_spirit"), "火灵已注册")
	_check(EnemySpawner._enemy_registry.has("mechanism_beast"), "机关兽已注册")
	_check(EnemySpawner._enemy_registry.has("bamboo_king"), "竹妖王已注册")
	_check(EnemySpawner._enemy_registry.has("fire_demon"), "火魔已注册")
	_check(EnemySpawner._enemy_registry.has("tianji_elder"), "天机老人已注册")

	# 敌人类型
	_check_eq(EnemySpawner._enemy_registry["bamboo_spirit"].type, "melee", "竹妖是近战")
	_check_eq(EnemySpawner._enemy_registry["bamboo_archer"].type, "ranged", "竹妖射手是远程")
	_check_eq(EnemySpawner._enemy_registry["bamboo_elite"].type, "elite", "竹妖精英是精英")
	_check_eq(EnemySpawner._enemy_registry["bamboo_king"].type, "boss", "竹妖王是Boss")

	# 敌人数据
	var bamboo_data = EnemySpawner._enemy_registry["bamboo_spirit"].data
	_check_eq(bamboo_data.maxHealth, 200, "竹妖血量200")
	_check_eq(bamboo_data.attackDamage, 50, "竹妖攻击50")

	var boss_data = EnemySpawner._enemy_registry["bamboo_king"].data
	_check_eq(boss_data.maxHealth, 8000, "竹妖王血量8000")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 9. 背包集成测试
# ═══════════════════════════════════════════════════════════
func _run_inventory_integration_tests() -> void:
	_begin_suite("背包集成")

	# 清空
	GameManager.inventory.clear()
	GameManager.storage.clear()

	# 搜刮→战斗→撤离循环模拟
	# 1. 搜刮资源
	GameManager.add_to_inventory({"id": "spirit_stone", "name": "灵石", "amount": 100})
	GameManager.add_to_inventory({"id": "herb", "name": "灵草", "amount": 20})
	GameManager.add_to_inventory({"id": "ore", "name": "矿石", "amount": 15})
	_check_eq(GameManager.inventory.size(), 3, "搜刮3种资源")

	# 2. 击败敌人获得掉落
	GameManager.add_to_inventory({"id": "spirit_stone", "name": "灵石", "amount": 50})
	_check_eq(GameManager.inventory.size(), 4, "击败敌人获得掉落")

	# 3. 撤离保存物资
	for item in GameManager.inventory:
		var id = item.get("id", "")
		var amount = item.get("amount", 0)
		GameManager.add_to_storage(id, amount)
	GameManager.inventory.clear()
	_check_eq(GameManager.inventory.size(), 0, "撤离后背包清空")
	_check_eq(GameManager.storage.get("spirit_stone", 0), 150, "灵石存入仓库150")
	_check_eq(GameManager.storage.get("herb", 0), 20, "灵草存入仓库20")

	# 4. 建造消耗资源
	GameManager.storage["spirit_stone"] = 150
	var can_build = BuildingSystem._has_enough_resources({"spirit_stone": 100})
	_check(can_build, "资源足够建造")

	BuildingSystem._consume_resources({"spirit_stone": 100})
	_check_eq(GameManager.storage.get("spirit_stone", 0), 50, "建造消耗后剩余50")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 10. 存档测试
# ═══════════════════════════════════════════════════════════
func _run_save_load_tests() -> void:
	_begin_suite("存档系统")

	# 设置游戏状态
	GameManager.player_data.health = 350
	GameManager.player_data.attack = 200
	GameManager.current_layer = 2
	GameManager.inventory.clear()
	GameManager.add_to_inventory({"id": "test_item", "amount": 1})
	GameManager.storage.clear()
	GameManager.add_to_storage("spirit_stone", 500)

	# 保存
	var saved = SaveManager.save_game()
	_check(saved, "保存成功")

	# 修改状态
	GameManager.player_data.health = 100
	GameManager.current_layer = 1
	GameManager.inventory.clear()
	GameManager.storage.clear()

	# 加载
	var loaded = SaveManager.load_game()
	_check(loaded, "加载成功")
	_check_eq(GameManager.player_data.health, 350, "血量恢复350")
	_check_eq(GameManager.current_layer, 2, "层数恢复2")

	# 清理存档
	SaveManager.delete_save()
	_check(not SaveManager.has_save(), "存档已删除")

	_end_suite()

# ─── 结果输出 ───────────────────────────────────────────────
func _print_summary() -> void:
	print("\n" + "═".repeat(50))
	print("测试结果汇总")
	print("═".repeat(50))

	if _failures.size() > 0:
		print("\n失败项:")
		for f in _failures:
			print("  ✗ %s" % f)

	print("\n总计: %d 通过, %d 失败" % [_total_pass, _total_fail])
	if _total_fail == 0:
		print("✓ 所有测试通过！")
	else:
		print("✗ 有 %d 个测试失败" % _total_fail)
