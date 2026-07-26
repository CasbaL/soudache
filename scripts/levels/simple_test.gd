## 简单测试关卡
## 确保可见的游戏世界
extends Node2D

# 游戏状态
var player_health: int = 500
var player_max_health: int = 500
var player_attack: int = 100
var player_defense: int = 50
var inventory: Array = []
var max_inventory: int = 10
var is_game_over: bool = false
var is_victory: bool = false

# UI引用
var health_bar: ProgressBar
var health_label: Label
var inventory_label: Label
var message_label: Label

# 纹理
var player_texture: Texture2D
var enemy_texture: Texture2D
var stone_texture: Texture2D
var herb_texture: Texture2D
var ore_texture: Texture2D
var portal_texture: Texture2D

func _ready() -> void:
	# 设置背景色
	RenderingServer.set_default_clear_color(Color(0.15, 0.15, 0.2))
	
	# 加载纹理
	load_textures()
	
	# 创建游戏世界
	create_world()
	
	# 创建玩家
	create_player()
	
	# 创建敌人
	create_enemies()
	
	# 创建资源
	create_resources()
	
	# 创建撤离点
	create_extraction_point()
	
	# 创建UI
	create_ui()
	
	# 显示开始消息
	show_message("仙侠搜打撤\n\nWASD移动 | 靠近敌人自动攻击\n收集资源 | 到达传送门撤离", 5.0)

func load_textures() -> void:
	player_texture = load("res://assets/sprites/characters/player.png")
	enemy_texture = load("res://assets/sprites/enemies/bamboo_spirit.png")
	stone_texture = load("res://assets/sprites/resources/spirit_stone.png")
	herb_texture = load("res://assets/sprites/resources/herb.png")
	ore_texture = load("res://assets/sprites/resources/ore.png")
	portal_texture = load("res://assets/sprites/effects/extraction_point.png")

func create_world() -> void:
	# 创建地面背景
	var ground = ColorRect.new()
	ground.name = "Ground"
	ground.position = Vector2(0, 0)
	ground.size = Vector2(720, 1280)
	ground.color = Color(0.25, 0.22, 0.18)  # 泥土色
	add_child(ground)
	
	# 创建石板地面（中央区域）
	var floor_rect = ColorRect.new()
	floor_rect.name = "Floor"
	floor_rect.position = Vector2(60, 150)
	floor_rect.size = Vector2(600, 900)
	floor_rect.color = Color(0.35, 0.33, 0.28)  # 石板色
	add_child(floor_rect)
	
	# 创建墙壁边框
	# 上墙
	var wall_top = ColorRect.new()
	wall_top.position = Vector2(60, 120)
	wall_top.size = Vector2(600, 30)
	wall_top.color = Color(0.4, 0.35, 0.3)  # 砖墙色
	add_child(wall_top)
	
	# 下墙
	var wall_bottom = ColorRect.new()
	wall_bottom.position = Vector2(60, 1050)
	wall_bottom.size = Vector2(600, 30)
	wall_bottom.color = Color(0.4, 0.35, 0.3)
	add_child(wall_bottom)
	
	# 左墙
	var wall_left = ColorRect.new()
	wall_left.position = Vector2(30, 150)
	wall_left.size = Vector2(30, 900)
	wall_left.color = Color(0.4, 0.35, 0.3)
	add_child(wall_left)
	
	# 右墙
	var wall_right = ColorRect.new()
	wall_right.position = Vector2(660, 150)
	wall_right.size = Vector2(30, 900)
	wall_right.color = Color(0.4, 0.35, 0.3)
	add_child(wall_right)
	
	# 添加装饰（竹子）
	for i in range(8):
		var bamboo = ColorRect.new()
		bamboo.position = Vector2(80 + i * 75, 160)
		bamboo.size = Vector2(8, 80)
		bamboo.color = Color(0.2, 0.5, 0.2)
		add_child(bamboo)
		
		# 竹叶
		var leaf = ColorRect.new()
		leaf.position = Vector2(75 + i * 75, 150)
		leaf.size = Vector2(18, 15)
		leaf.color = Color(0.3, 0.6, 0.3)
		add_child(leaf)

func create_player() -> void:
	var player = CharacterBody2D.new()
	player.position = Vector2(360, 800)
	player.name = "Player"
	
	# 创建精灵
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = player_texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 32, 48)
	sprite.scale = Vector2(2, 2)  # 放大2倍
	player.add_child(sprite)
	
	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 60)
	collision.shape = shape
	player.add_child(collision)
	
	# 添加脚本
	var script = GDScript.new()
	script.source_code = """extends CharacterBody2D

var speed: float = 200.0
var is_invincible: bool = false
var invincible_timer: float = 0.0
var attack_cooldown: float = 0.5
var can_attack: bool = true
var sprite: Sprite2D

func _ready() -> void:
	sprite = $Sprite2D
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			modulate = Color(1, 1, 1, 1)
	
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
	# 边界限制
	position.x = clamp(position.x, 90, 630)
	position.y = clamp(position.y, 200, 1000)
	
	if input_vector.x != 0:
		sprite.flip_h = input_vector.x < 0
	
	if can_attack:
		auto_attack()

func auto_attack() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var min_distance = 120.0
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	if nearest_enemy:
		attack_enemy(nearest_enemy)

func attack_enemy(enemy: Node2D) -> void:
	can_attack = false
	get_parent().player_attack_enemy(enemy)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(damage: int) -> void:
	if is_invincible:
		return
	
	var actual_damage = max(1, damage - get_parent().player_defense)
	get_parent().player_health -= actual_damage
	get_parent().update_ui()
	
	is_invincible = true
	invincible_timer = 0.5
	modulate = Color(1, 0.5, 0.5, 1)
	
	if get_parent().player_health <= 0:
		get_parent().game_over()
"""
	script.reload()
	player.set_script(script)
	add_child(player)

func create_enemies() -> void:
	var enemy_positions = [
		Vector2(200, 400),
		Vector2(400, 350),
		Vector2(500, 500),
		Vector2(300, 600),
		Vector2(450, 700)
	]
	
	for i in range(5):
		var enemy = CharacterBody2D.new()
		enemy.position = enemy_positions[i]
		enemy.name = "Enemy_%d" % i
		
		# 创建精灵
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = enemy_texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 32, 48)
		sprite.scale = Vector2(2, 2)
		enemy.add_child(sprite)
		
		# 创建碰撞形状
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(40, 60)
		collision.shape = shape
		enemy.add_child(collision)
		
		# 添加脚本
		var script = GDScript.new()
		script.source_code = """extends CharacterBody2D

var health: int = 200
var attack_damage: int = 50
var speed: float = 80.0
var attack_range: float = 80.0
var attack_cooldown: float = 1.0
var can_attack: bool = true
var target: Node2D = null
var sprite: Sprite2D

func _ready() -> void:
	sprite = $Sprite2D
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = null
	
	if target:
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range:
			attack()
		else:
			var direction = (target.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			if velocity.x != 0:
				sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func attack() -> void:
	if not can_attack or not is_instance_valid(target):
		return
	can_attack = false
	target.take_damage(attack_damage)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(damage: int) -> void:
	health -= damage
	modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)
	if health <= 0:
		die()

func die() -> void:
	get_parent().add_resource(global_position)
	queue_free()
"""
		script.reload()
		enemy.set_script(script)
		add_child(enemy)

func create_resources() -> void:
	var resource_data = [
		{"type": "stone", "pos": Vector2(150, 300)},
		{"type": "herb", "pos": Vector2(500, 250)},
		{"type": "ore", "pos": Vector2(250, 500)},
		{"type": "stone", "pos": Vector2(550, 600)},
		{"type": "herb", "pos": Vector2(180, 700)},
		{"type": "ore", "pos": Vector2(400, 800)},
		{"type": "stone", "pos": Vector2(300, 900)},
		{"type": "herb", "pos": Vector2(500, 450)},
	]
	
	for data in resource_data:
		create_single_resource(data.type, data.pos)

func create_single_resource(type: String, pos: Vector2) -> void:
	var resource = Area2D.new()
	resource.position = pos
	resource.name = "Resource_" + type
	
	# 选择纹理
	var texture = stone_texture
	var res_name = "灵石"
	var res_amount = randi_range(10, 30)
	
	if type == "herb":
		texture = herb_texture
		res_name = "灵草"
		res_amount = randi_range(1, 3)
	elif type == "ore":
		texture = ore_texture
		res_name = "矿石"
		res_amount = randi_range(1, 3)
	
	# 创建精灵
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(2, 2)
	resource.add_child(sprite)
	
	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	resource.add_child(collision)
	
	# 添加脚本
	var script = GDScript.new()
	script.source_code = """extends Area2D

var res_name: String = "%s"
var res_amount: int = %d

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if get_parent().inventory.size() < get_parent().max_inventory:
			get_parent().inventory.append({"name": res_name, "amount": res_amount})
			get_parent().update_ui()
			get_parent().show_message("获得: " + res_name + " x" + str(res_amount), 1.0)
			queue_free()
		else:
			get_parent().show_message("背包已满！", 1.0)
""" % [res_name, res_amount]
	script.reload()
	resource.set_script(script)
	add_child(resource)

func create_extraction_point() -> void:
	var portal = Area2D.new()
	portal.position = Vector2(360, 250)
	portal.name = "ExtractionPoint"
	
	# 创建精灵
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = portal_texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 64, 64)
	sprite.scale = Vector2(2, 2)
	portal.add_child(sprite)
	
	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	collision.shape = shape
	portal.add_child(collision)
	
	# 添加脚本
	var script = GDScript.new()
	script.source_code = """extends Area2D

var extract_time: float = 3.0
var extract_progress: float = 0.0
var is_extracting: bool = false
var sprite: Sprite2D

func _ready() -> void:
	sprite = $Sprite2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_extracting:
		extract_progress += delta
		var progress = extract_progress / extract_time
		sprite.modulate = Color(1, 1, 1, 0.5 + progress * 0.5)
		if extract_progress >= extract_time:
			complete_extract()
	else:
		var alpha = 0.7 + sin(Time.get_ticks_msec() * 0.003) * 0.3
		sprite.modulate = Color(1, 1, 1, alpha)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		start_extract()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		cancel_extract()

func start_extract() -> void:
	if is_extracting:
		return
	is_extracting = true
	extract_progress = 0.0
	get_parent().show_message("开始撤离...", 1.0)

func cancel_extract() -> void:
	is_extracting = false
	extract_progress = 0.0
	sprite.modulate = Color(1, 1, 1, 1)
	get_parent().show_message("撤离取消", 1.0)

func complete_extract() -> void:
	is_extracting = false
	get_parent().victory()
"""
	script.reload()
	portal.set_script(script)
	add_child(portal)

func create_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	
	# 血量条背景
	var health_bg = ColorRect.new()
	health_bg.position = Vector2(20, 20)
	health_bg.size = Vector2(200, 25)
	health_bg.color = Color(0.2, 0.2, 0.2, 0.9)
	canvas.add_child(health_bg)
	
	# 血量条
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(22, 22)
	health_bar.size = Vector2(196, 21)
	health_bar.max_value = player_max_health
	health_bar.value = player_health
	health_bar.show_percentage = false
	canvas.add_child(health_bar)
	
	# 血量标签
	health_label = Label.new()
	health_label.position = Vector2(80, 22)
	health_label.text = "%d / %d" % [player_health, player_max_health]
	health_label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(health_label)
	
	# 背包标签
	inventory_label = Label.new()
	inventory_label.position = Vector2(20, 55)
	inventory_label.text = "背包: 0 / %d" % max_inventory
	inventory_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(inventory_label)
	
	# 消息标签
	message_label = Label.new()
	message_label.position = Vector2(360, 1150)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(message_label)
	
	# 操作提示
	var hint = Label.new()
	hint.position = Vector2(20, 1220)
	hint.text = "WASD移动 | 靠近敌人自动攻击 | 到达传送门撤离"
	hint.add_theme_font_size_override("font_size", 12)
	canvas.add_child(hint)

func update_ui() -> void:
	if health_bar:
		health_bar.value = player_health
	if health_label:
		health_label.text = "%d / %d" % [player_health, player_max_health]
	if inventory_label:
		inventory_label.text = "背包: %d / %d" % [inventory.size(), max_inventory]

func show_message(text: String, duration: float = 2.0) -> void:
	if message_label:
		message_label.text = text
		await get_tree().create_timer(duration).timeout
		if message_label and message_label.text == text:
			message_label.text = ""

func player_attack_enemy(enemy: Node2D) -> void:
	if is_instance_valid(enemy) and enemy.has_method("take_damage"):
		enemy.take_damage(player_attack)

func add_resource(pos: Vector2) -> void:
	var types = ["stone", "herb", "ore"]
	var type = types[randi() % 3]
	create_single_resource(type, pos + Vector2(randf_range(-30, 30), randf_range(-30, 30)))

func game_over() -> void:
	is_game_over = true
	show_message("游戏结束！\n\n按R重试", 999.0)

func victory() -> void:
	is_victory = true
	show_message("胜利！成功撤离！\n\n按R重试", 999.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
