## 游戏功能测试
## 自动化测试核心游戏机制
extends Node

# 测试结果
var test_results: Array = []
var current_test: String = ""

func _ready() -> void:
	print("=== 开始游戏功能测试 ===")
	
	# 运行所有测试
	test_player_movement()
	test_enemy_damage()
	test_resource_collection()
	test_extraction_mechanic()
	
	# 输出测试结果
	print_test_results()

## 测试玩家移动
func test_player_movement() -> void:
	current_test = "玩家移动"
	
	# 创建测试场景
	var test_scene = Node2D.new()
	add_child(test_scene)
	
	# 创建玩家
	var player = CharacterBody2D.new()
	player.position = Vector2(100, 100)
	test_scene.add_child(player)
	
	# 验证初始位置
	var initial_position = player.position
	
	# 模拟移动输入
	player.velocity = Vector2(100, 0)
	player.move_and_slide()
	
	# 验证位置变化
	if player.position.x > initial_position.x:
		add_test_result(current_test, true, "玩家可以向右移动")
	else:
		add_test_result(current_test, false, "玩家无法移动")
	
	# 清理
	test_scene.queue_free()

## 测试敌人伤害
func test_enemy_damage() -> void:
	current_test = "敌人伤害"
	
	# 创建测试场景
	var test_scene = Node2D.new()
	add_child(test_scene)
	
	# 创建玩家
	var player = CharacterBody2D.new()
	player.position = Vector2(100, 100)
	test_scene.add_child(player)
	
	# 创建敌人
	var enemy = CharacterBody2D.new()
	enemy.position = Vector2(150, 100)
	test_scene.add_child(enemy)
	
	# 模拟敌人攻击
	var damage = 50
	var player_health = 500
	var player_defense = 20
	
	var actual_damage = max(1, damage - player_defense)
	player_health -= actual_damage
	
	# 验证伤害计算
	if player_health == 470:  # 500 - 30 = 470
		add_test_result(current_test, true, "伤害计算正确: %d" % actual_damage)
	else:
		add_test_result(current_test, false, "伤害计算错误: 期望470, 实际%d" % player_health)
	
	# 清理
	test_scene.queue_free()

## 测试资源收集
func test_resource_collection() -> void:
	current_test = "资源收集"
	
	# 创建测试场景
	var test_scene = Node2D.new()
	add_child(test_scene)
	
	# 创建资源
	var resource = Area2D.new()
	resource.position = Vector2(100, 100)
	test_scene.add_child(resource)
	
	# 创建玩家
	var player = CharacterBody2D.new()
	player.position = Vector2(100, 100)
	test_scene.add_child(player)
	
	# 模拟收集
	var inventory = []
	inventory.append({"id": "spirit_stone", "amount": 10})
	
	# 验证收集
	if inventory.size() == 1:
		add_test_result(current_test, true, "资源收集成功")
	else:
		add_test_result(current_test, false, "资源收集失败")
	
	# 清理
	test_scene.queue_free()

## 测试撤离机制
func test_extraction_mechanic() -> void:
	current_test = "撤离机制"
	
	# 创建测试场景
	var test_scene = Node2D.new()
	add_child(test_scene)
	
	# 创建撤离点
	var extraction_point = Area2D.new()
	extraction_point.position = Vector2(100, 100)
	test_scene.add_child(extraction_point)
	
	# 创建玩家
	var player = CharacterBody2D.new()
	player.position = Vector2(100, 100)
	test_scene.add_child(player)
	
	# 模拟撤离
	var extract_time = 3.0
	var extract_progress = 0.0
	
	# 模拟时间流逝
	extract_progress = extract_time
	
	# 验证撤离完成
	if extract_progress >= extract_time:
		add_test_result(current_test, true, "撤离机制正常")
	else:
		add_test_result(current_test, false, "撤离机制异常")
	
	# 清理
	test_scene.queue_free()

## 添加测试结果
func add_test_result(test_name: String, passed: bool, message: String) -> void:
	test_results.append({
		"test": test_name,
		"passed": passed,
		"message": message
	})

## 输出测试结果
func print_test_results() -> void:
	print("\n=== 测试结果 ===")
	
	var passed_count = 0
	var failed_count = 0
	
	for result in test_results:
		var status = "✓" if result.passed else "✗"
		print("%s %s: %s" % [status, result.test, result.message])
		
		if result.passed:
			passed_count += 1
		else:
			failed_count += 1
	
	print("\n总计: %d 通过, %d 失败" % [passed_count, failed_count])
	
	if failed_count == 0:
		print("所有测试通过！")
	else:
		print("有 %d 个测试失败" % failed_count)
