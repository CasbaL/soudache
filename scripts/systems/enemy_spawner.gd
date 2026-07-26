## 敌人生成器 - 自动加载单例
## 从enemies.json读取数据，创建敌人实例
extends Node

# 敌人脚本路径（延迟加载，避免类名注册顺序问题）
const MELEE_SCRIPT_PATH = "res://scripts/enemies/melee_enemy.gd"
const RANGED_SCRIPT_PATH = "res://scripts/enemies/ranged_enemy.gd"
const ELITE_SCRIPT_PATH = "res://scripts/enemies/elite_enemy.gd"
const BOSS_SCRIPT_PATHS = {
	"bamboo_king": "res://scripts/enemies/bosses/bamboo_king.gd",
	"fire_demon": "res://scripts/enemies/bosses/fire_demon.gd",
	"tianji_elder": "res://scripts/enemies/bosses/tianji_elder.gd"
}

# 敌人数据
var _enemy_data: Dictionary = {}

# 敌人ID到类型和脚本路径的映射
var _enemy_registry: Dictionary = {}

func _ready() -> void:
	_load_enemy_data()
	_build_registry()

## 加载敌人数据
func _load_enemy_data() -> void:
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			_enemy_data = json.data
		else:
			print("敌人数据解析错误: ", json.get_error_message())
	else:
		print("无法打开敌人数据文件")

## 构建敌人注册表
func _build_registry() -> void:
	for layer_key in _enemy_data:
		var layer = _enemy_data[layer_key]
		
		# 普通敌人
		for enemy in layer.get("enemies", []):
			_enemy_registry[enemy.id] = {
				"data": enemy,
				"script_path": MELEE_SCRIPT_PATH,
				"type": "melee"
			}
		
		# 精英敌人
		for elite in layer.get("elite", []):
			_enemy_registry[elite.id] = {
				"data": elite,
				"script_path": ELITE_SCRIPT_PATH,
				"type": "elite"
			}
		
		# Boss敌人
		var boss = layer.get("boss", {})
		if not boss.is_empty():
			var boss_path = BOSS_SCRIPT_PATHS.get(boss.id, "")
			_enemy_registry[boss.id] = {
				"data": boss,
				"script_path": boss_path,
				"type": "boss"
			}
	
	# 特殊：竹妖射手用远程脚本
	if _enemy_registry.has("bamboo_archer"):
		_enemy_registry["bamboo_archer"].script_path = RANGED_SCRIPT_PATH
		_enemy_registry["bamboo_archer"].type = "ranged"

## 生成敌人
func spawn_enemy(type_id: String, spawn_position: Vector2) -> Node2D:
	if not _enemy_registry.has(type_id):
		print("未知敌人类型: ", type_id)
		return null
	
	var entry = _enemy_registry[type_id]
	var data = entry.data
	var script_path = entry.script_path
	
	if script_path.is_empty():
		print("敌人脚本路径为空: ", type_id)
		return null
	
	# 延迟加载脚本
	var script = load(script_path)
	if script == null:
		print("无法加载敌人脚本: ", script_path)
		return null
	
	# 创建敌人节点
	var enemy = CharacterBody2D.new()
	enemy.set_script(script)
	
	# 设置碰撞层
	enemy.collision_layer = 2  # 第2层（敌人）
	enemy.collision_mask = 1   # 第1层（玩家）
	
	# 设置位置
	enemy.position = spawn_position
	
	# 创建子节点
	_create_enemy_nodes(enemy, data)
	
	# 设置属性
	_apply_enemy_data(enemy, data)
	
	# 添加到场景
	get_tree().current_scene.add_child(enemy)
	
	# 连接掉落信号
	if enemy.has_signal("dropped_items"):
		enemy.dropped_items.connect(_on_enemy_dropped_items)
	
	print("生成敌人: %s (%s) 位置: %s" % [data.get("name", "?"), type_id, str(spawn_position)])
	return enemy

## 生成Boss
func spawn_boss(boss_id: String, spawn_position: Vector2) -> Node2D:
	var enemy = spawn_enemy(boss_id, spawn_position)
	if enemy:
		var boss_name = boss_id
		if "enemy_name" in enemy:
			boss_name = enemy.enemy_name
		print("=== BOSS 出现: %s ===" % boss_name)
	return enemy

## 生成一波敌人
func spawn_wave(enemy_types: Array, positions: Array) -> Array:
	var spawned: Array = []
	
	for i in min(enemy_types.size(), positions.size()):
		var enemy = spawn_enemy(enemy_types[i], positions[i])
		if enemy:
			spawned.append(enemy)
	
	print("生成敌人波次: %d 个敌人" % spawned.size())
	return spawned

## 创建敌人的子节点结构
func _create_enemy_nodes(enemy: Node2D, data: Dictionary) -> void:
	# Sprite2D
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	enemy.add_child(sprite)
	
	# CollisionShape2D
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	
	# 根据类型设置碰撞大小
	match data.get("id", ""):
		"bamboo_king", "fire_demon", "tianji_elder":
			shape.size = Vector2(64, 64)
		"bamboo_elite", "fire_giant", "mechanism_general":
			shape.size = Vector2(40, 40)
		_:
			shape.size = Vector2(32, 32)
	
	collision.shape = shape
	enemy.add_child(collision)
	
	# AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	enemy.add_child(anim_player)
	
	# AttackTimer
	var attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.one_shot = true
	enemy.add_child(attack_timer)
	
	# DetectArea
	var detect_area = Area2D.new()
	detect_area.name = "DetectArea"
	enemy.add_child(detect_area)
	
	var detect_collision = CollisionShape2D.new()
	detect_collision.name = "DetectCollision"
	var detect_shape = CircleShape2D.new()
	detect_shape.radius = data.get("detectRange", 200.0)
	detect_collision.shape = detect_shape
	detect_area.add_child(detect_collision)
	
	# AttackArea
	var attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	enemy.add_child(attack_area)
	
	var attack_collision = CollisionShape2D.new()
	attack_collision.name = "AttackCollision"
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = data.get("attackRange", 50.0)
	attack_collision.shape = attack_shape
	attack_area.add_child(attack_collision)

## 应用敌人数据
func _apply_enemy_data(enemy: Node2D, data: Dictionary) -> void:
	if "enemy_name" in enemy:
		enemy.enemy_name = data.get("name", "未知")
	if "max_health" in enemy:
		enemy.max_health = data.get("maxHealth", 100)
		enemy.current_health = enemy.max_health
	if "attack_damage" in enemy:
		enemy.attack_damage = data.get("attackDamage", 50)
	if "defense" in enemy:
		enemy.defense = data.get("defense", 10)
	if "speed" in enemy:
		enemy.speed = data.get("speed", 100.0)
	if "attack_range" in enemy:
		enemy.attack_range = data.get("attackRange", 50.0)
	if "attack_cooldown" in enemy:
		enemy.attack_cooldown = data.get("attackCooldown", 1.0)
	if "detect_range" in enemy:
		enemy.detect_range = data.get("detectRange", 200.0)
	
	# 设置掉落物
	if "drop_items" in enemy:
		var drops = data.get("dropItems", [])
		if drops.size() > 0:
			enemy.drop_items.clear()
			for drop in drops:
				enemy.drop_items.append(drop)

## 敌人掉落处理
func _on_enemy_dropped_items(items: Array) -> void:
	for item in items:
		GameManager.add_to_inventory(item)
		print("获得物品: %s x%d" % [item.get("name", "?"), item.get("amount", 1)])
