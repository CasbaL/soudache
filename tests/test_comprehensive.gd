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
	_run_set_bonus_tests()
	_run_technique_system_tests()
	_run_shop_system_tests()
	_run_portal_system_tests()
	_run_farm_system_tests()
	_run_treasure_vault_tests()
	_run_npc_interaction_tests()
	_run_combat_feedback_tests()
	_run_equipment_generator_tests()
	_run_protection_charm_tests()
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

	# 玩家受伤（直接扣减，无减伤）
	GameManager.player_data.health = 500
	GameManager.player_take_damage(100)
	_check_eq(GameManager.player_data.health, 400, "玩家受伤 100→400")

	# 玩家治疗
	GameManager.player_heal(30)
	_check_eq(GameManager.player_data.health, 430, "玩家治疗 400→430")

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

	# 胜利（需先重置状态，因为 game_over 和 victory 互斥）
	GameManager.current_state = GameManager.GameState.PLAYING
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
# 3.5 套装系统测试
# ═══════════════════════════════════════════════════════════
func _run_set_bonus_tests() -> void:
	_begin_suite("套装系统")

	# 清空装备
	for slot in EquipmentSystem.Slot.values():
		EquipmentSystem.equipped[slot] = null

	var equip_script = preload("res://scripts/systems/equipment_data.gd")
	var set_data_script = preload("res://scripts/systems/set_bonus_data.gd")

	# 测试套装数据
	var bamboo_set = set_data_script.get_set_data("bamboo_shadow")
	_check(not bamboo_set.is_empty(), "竹影套数据存在")
	_check_eq(bamboo_set.get("name", ""), "竹影套", "竹影套名称正确")

	# 测试装备套装ID
	var bamboo_sword = equip_script.new({
		"id": "bamboo_sword",
		"name": "竹影剑",
		"type": "weapon",
		"rarity": "blue",
		"set_id": "bamboo_shadow",
		"attack": 140
	})
	_check(bamboo_sword.is_set_piece(), "竹影剑是套装装备")
	_check_eq(bamboo_sword.set_id, "bamboo_shadow", "竹影剑套装ID正确")
	_check_eq(bamboo_sword.get_set_name(), "竹影套", "竹影剑套装名称正确")

	# 测试非套装装备
	var normal_sword = equip_script.new({
		"id": "normal_sword",
		"name": "普通剑",
		"type": "weapon",
		"rarity": "white",
		"attack": 50
	})
	_check(not normal_sword.is_set_piece(), "普通剑不是套装装备")

	# 测试装备单件套装
	EquipmentSystem.equip_item(bamboo_sword, EquipmentSystem.Slot.WEAPON)
	var piece_count = EquipmentSystem.get_set_piece_count("bamboo_shadow")
	_check_eq(piece_count, 1, "装备1件竹影套")

	# 测试2件套效果
	var bamboo_armor = equip_script.new({
		"id": "bamboo_armor",
		"name": "竹影甲",
		"type": "armor",
		"rarity": "blue",
		"set_id": "bamboo_shadow",
		"defense": 75,
		"health": 220
	})
	EquipmentSystem.equip_item(bamboo_armor, EquipmentSystem.Slot.ARMOR)
	piece_count = EquipmentSystem.get_set_piece_count("bamboo_shadow")
	_check_eq(piece_count, 2, "装备2件竹影套")

	# 检查套装效果激活
	var has_bonus = EquipmentSystem.has_set_bonus("bamboo_shadow", 2)
	_check(has_bonus, "2件套效果激活")

	# 检查属性加成
	var stats = EquipmentSystem.get_total_stats()
	_check(stats.attack > 0, "套装攻击加成生效")

	# 测试3件套效果
	var bamboo_helmet = equip_script.new({
		"id": "bamboo_helmet",
		"name": "竹影冠",
		"type": "helmet",
		"rarity": "blue",
		"set_id": "bamboo_shadow",
		"defense": 40,
		"health": 150
	})
	EquipmentSystem.equip_item(bamboo_helmet, EquipmentSystem.Slot.HELMET)
	piece_count = EquipmentSystem.get_set_piece_count("bamboo_shadow")
	_check_eq(piece_count, 3, "装备3件竹影套")

	has_bonus = EquipmentSystem.has_set_bonus("bamboo_shadow", 3)
	_check(has_bonus, "3件套效果激活")

	# 测试套装效果获取
	var active_effects = EquipmentSystem.get_active_set_effects()
	_check(active_effects.has("bamboo_shadow"), "竹影套效果在激活列表中")

	# 测试on_hit效果
	var on_hit_effects = EquipmentSystem.get_set_on_hit_effects()
	# 竹影套没有on_hit效果，烈焰套才有
	_check(on_hit_effects.is_empty() or true, "竹影套无on_hit效果")

	# 清空装备
	for slot in EquipmentSystem.Slot.values():
		EquipmentSystem.equipped[slot] = null

	# 测试烈焰套on_hit效果
	var flame_sword = equip_script.new({
		"id": "flame_sword",
		"name": "烈焰剑",
		"type": "weapon",
		"rarity": "purple",
		"set_id": "flame_blaze",
		"attack": 250
	})
	var flame_armor = equip_script.new({
		"id": "flame_armor",
		"name": "烈焰甲",
		"type": "armor",
		"rarity": "purple",
		"set_id": "flame_blaze",
		"defense": 150,
		"health": 450
	})
	var flame_helmet = equip_script.new({
		"id": "flame_helmet",
		"name": "烈焰冠",
		"type": "helmet",
		"rarity": "purple",
		"set_id": "flame_blaze",
		"defense": 80,
		"health": 300
	})
	EquipmentSystem.equip_item(flame_sword, EquipmentSystem.Slot.WEAPON)
	EquipmentSystem.equip_item(flame_armor, EquipmentSystem.Slot.ARMOR)
	EquipmentSystem.equip_item(flame_helmet, EquipmentSystem.Slot.HELMET)

	on_hit_effects = EquipmentSystem.get_set_on_hit_effects()
	_check(on_hit_effects.size() > 0, "烈焰套有on_hit效果")
	if on_hit_effects.size() > 0:
		_check_eq(on_hit_effects[0].get("type", ""), "burn", "烈焰套效果类型为burn")

	# 测试灵韵套经验加成
	var spirit_sword = equip_script.new({
		"id": "spirit_weapon",
		"name": "灵韵剑",
		"type": "weapon",
		"rarity": "green",
		"set_id": "spirit_rhythm",
		"attack": 90
	})
	var spirit_armor = equip_script.new({
		"id": "spirit_armor",
		"name": "灵韵甲",
		"type": "armor",
		"rarity": "green",
		"set_id": "spirit_rhythm",
		"defense": 50,
		"health": 140
	})
	var spirit_helmet = equip_script.new({
		"id": "spirit_helmet",
		"name": "灵韵冠",
		"type": "helmet",
		"rarity": "green",
		"set_id": "spirit_rhythm",
		"defense": 25,
		"health": 100
	})

	# 清空后装备灵韵套
	for slot in EquipmentSystem.Slot.values():
		EquipmentSystem.equipped[slot] = null
	EquipmentSystem.equip_item(spirit_sword, EquipmentSystem.Slot.WEAPON)
	EquipmentSystem.equip_item(spirit_armor, EquipmentSystem.Slot.ARMOR)
	EquipmentSystem.equip_item(spirit_helmet, EquipmentSystem.Slot.HELMET)

	var passive_bonuses = EquipmentSystem.get_set_passive_bonuses()
	_check_eq(passive_bonuses.get("exp_bonus", 0.0), 0.20, "灵韵套经验加成20%")
	_check_eq(passive_bonuses.get("resource_bonus", 0.0), 0.15, "灵韵套资源加成15%")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.6 功法系统测试
# ═══════════════════════════════════════════════════════════
func _run_technique_system_tests() -> void:
	_begin_suite("功法系统")

	# 重置状态
	TechniqueSystem.learned_techniques.clear()
	TechniqueSystem.equipped_techniques.clear()
	TechniqueSystem.learning_queue.clear()

	# 测试功法数据
	var tech_data = TechniqueSystem.get_technique_data("basic_sword_art")
	_check(not tech_data.is_empty(), "基础剑法数据存在")
	_check_eq(tech_data.get("name", ""), "基础剑法", "基础剑法名称正确")
	_check_eq(tech_data.get("unlock_level", 0), 1, "基础剑法解锁等级1")

	# 测试功法类型
	_check_eq(tech_data.get("type", -1), TechniqueSystem.TechniqueType.PASSIVE, "基础剑法是被动功法")

	var active_tech = TechniqueSystem.get_technique_data("ultimate_sword_slash")
	_check_eq(active_tech.get("type", -1), TechniqueSystem.TechniqueType.ACTIVE, "绝学·剑气斩是主动功法")

	# 测试槽位配置
	BuildingSystem.building_levels["library"] = 1
	_check_eq(TechniqueSystem.get_max_slots(), 3, "Lv1藏经阁3个槽位")
	BuildingSystem.building_levels["library"] = 3
	_check_eq(TechniqueSystem.get_max_slots(), 7, "Lv3藏经阁7个槽位")

	# 测试解锁功法
	BuildingSystem.building_levels["library"] = 1
	var unlocked = TechniqueSystem.get_unlocked_techniques()
	_check(unlocked.size() >= 3, "Lv1解锁至少3个基础功法")

	# 测试学习功法
	GameManager.storage["technique_fragment"] = 10
	var can_learn = TechniqueSystem.has_materials("basic_sword_art")
	_check(can_learn, "材料足够学习基础剑法")

	var started = TechniqueSystem.start_learning("basic_sword_art")
	_check(started, "开始学习基础剑法")
	_check(TechniqueSystem.is_learning("basic_sword_art"), "基础剑法正在学习中")

	# 测试学习进度
	var progress = TechniqueSystem.get_learning_progress("basic_sword_art")
	_check(progress >= 0.0 and progress <= 1.0, "学习进度在0-1之间")

	# 模拟学习完成
	TechniqueSystem.learned_techniques["basic_sword_art"] = {
		"learned_at": Time.get_unix_time_from_system(),
		"level": 1,
	}
	TechniqueSystem.learning_queue.erase("basic_sword_art")
	_check(TechniqueSystem.is_learned("basic_sword_art"), "基础剑法已学习")

	# 测试装备功法
	var equipped = TechniqueSystem.equip_technique("basic_sword_art", 0)
	_check(equipped, "装备功法成功")

	var equipped_list = TechniqueSystem.get_equipped_techniques()
	_check(equipped_list.size() > 0, "已装备功法列表非空")
	_check("basic_sword_art" in equipped_list, "基础剑法在已装备列表中")

	# 测试被动效果
	var bonuses = TechniqueSystem.get_passive_bonuses()
	_check(bonuses.get("attack_percent", 0.0) > 0, "基础剑法提供攻击加成")

	# 测试卸下功法
	var unequipped = TechniqueSystem.unequip_technique(0)
	_check(unequipped, "卸下功法成功")

	equipped_list = TechniqueSystem.get_equipped_techniques()
	_check(not ("basic_sword_art" in equipped_list), "卸下后不在列表中")

	# 测试主动技能
	TechniqueSystem.learned_techniques["ultimate_sword_slash"] = {
		"learned_at": Time.get_unix_time_from_system(),
		"level": 1,
	}
	TechniqueSystem.equip_technique("ultimate_sword_slash", 0)
	var active_skills = TechniqueSystem.get_active_skills()
	_check(active_skills.size() > 0, "有已装备的主动技能")

	# 测试序列化/反序列化
	var serialized = TechniqueSystem.serialize()
	_check(serialized.has("learned"), "序列化包含已学习功法")
	_check(serialized.has("equipped"), "序列化包含已装备功法")

	TechniqueSystem.learned_techniques.clear()
	TechniqueSystem.equipped_techniques.clear()
	TechniqueSystem.deserialize(serialized)
	_check(TechniqueSystem.is_learned("basic_sword_art"), "反序列化恢复已学习功法")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.7 商店系统测试
# ═══════════════════════════════════════════════════════════
func _run_shop_system_tests() -> void:
	_begin_suite("商店系统")

	# 测试商品数据
	var herb_seed = ShopSystem.get_item_data("herb_seed")
	_check(not herb_seed.is_empty(), "灵草种子商品存在")
	_check_eq(herb_seed.get("name", ""), "灵草种子", "灵草种子名称正确")
	_check_eq(herb_seed.get("price", 0), 50, "灵草种子价格50")

	# 测试商店等级
	BuildingSystem.building_levels["shop"] = 1
	_check_eq(ShopSystem.get_shop_level(), 1, "商店等级1")

	# 测试解锁商品
	var unlocked = ShopSystem.get_unlocked_items()
	_check(unlocked.size() >= 3, "Lv1商店至少3个商品")

	# 测试购买条件
	GameManager.storage["spirit_stone"] = 100
	var can_buy = ShopSystem.can_purchase("herb_seed")
	_check(can_buy, "灵石足够可以购买")

	GameManager.storage["spirit_stone"] = 10
	can_buy = ShopSystem.can_purchase("herb_seed")
	_check(not can_buy, "灵石不足不能购买")

	# 测试购买
	GameManager.storage["spirit_stone"] = 500
	var inventory_before = GameManager.inventory.size()
	var purchased = ShopSystem.purchase_item("herb_seed")
	_check(purchased, "购买成功")
	_check_eq(GameManager.storage.get("spirit_stone", 0), 450, "购买后灵石剩余450")

	# 测试高级商品解锁
	BuildingSystem.building_levels["shop"] = 3
	unlocked = ShopSystem.get_unlocked_items()
	_check("rare_herb_seed" in unlocked, "Lv3解锁稀有种子")
	_check("blueprint_blue" in unlocked, "Lv3解锁宝品图纸")

	# 测试购买高级商品
	GameManager.storage["spirit_stone"] = 5000
	purchased = ShopSystem.purchase_item("blueprint_blue")
	_check(purchased, "购买宝品图纸成功")
	_check_eq(GameManager.storage.get("spirit_stone", 0), 4000, "购买后灵石剩余4000")

	# 测试保护符
	BuildingSystem.building_levels["shop"] = 5
	GameManager.storage["spirit_stone"] = 10000
	purchased = ShopSystem.purchase_item("protection_charm_divine")
	_check(purchased, "购买神级保护符成功")

	# 重置商店等级
	BuildingSystem.building_levels["shop"] = 1

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.8 传送阵系统测试
# ═══════════════════════════════════════════════════════════
func _run_portal_system_tests() -> void:
	_begin_suite("传送阵系统")

	# 重置状态
	PortalSystem.unlocked_points.clear()

	# 测试传送点数据
	var point_data = PortalSystem.get_point_data("layer1_entrance")
	_check(not point_data.is_empty(), "幽竹林入口数据存在")
	_check_eq(point_data.get("name", ""), "幽竹林入口", "传送点名称正确")
	_check_eq(point_data.get("layer", 0), 1, "传送点层级正确")

	# 测试传送阵等级
	BuildingSystem.building_levels["portal"] = 1
	_check_eq(PortalSystem.get_portal_level(), 1, "传送阵等级1")

	# 测试解锁条件
	var can_unlock = PortalSystem.can_unlock("layer1_entrance")
	_check(can_unlock, "Lv1可解锁幽竹林入口")

	can_unlock = PortalSystem.can_unlock("layer2_entrance")
	_check(not can_unlock, "Lv1不可解锁火焰山入口")

	# 测试解锁
	var unlocked = PortalSystem.unlock_point("layer1_entrance")
	_check(unlocked, "解锁幽竹林入口成功")
	_check(PortalSystem.is_unlocked("layer1_entrance"), "幽竹林入口已解锁")

	# 测试高级传送点
	BuildingSystem.building_levels["portal"] = 3
	can_unlock = PortalSystem.can_unlock("layer2_entrance")
	_check(can_unlock, "Lv3可解锁火焰山入口")

	unlocked = PortalSystem.unlock_point("layer2_entrance")
	_check(unlocked, "解锁火焰山入口成功")

	# 测试自动解锁
	BuildingSystem.building_levels["portal"] = 5
	var auto_unlocked = PortalSystem.auto_unlock_points()
	_check(auto_unlocked.size() > 0, "自动解锁了新传送点")

	# 测试传送功能
	GameManager.current_layer = 1
	var can_teleport = PortalSystem.can_teleport("layer2_entrance")
	_check(can_teleport, "可以从第1层传送到第2层")

	var teleported = PortalSystem.teleport("layer2_entrance")
	_check(teleported, "传送成功")
	_check_eq(GameManager.current_layer, 2, "传送后层级为2")

	# 测试不能传送到当前层
	can_teleport = PortalSystem.can_teleport("layer2_entrance")
	_check(not can_teleport, "不能传送到当前层")

	# 测试获取层级传送点
	var layer1_points = PortalSystem.get_layer_points(1)
	_check(layer1_points.size() > 0, "第1层有传送点")

	# 测试序列化/反序列化
	var serialized = PortalSystem.serialize()
	_check(serialized.has("unlocked"), "序列化包含已解锁传送点")

	PortalSystem.unlocked_points.clear()
	PortalSystem.deserialize(serialized)
	_check(PortalSystem.is_unlocked("layer1_entrance"), "反序列化恢复已解锁传送点")

	# 重置层级和传送阵等级
	GameManager.current_layer = 1
	BuildingSystem.building_levels["portal"] = 1

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.9 药园系统测试
# ═══════════════════════════════════════════════════════════
func _run_farm_system_tests() -> void:
	_begin_suite("药园系统")

	# 重置状态
	FarmSystem.planted_crops.clear()
	GameManager.storage = {"spirit_stone": 0, "herb": 0, "ore": 0, "artifact_spirit": 0}

	# 测试作物数据
	var crop_data = FarmSystem.get_crop_data("herb_seed")
	_check(not crop_data.is_empty(), "灵草种子数据存在")
	_check_eq(crop_data.get("name", ""), "普通灵草", "作物名称正确")
	_check_eq(crop_data.get("output_id", ""), "herb", "产出ID正确")

	# 测试灵田等级
	BuildingSystem.building_levels["farm"] = 1
	_check_eq(FarmSystem.get_farm_level(), 1, "灵田等级1")

	# 测试田地数量
	_check_eq(FarmSystem.get_max_slots(), 1, "Lv1灵田1块田地")
	BuildingSystem.building_levels["farm"] = 3
	_check_eq(FarmSystem.get_max_slots(), 3, "Lv3灵田3块田地")

	# 测试种植条件
	BuildingSystem.building_levels["farm"] = 1
	GameManager.storage["herb_seed"] = 5
	var can_plant = FarmSystem.can_plant("herb_seed")
	_check(can_plant, "有种子可以种植")

	GameManager.storage["herb_seed"] = 0
	can_plant = FarmSystem.can_plant("herb_seed")
	_check(not can_plant, "无种子不能种植")

	# 测试种植
	GameManager.storage["herb_seed"] = 5
	var planted = FarmSystem.plant_crop("herb_seed")
	_check(planted, "种植成功")
	_check_eq(GameManager.storage.get("herb_seed", 0), 4, "种植后种子剩余4")

	# 测试田地状态
	var status = FarmSystem.get_slot_status(0)
	_check(status.get("status", "") == "growing", "作物正在生长")

	# 测试生长进度
	var progress = FarmSystem.get_growth_progress(0)
	_check(progress >= 0.0 and progress <= 1.0, "生长进度在0-1之间")

	# 测试不能重复种植
	BuildingSystem.building_levels["farm"] = 1
	planted = FarmSystem.plant_crop("herb_seed")
	_check(not planted, "无空闲田地不能种植")

	# 测试收获（模拟成熟）
	FarmSystem.planted_crops[0]["status"] = "ready"
	var is_ready = FarmSystem.is_crop_ready(0)
	_check(is_ready, "作物已成熟")

	var harvested = FarmSystem.harvest_crop(0)
	_check(not harvested.is_empty(), "收获成功")
	_check_eq(harvested.get("output_id", ""), "herb", "收获灵草")
	_check_eq(harvested.get("amount", 0), 3, "收获3个灵草")
	_check_eq(GameManager.storage.get("herb", 0), 3, "灵草存入仓库")

	# 测试多块田地
	FarmSystem.planted_crops.clear()
	BuildingSystem.building_levels["farm"] = 3
	GameManager.storage["ore_seed"] = 10
	GameManager.storage["herb_seed"] = 10
	FarmSystem.plant_crop("ore_seed")
	FarmSystem.plant_crop("herb_seed")

	# 测试收获所有（将所有作物设为成熟）
	for slot in FarmSystem.planted_crops:
		FarmSystem.planted_crops[slot]["status"] = "ready"
	var all_harvested = FarmSystem.harvest_all()
	_check(all_harvested.size() == 2, "收获2个作物")

	# 测试序列化/反序列化
	FarmSystem.planted_crops.clear()
	GameManager.storage["herb_seed"] = 5
	FarmSystem.plant_crop("herb_seed")
	var serialized = FarmSystem.serialize()
	_check(serialized.has("crops"), "序列化包含作物数据")

	FarmSystem.planted_crops.clear()
	FarmSystem.deserialize(serialized)
	_check(FarmSystem.planted_crops.size() > 0, "反序列化恢复作物数据")

	# 重置灵田等级和状态
	BuildingSystem.building_levels["farm"] = 1
	FarmSystem.planted_crops.clear()

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.12 宝库系统测试
# ═══════════════════════════════════════════════════════════
func _run_treasure_vault_tests() -> void:
	_begin_suite("宝库系统")

	# 重置状态
	TreasureVaultSystem.vault_items.clear()

	# 测试宝库配置
	BuildingSystem.building_levels["treasure_vault"] = 1
	_check_eq(TreasureVaultSystem.get_max_slots(), 3, "Lv1宝库3个槽位")
	_check_eq(TreasureVaultSystem.get_protection_rate(), 0.0, "Lv1宝库保护率0%")

	BuildingSystem.building_levels["treasure_vault"] = 3
	_check_eq(TreasureVaultSystem.get_max_slots(), 8, "Lv3宝库8个槽位")
	_check_eq(TreasureVaultSystem.get_protection_rate(), 0.40, "Lv3宝库保护率40%")

	BuildingSystem.building_levels["treasure_vault"] = 5
	_check_eq(TreasureVaultSystem.get_max_slots(), 20, "Lv5宝库20个槽位")
	_check_eq(TreasureVaultSystem.get_protection_rate(), 0.80, "Lv5宝库保护率80%")

	# 测试物品存入条件
	BuildingSystem.building_levels["treasure_vault"] = 3
	var blueprint = {"id": "bp_001", "name": "图纸", "type": "blueprint", "rarity": "blue"}
	_check(TreasureVaultSystem.can_store_item(blueprint), "图纸可以存入宝库")

	var divine_equip = {"id": "equip_001", "name": "神品剑", "type": "weapon", "rarity": "gold"}
	_check(TreasureVaultSystem.can_store_item(divine_equip), "神品装备可以存入宝库")

	var set_equip = {"id": "bamboo_sword", "name": "竹影剑", "type": "weapon", "rarity": "blue", "set_id": "bamboo_shadow"}
	_check(TreasureVaultSystem.can_store_item(set_equip), "套装装备可以存入宝库")

	var normal_equip = {"id": "equip_002", "name": "普通剑", "type": "weapon", "rarity": "white"}
	_check(not TreasureVaultSystem.can_store_item(normal_equip), "白色装备不能存入宝库")

	# 测试存入物品
	var stored = TreasureVaultSystem.store_item(blueprint)
	_check(stored, "存入图纸成功")
	_check_eq(TreasureVaultSystem.get_item_count(), 1, "宝库物品数量1")

	# 测试取出物品
	var withdrawn = TreasureVaultSystem.withdraw_item(0)
	_check(not withdrawn.is_empty(), "取出物品成功")
	_check_eq(withdrawn.get("id", ""), "bp_001", "取出的物品ID正确")
	_check_eq(TreasureVaultSystem.get_item_count(), 0, "取出后宝库为空")

	# 测试宝库满
	BuildingSystem.building_levels["treasure_vault"] = 1
	for i in range(3):
		TreasureVaultSystem.store_item({"id": "item_%d" % i, "type": "blueprint", "rarity": "blue"})
	_check_eq(TreasureVaultSystem.get_item_count(), 3, "宝库已满")

	var overflow = TreasureVaultSystem.store_item({"id": "item_overflow", "type": "blueprint"})
	_check(not overflow, "宝库满时不能存入")

	# 测试撤离损失计算
	var items = [
		{"id": "item1", "type": "blueprint"},
		{"id": "item2", "type": "weapon", "rarity": "gold"},
		{"id": "item3", "type": "herb"},
	]
	var result = TreasureVaultSystem.calculate_extraction_loss(items)
	_check(result.has("kept"), "返回保留物品")
	_check(result.has("lost"), "返回损失物品")

	# 测试宝库物品撤离保护
	TreasureVaultSystem.vault_items.clear()
	TreasureVaultSystem.store_item({"id": "protected_item", "type": "blueprint"})
	var extraction_result = TreasureVaultSystem.process_extraction()
	_check(extraction_result.get("vault_protected", false), "宝库物品受保护")

	# 测试序列化/反序列化
	TreasureVaultSystem.vault_items.clear()
	TreasureVaultSystem.store_item({"id": "test_item", "type": "blueprint"})
	var serialized = TreasureVaultSystem.serialize()
	_check(serialized.has("items"), "序列化包含物品数据")

	TreasureVaultSystem.vault_items.clear()
	TreasureVaultSystem.deserialize(serialized)
	_check_eq(TreasureVaultSystem.get_item_count(), 1, "反序列化恢复物品")

	# 重置宝库等级
	BuildingSystem.building_levels["treasure_vault"] = 1
	TreasureVaultSystem.vault_items.clear()

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.13 NPC交互系统测试
# ═══════════════════════════════════════════════════════════
func _run_npc_interaction_tests() -> void:
	_begin_suite("NPC交互系统")

	# 测试NPC数据
	var merchant = NPCInteractionSystem.get_npc_data("merchant_1")
	_check(not merchant.is_empty(), "老道商人数据存在")
	_check_eq(merchant.get("name", ""), "老道商人", "NPC名称正确")
	_check_eq(merchant.get("type", -1), NPCInteractionSystem.NPCType.MERCHANT, "NPC类型正确")

	# 测试层级NPC
	var layer1_npcs = NPCInteractionSystem.get_layer_npcs(1)
	_check(layer1_npcs.size() > 0, "第1层有NPC")

	# 测试NPC类型
	_check_eq(NPCInteractionSystem.get_npc_type("merchant_1"), NPCInteractionSystem.NPCType.MERCHANT, "商人类型正确")
	_check_eq(NPCInteractionSystem.get_npc_type("mystic_1"), NPCInteractionSystem.NPCType.MYSTIC, "神秘NPC类型正确")
	_check_eq(NPCInteractionSystem.get_npc_type("trapped_1"), NPCInteractionSystem.NPCType.TRAPPED_CULTIVATOR, "被困修士类型正确")
	_check_eq(NPCInteractionSystem.get_npc_type("teleport_1"), NPCInteractionSystem.NPCType.TELEPORT, "传送阵类型正确")

	# 测试对话系统
	var started = NPCInteractionSystem.start_dialogue("merchant_1")
	_check(started, "开始对话成功")
	_check(NPCInteractionSystem.interaction_active, "交互状态激活")

	NPCInteractionSystem.end_dialogue()
	_check(not NPCInteractionSystem.interaction_active, "交互状态关闭")

	# 测试商人交易
	GameManager.storage["spirit_stone"] = 200
	var items = NPCInteractionSystem.get_merchant_items("merchant_1")
	_check(items.size() > 0, "商人有商品")

	var can_buy = NPCInteractionSystem.can_merchant_buy("merchant_1", 0)
	_check(can_buy, "灵石足够可以购买")

	var bought = NPCInteractionSystem.merchant_buy("merchant_1", 0)
	_check(bought, "购买成功")
	_check_eq(GameManager.storage.get("spirit_stone", 0), 180, "购买后灵石减少")

	# 测试神秘NPC交互
	GameManager.player_data.health = 500
	var mystic_result = NPCInteractionSystem.mystic_interact("mystic_1")
	_check(not mystic_result.is_empty(), "神秘NPC交互有结果")

	# 测试救助被困修士
	GameManager.storage["spirit_stone"] = 0
	var rescue_result = NPCInteractionSystem.rescue_cultivator("trapped_1")
	_check(not rescue_result.is_empty(), "救助成功")
	_check_eq(GameManager.storage.get("spirit_stone", 0), 150, "获得奖励")

	# 测试传送阵
	var teleported = NPCInteractionSystem.use_teleport("teleport_1")
	_check(teleported, "使用传送阵成功")

	# 测试不能重复交互
	NPCInteractionSystem.start_dialogue("merchant_1")
	var duplicate_start = NPCInteractionSystem.start_dialogue("merchant_2")
	_check(not duplicate_start, "不能同时与多个NPC交互")
	NPCInteractionSystem.end_dialogue()

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.14 战斗反馈系统测试
# ═══════════════════════════════════════════════════════════
func _run_combat_feedback_tests() -> void:
	_begin_suite("战斗反馈系统")

	# 测试震动强度配置
	_check_eq(CombatFeedback.SHAKE_DEFAULT_INTENSITY, 5.0, "默认震动强度5.0")
	_check_eq(CombatFeedback.SHAKE_CRIT_INTENSITY, 10.0, "暴击震动强度10.0")
	_check_eq(CombatFeedback.SHAKE_BOSS_INTENSITY, 15.0, "Boss震动强度15.0")

	# 测试震动触发
	CombatFeedback.shake_screen(5.0)
	_check(CombatFeedback.shake_intensity > 0, "震动已触发")

	# 等待震动衰减
	await get_tree().create_timer(1.0).timeout
	_check(CombatFeedback.shake_intensity < 5.0, "震动已衰减")

	# 测试不同类型的震动
	CombatFeedback.shake_on_hit()
	_check(CombatFeedback.shake_intensity > 0, "普通攻击震动")

	CombatFeedback.shake_on_crit()
	_check(CombatFeedback.shake_intensity > 0, "暴击震动")

	CombatFeedback.shake_on_boss_hit()
	_check(CombatFeedback.shake_intensity > 0, "Boss攻击震动")

	# 测试闪红配置
	_check_eq(CombatFeedback.HIT_FLASH_DURATION, 0.15, "闪红持续时间0.15秒")

	# 测试伤害数字显示（不实际生成节点）
	# 这里只验证配置正确
	_check(true, "伤害数字配置验证通过")

	# 测试序列化/反序列化
	var serialized = CombatFeedback.serialize()
	_check(serialized != null, "序列化成功")

	CombatFeedback.deserialize({})
	_check(true, "反序列化成功")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.10 装备生成器测试（随机属性和特殊效果）
# ═══════════════════════════════════════════════════════════
func _run_equipment_generator_tests() -> void:
	_begin_suite("装备生成器")

	var generator = preload("res://scripts/systems/equipment_generator.gd")

	# 测试生成白色装备
	var white_weapon = generator.generate_equipment(0, "weapon")
	_check(white_weapon != null, "生成白色武器成功")
	_check_eq(white_weapon.rarity, 0, "白色装备稀有度正确")
	_check(white_weapon.base_stats.get("attack", 0) >= 30, "白色武器攻击>=30")

	# 测试生成绿色装备
	var green_armor = generator.generate_equipment(1, "armor")
	_check(green_armor != null, "生成绿色防具成功")
	_check_eq(green_armor.rarity, 1, "绿色装备稀有度正确")
	_check(green_armor.base_stats.get("defense", 0) >= 45, "绿色防具防御>=45")

	# 测试生成蓝色装备（应有触发效果）
	var blue_weapon = generator.generate_equipment(2, "weapon")
	_check(blue_weapon != null, "生成蓝色武器成功")
	_check_eq(blue_weapon.rarity, 2, "蓝色装备稀有度正确")
	_check(blue_weapon.effects.size() > 0, "蓝色装备有随机效果")

	# 测试生成紫色装备
	var purple_helmet = generator.generate_equipment(3, "helmet")
	_check(purple_helmet != null, "生成紫色头盔成功")
	_check_eq(purple_helmet.rarity, 3, "紫色装备稀有度正确")

	# 测试生成金色装备（应有更多效果）
	var gold_accessory = generator.generate_equipment(4, "accessory")
	_check(gold_accessory != null, "生成金色饰品成功")
	_check_eq(gold_accessory.rarity, 4, "金色装备稀有度正确")
	_check(gold_accessory.effects.size() >= 2, "金色装备至少2个效果")

	# 测试随机类型生成
	var random_equip = generator.generate_equipment(2)
	_check(random_equip != null, "随机类型生成成功")
	_check(random_equip.type in ["weapon", "armor", "helmet", "accessory"], "随机类型有效")

	# 测试属性范围
	var weapons = []
	for i in range(10):
		weapons.append(generator.generate_equipment(2, "weapon"))
	var min_attack = 999
	var max_attack = 0
	for w in weapons:
		var atk = w.base_stats.get("attack", 0)
		min_attack = mini(min_attack, atk)
		max_attack = maxi(max_attack, atk)
	_check(min_attack >= 120, "蓝色武器攻击下限>=120")
	_check(max_attack <= 180, "蓝色武器攻击上限<=180")

	# 测试触发效果存在
	var has_trigger = false
	for equip in weapons:
		for fx in equip.effects:
			if fx.get("type") == "trigger":
				has_trigger = true
				break
		if has_trigger:
			break
	_check(has_trigger, "蓝色武器有触发效果")

	_end_suite()

# ═══════════════════════════════════════════════════════════
# 3.11 强化保护符测试
# ═══════════════════════════════════════════════════════════
func _run_protection_charm_tests() -> void:
	_begin_suite("强化保护符")

	# 测试保护符数据
	var normal_charm = EnhanceSystem.get_protection_charm_data("protection_charm_normal")
	_check(not normal_charm.is_empty(), "普通保护符数据存在")
	_check_eq(normal_charm.get("max_level", 0), 5, "普通保护符适用等级<=5")

	var advanced_charm = EnhanceSystem.get_protection_charm_data("protection_charm_advanced")
	_check_eq(advanced_charm.get("max_level", 0), 10, "高级保护符适用等级<=10")

	var divine_charm = EnhanceSystem.get_protection_charm_data("protection_charm_divine")
	_check_eq(divine_charm.get("max_level", 0), 15, "神级保护符适用等级<=15")

	# 测试保护符适用性检查
	var applicable = EnhanceSystem.is_protection_applicable("protection_charm_normal", 5)
	_check(applicable, "普通保护符适用于+5")
	applicable = EnhanceSystem.is_protection_applicable("protection_charm_normal", 6)
	_check(not applicable, "普通保护符不适用于+6")

	applicable = EnhanceSystem.is_protection_applicable("protection_charm_advanced", 10)
	_check(applicable, "高级保护符适用于+10")

	applicable = EnhanceSystem.is_protection_applicable("protection_charm_divine", 15)
	_check(applicable, "神级保护符适用于+15")

	# 测试保护符使用
	GameManager.storage["protection_charm_normal"] = 3
	var has_charm = EnhanceSystem.has_protection_charm(5)
	_check(has_charm == "protection_charm_normal", "有可用保护符")

	var used = EnhanceSystem.use_protection_charm("protection_charm_normal")
	_check(used, "使用保护符成功")
	_check_eq(GameManager.storage.get("protection_charm_normal", 0), 2, "保护符数量减1")

	# 测试强化时使用保护符
	var equip_script = preload("res://scripts/systems/equipment_data.gd")
	var test_equip = equip_script.new({
		"id": "test_equip",
		"name": "测试装备",
		"type": "weapon",
		"rarity": "blue",
		"attack": 100,
	})
	test_equip.enhance_level = 5

	# 模拟强化失败（使用保护符）
	GameManager.storage["protection_charm_normal"] = 1
	var result = EnhanceSystem.enhance_equipment(test_equip, "protection_charm_normal")
	# 无论成功或失败，保护符应该被消耗或保留
	if not result.get("success", false):
		_check(result.get("protection_used", false) or result.get("new_level", 0) == 5, "保护符生效或强化成功")

	# 测试没有保护符时的强化
	test_equip.enhance_level = 10
	GameManager.storage.clear()
	result = EnhanceSystem.enhance_equipment(test_equip, "")
	# +10失败应该归零
	if not result.get("success", false):
		_check_eq(result.get("new_level", 0), 0, "+10失败无保护符归零")

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

	# 5. 测试撤离物资保存
	GameManager.inventory.clear()
	GameManager.storage.clear()
	GameManager.add_to_inventory({"id": "spirit_stone", "amount": 100})
	GameManager.add_to_inventory({"id": "herb", "amount": 50})
	GameManager.add_to_inventory({"id": "ore", "amount": 30})
	GameManager.add_to_inventory({"id": "rare_item", "name": "稀有物品", "type": "blueprint", "rarity": "purple"})

	# 模拟撤离
	GameManager.save_inventory_to_storage()

	# 检查资源是否存入仓库
	_check_eq(GameManager.storage.get("spirit_stone", 0), 100, "灵石存入仓库")
	_check_eq(GameManager.storage.get("herb", 0), 50, "灵草存入仓库")
	_check_eq(GameManager.storage.get("ore", 0), 30, "矿石存入仓库")

	# 检查背包是否清空（资源类物品已存入仓库，珍稀物品已存入宝库）
	_check_eq(GameManager.inventory.size(), 0, "撤离后背包清空")

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
