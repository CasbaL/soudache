## 开放世界关卡（大地图版本）
## 连续大地图，玩家自由移动，敌人/资源/NPC/撤离点散布在地图各处
extends Node2D

# ============================================================
# 场景引用
# ============================================================

@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var map_renderer: Node2D = $MapRenderer

# Boss UI
var _boss_health_bar: CanvasLayer = null
var _boss_announcement_label: Label = null

# 指南针 UI
var _compass: Control = null

# 区域进入动画
var _zone_enter_label: Label = null
var _zone_enter_tween: Tween = null

# ============================================================
# 预加载脚本
# ============================================================

var _MapGeneratorScript = preload("res://scripts/systems/map_generator.gd")

# ============================================================
# 地图状态
# ============================================================

var _map_generator = null
var _map_data: Dictionary = {}
var _zones: Dictionary = {}  # { id }
var _map_size: Vector2i = Vector2i.ZERO
var _current_zone = null
var _is_transitioning: bool = false

# 实体管理
var _active_enemies: Array[Node2D] = []
var _active_resources: Array[Node2D] = []
var _active_npcs: Array[Node2D] = []
var _extract_entities: Array[Node2D] = []
var _boss_entity: Node2D = null

# ============================================================
# 方向指示器
# ============================================================

var _extract_indicator: Control = null
var _extract_arrow: ColorRect = null
var _extract_label: Label = null
const INDICATOR_MARGIN: float = 60.0

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print("[OpenWorldLevel] _ready 开始")

	# 初始化游戏
	GameManager.start_new_game()

	# 生成大地图
	_generate_map()

	# 连接信号
	_connect_signals()

	# 初始化HUD
	if hud and player:
		hud.initialize(player)

	# 创建撤离点方向指示器
	_create_extract_indicator()

	# 创建指南针
	_create_compass()

	# 创建区域进入动画标签
	_create_zone_enter_label()

	print("[OpenWorldLevel] _ready 完成")

## 生成大地图
func _generate_map() -> void:
	_map_generator = _MapGeneratorScript.new()
	var layer = GameManager.current_layer
	_map_data = _map_generator.generate_layer(layer)
	_zones = _map_data.zones
	_map_size = _map_data.map_size

	print("[OpenWorldLevel] 大地图生成完成: %dx%d, %d 个区域" % [_map_size.x, _map_size.y, _zones.size()])

	# 初始化迷雾系统
	FogSystem.initialize(_zones, _map_size)

	# 初始化渲染器
	if map_renderer:
		map_renderer.set_layer_theme(layer)
		map_renderer.initialize_map(_zones, _map_size)

	# 设置玩家位置（出生点）
	player.position = _map_data.spawn_position

	# 重置摄像机
	if camera:
		camera.reset_smoothing()

	# 生成所有实体
	_spawn_all_entities()

## 连接信号
func _connect_signals() -> void:
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)

# ============================================================
# 实体生成
# ============================================================

## 生成所有实体
func _spawn_all_entities() -> void:
	# 生成敌人
	_spawn_all_enemies()

	# 生成资源
	_spawn_all_resources()

	# 生成NPC
	_spawn_all_npcs()

	# 生成撤离点
	_spawn_all_extract_points()

	# 生成Boss
	_spawn_boss()

## 生成所有敌人
func _spawn_all_enemies() -> void:
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if zone.type == 0 or zone.type == 5:
			continue  # 出生点和撤离点不生成敌人

		for enemy_config in zone.enemies:
			var enemy_id = enemy_config.get("enemy_id", "")
			var count = enemy_config.get("count", 0)
			if enemy_id == "" or count <= 0:
				continue

			for i in range(count):
				var spawn_pos = zone.get_random_position()
				var enemy = EnemySpawner.spawn_enemy(enemy_id, spawn_pos)
				if enemy:
					_active_enemies.append(enemy)
					# 连接死亡信号
					if enemy.has_signal("died"):
						enemy.died.connect(_on_enemy_died.bind(enemy, zone))
					# Boss信号连接
					if enemy is BossEnemy:
						_connect_boss_signals(enemy)

## 生成所有资源
func _spawn_all_resources() -> void:
	for zone_id in _zones:
		var zone = _zones[zone_id]
		for res_config in zone.resources:
			var amount = res_config.get("amount", 1)
			for i in range(amount):
				var spawn_pos = zone.get_random_position()
				_create_resource_pickup(res_config, spawn_pos)

## 生成所有NPC
func _spawn_all_npcs() -> void:
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if not zone.has_npc:
			continue
		_create_npc_entity(zone, zone.center)

## 生成所有撤离点
func _spawn_all_extract_points() -> void:
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if not zone.has_extraction_point:
			continue
		_create_extraction_entity(zone.center, zone)

## 生成Boss
func _spawn_boss() -> void:
	var boss_id = _map_generator._get_boss_id()
	var boss_pos = _map_data.boss_position
	var boss = EnemySpawner.spawn_enemy(boss_id, boss_pos)
	if boss:
		_boss_entity = boss
		_active_enemies.append(boss)
		if boss.has_signal("died"):
			boss.died.connect(_on_boss_died)
		if boss is BossEnemy:
			_connect_boss_signals(boss)

# ============================================================
# 敌人管理
# ============================================================

## 敌人死亡回调
func _on_enemy_died(enemy: Node2D, zone) -> void:
	_active_enemies.erase(enemy)

	# 检查区域是否全部清除
	var zone_enemies_alive = 0
	for e in _active_enemies:
		if is_instance_valid(e) and zone.contains_point(e.position):
			zone_enemies_alive += 1

	if zone_enemies_alive <= 0:
		zone.mark_cleared()
		print("[OpenWorldLevel] 区域已清除: %s (%s)" % [zone.id, zone.get_type_name()])

## Boss信号连接
func _connect_boss_signals(boss: BossEnemy) -> void:
	if not boss.phase_changed.is_connected(_on_boss_phase_changed):
		boss.phase_changed.connect(_on_boss_phase_changed)
	if not boss.boss_announcement.is_connected(_on_boss_announcement):
		boss.boss_announcement.connect(_on_boss_announcement)
	if not boss.died.is_connected(_on_boss_died):
		boss.died.connect(_on_boss_died)
	# 显示Boss血条
	_show_boss_health_bar(boss)

## 显示Boss血条
func _show_boss_health_bar(boss: BossEnemy) -> void:
	if not _boss_health_bar:
		_boss_health_bar = preload("res://scenes/ui/boss_health_bar.tscn").instantiate()
		add_child(_boss_health_bar)
	_boss_health_bar.show_boss(boss.enemy_name, boss.max_health, boss.phases[0].get("name", "阶段1"))

	# 持续更新Boss血量
	var update_timer = Timer.new()
	update_timer.wait_time = 0.1
	update_timer.autostart = true
	boss.add_child(update_timer)
	update_timer.timeout.connect(func():
		if is_instance_valid(boss) and not boss.is_dead:
			_boss_health_bar.update_health(boss.current_health)
		else:
			update_timer.queue_free()
	)

## 隐藏Boss UI
func _hide_boss_ui() -> void:
	if _boss_health_bar:
		_boss_health_bar.hide_boss()

## Boss阶段变化回调
func _on_boss_phase_changed(new_phase: int, phase_name: String) -> void:
	if _boss_health_bar:
		_boss_health_bar.update_phase(phase_name)

## Boss公告回调
func _on_boss_announcement(text: String) -> void:
	if not _boss_announcement_label:
		_boss_announcement_label = Label.new()
		_boss_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_boss_announcement_label.add_theme_font_size_override("font_size", 36)
		_boss_announcement_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_boss_announcement_label.z_index = 200
		_boss_announcement_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_boss_announcement_label.offset_top = 150
		if hud:
			hud.add_child(_boss_announcement_label)
		else:
			add_child(_boss_announcement_label)

	_boss_announcement_label.text = text
	_boss_announcement_label.visible = true
	_boss_announcement_label.modulate.a = 1.0

	# 淡入淡出效果
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(_boss_announcement_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func(): _boss_announcement_label.visible = false)

## Boss死亡回调
func _on_boss_died() -> void:
	_hide_boss_ui()
	print("[OpenWorldLevel] Boss已被击败！")

# ============================================================
# 资源拾取
# ============================================================

## 创建资源拾取物
func _create_resource_pickup(res_config: Dictionary, pos: Vector2) -> void:
	var resource = Area2D.new()
	resource.position = pos
	resource.collision_layer = 4
	resource.collision_mask = 1

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	var res_id = res_config.get("resource_id", "")
	match res_id:
		"spirit_stone":
			sprite.color = Color(0.3, 0.6, 1.0)
		"herb":
			sprite.color = Color(0.2, 0.8, 0.2)
		"ore":
			sprite.color = Color(0.6, 0.4, 0.2)
		"chest":
			sprite.color = Color(0.8, 0.6, 0.2)
		"fire_crystal":
			sprite.color = Color(0.9, 0.3, 0.1)
		"gear":
			sprite.color = Color(0.5, 0.5, 0.6)
		_:
			sprite.color = Color(0.5, 0.5, 0.5)
	resource.add_child(sprite)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	resource.add_child(collision)

	resource.set_meta("resource_id", res_id)
	resource.set_meta("resource_name", res_config.get("name", ""))
	resource.set_meta("amount", res_config.get("amount", 1))

	resource.body_entered.connect(_on_resource_collected.bind(resource))
	add_child(resource)
	_active_resources.append(resource)

## 资源被收集
func _on_resource_collected(body: Node2D, resource: Node2D) -> void:
	if not body is Player:
		return
	var item = {
		"id": resource.get_meta("resource_id", ""),
		"name": resource.get_meta("resource_name", ""),
		"amount": resource.get_meta("amount", 1),
	}
	if GameManager.add_to_inventory(item):
		_active_resources.erase(resource)
		resource.queue_free()

# ============================================================
# NPC交互
# ============================================================

## 创建NPC实体
func _create_npc_entity(zone, pos: Vector2) -> void:
	var npc = Area2D.new()
	npc.position = pos
	npc.collision_layer = 0
	npc.collision_mask = 1

	var sprite = ColorRect.new()
	sprite.size = Vector2(20, 30)
	sprite.position = Vector2(-10, -30)
	sprite.color = Color(0.8, 0.6, 0.2)
	npc.add_child(sprite)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 30)
	collision.shape = shape
	npc.add_child(collision)

	var label = Label.new()
	label.text = "NPC"
	label.position = Vector2(-15, -50)
	label.add_theme_font_size_override("font_size", 12)
	npc.add_child(label)

	npc.body_entered.connect(_on_npc_entered.bind(zone))
	add_child(npc)
	_active_npcs.append(npc)

## 玩家进入NPC区域
func _on_npc_entered(body: Node2D, zone) -> void:
	if not body is Player:
		return
	match zone.npc_type:
		"merchant":
			NPCInteractionSystem.start_dialogue("merchant_%d" % GameManager.current_layer)
		"mystic":
			NPCInteractionSystem.start_dialogue("mystic_%d" % GameManager.current_layer)
		"trapped_cultivator":
			NPCInteractionSystem.rescue_cultivator("trapped_%d" % GameManager.current_layer)

# ============================================================
# 撤离点
# ============================================================

## 创建撤离点实体
func _create_extraction_entity(pos: Vector2, zone) -> void:
	var extract = Area2D.new()
	extract.position = pos
	extract.collision_layer = 8
	extract.collision_mask = 1
	extract.z_index = 100  # 确保在地形之上
	extract.name = "ExtractPoint_%s" % zone.id

	# 视觉：青色大方块
	var sprite = ColorRect.new()
	sprite.size = Vector2(60, 60)
	sprite.position = Vector2(-30, -30)
	sprite.color = Color(0.2, 0.8, 0.8, 0.9)
	extract.add_child(sprite)

	# 闪烁动画（吸引注意）
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "modulate:a", 0.4, 0.8)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.8)

	# 碰撞区域（大一些方便触发）
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	collision.shape = shape
	extract.add_child(collision)

	# 标签
	var label = Label.new()
	label.text = "🚪 撤离点"
	label.position = Vector2(-30, -50)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9))
	extract.add_child(label)

	extract.body_entered.connect(_on_extract_entered.bind(extract, zone))
	add_child(extract)
	_extract_entities.append(extract)

## 撤离确认弹窗
var _extract_confirm_dialog: ConfirmationDialog = null

## 撤离点交互
func _on_extract_entered(body: Node2D, _extract: Node2D, zone) -> void:
	if body is Player:
		print("[OpenWorldLevel] 到达撤离点: %s" % zone.id)
		_show_extract_confirm(zone)

## 显示撤离确认弹窗
func _show_extract_confirm(zone) -> void:
	# 防止重复弹出
	if _extract_confirm_dialog and _extract_confirm_dialog.visible:
		return

	# 先暂停游戏
	get_tree().paused = true

	_extract_confirm_dialog = ConfirmationDialog.new()
	_extract_confirm_dialog.title = "撤离点"
	_extract_confirm_dialog.dialog_text = "是否立即撤离？\n\n背包物品将保存到仓库。\n继续探索可能获得更好奖励。"
	_extract_confirm_dialog.ok_button_text = "撤离"
	_extract_confirm_dialog.cancel_button_text = "继续探索"
	_extract_confirm_dialog.min_size = Vector2(350, 180)

	# 关键：设置弹窗在暂停时也能处理输入
	_extract_confirm_dialog.process_mode = Node.PROCESS_MODE_ALWAYS

	_extract_confirm_dialog.confirmed.connect(_on_extract_confirmed)
	_extract_confirm_dialog.canceled.connect(_on_extract_canceled)

	# 添加到 HUD 层确保在最上层
	if hud:
		hud.add_child(_extract_confirm_dialog)
	else:
		add_child(_extract_confirm_dialog)

	_extract_confirm_dialog.popup_centered()

## 确认撤离
func _on_extract_confirmed() -> void:
	get_tree().paused = false
	GameManager.victory()

## 取消撤离
func _on_extract_canceled() -> void:
	get_tree().paused = false

# ============================================================
# 信号回调
# ============================================================

func _on_player_health_changed(new_health: int) -> void:
	if hud and player:
		hud.update_health(new_health, player.max_health)

func _on_player_died() -> void:
	print("[OpenWorldLevel] 玩家死亡")

# ============================================================
# 物理更新
# ============================================================

func _physics_process(_delta: float) -> void:
	# 更新当前区域
	_update_current_zone()

	# 更新撤离点指示器
	_update_extract_indicator()

	# 管理敌人AI激活状态
	_manage_enemy_activation()

## 更新当前区域
func _update_current_zone() -> void:
	if not player:
		return

	var new_zone = _map_generator.get_zone_at_position(player.position)
	if new_zone != _current_zone:
		var old_zone = _current_zone
		_current_zone = new_zone

		if new_zone:
			new_zone.enter()
			FogSystem.enter_zone(new_zone.id)

			# 更新 HUD 区域信息
			if hud:
				hud.update_zone_info(new_zone)

			# 显示区域进入动画
			_show_zone_enter_animation(new_zone)
		else:
			# 离开所有区域
			if hud:
				hud.hide_zone_info()

## 管理敌人AI激活状态
func _manage_enemy_activation() -> void:
	if not player:
		return

	var player_pos = player.position
	var activation_range = 800.0
	var deactivation_range = 1200.0

	for enemy in _active_enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = player_pos.distance_to(enemy.position)
		if dist < activation_range:
			enemy.set_process(true)
			enemy.set_physics_process(true)
		elif dist > deactivation_range:
			enemy.set_process(false)
			enemy.set_physics_process(false)

# ============================================================
# 撤离点方向指示器
# ============================================================

func _create_extract_indicator() -> void:
	_extract_indicator = Control.new()
	_extract_indicator.name = "ExtractIndicator"
	_extract_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_extract_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if hud:
		hud.add_child(_extract_indicator)
	else:
		add_child(_extract_indicator)

	_extract_arrow = ColorRect.new()
	_extract_arrow.name = "Arrow"
	_extract_arrow.size = Vector2(20, 20)
	_extract_arrow.color = Color(0.2, 0.8, 0.8, 0.8)
	_extract_indicator.add_child(_extract_arrow)

	_extract_label = Label.new()
	_extract_label.name = "DistanceLabel"
	_extract_label.text = "撤离点"
	_extract_label.add_theme_font_size_override("font_size", 14)
	_extract_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.8))
	_extract_indicator.add_child(_extract_label)

## 创建指南针
func _create_compass() -> void:
	_compass = preload("res://scripts/ui/compass.gd").new()
	_compass.name = "Compass"
	_compass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if hud:
		hud.add_child(_compass)
	else:
		add_child(_compass)

	# 初始化指南针
	if player:
		_compass.initialize(player)

	# 设置兴趣点数据
	_setup_compass_poi()

## 设置指南针兴趣点数据
func _setup_compass_poi() -> void:
	if not _compass:
		return

	var poi_data: Array[Dictionary] = []

	# 添加 Boss 位置
	poi_data.append({
		"type": "boss",
		"position": _map_data.boss_position,
		"color": Color(1.0, 0.3, 0.3),
	})

	# 添加撤离点位置
	for extract_pos in _map_data.extract_positions:
		poi_data.append({
			"type": "extract",
			"position": extract_pos,
			"color": Color(0.2, 0.8, 0.8),
		})

	# 添加 NPC 位置
	for zone_id in _zones:
		var zone = _zones[zone_id]
		if zone.has_npc:
			poi_data.append({
				"type": "npc",
				"position": zone.center,
				"color": Color(0.9, 0.8, 0.3),
			})

	_compass.set_poi_data(poi_data)

## 创建区域进入动画标签
func _create_zone_enter_label() -> void:
	_zone_enter_label = Label.new()
	_zone_enter_label.name = "ZoneEnterLabel"
	_zone_enter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_enter_label.add_theme_font_size_override("font_size", 28)
	_zone_enter_label.add_theme_color_override("font_color", Color.WHITE)
	_zone_enter_label.z_index = 150
	_zone_enter_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_zone_enter_label.offset_top = 200
	_zone_enter_label.visible = false

	if hud:
		hud.add_child(_zone_enter_label)
	else:
		add_child(_zone_enter_label)

## 显示区域进入动画
func _show_zone_enter_animation(zone) -> void:
	if not _zone_enter_label:
		return

	# 停止之前的动画
	if _zone_enter_tween and _zone_enter_tween.is_valid():
		_zone_enter_tween.kill()

	# 设置文本
	_zone_enter_label.text = zone.get_type_name()
	_zone_enter_label.visible = true
	_zone_enter_label.modulate.a = 0.0
	_zone_enter_label.scale = Vector2(0.8, 0.8)

	# 设置颜色
	var color = Color.WHITE
	match zone.type:
		1:
			color = Color(0.9, 0.5, 0.2)
		2:
			color = Color(0.3, 0.7, 0.4)
		3:
			color = Color(0.9, 0.3, 0.3)
		4:
			color = Color(1.0, 0.2, 0.2)
		5:
			color = Color(0.2, 0.7, 0.9)
		6:
			color = Color(0.9, 0.8, 0.3)
	_zone_enter_label.add_theme_color_override("font_color", color)

	# 播放动画
	_zone_enter_tween = create_tween()
	_zone_enter_tween.tween_property(_zone_enter_label, "modulate:a", 1.0, 0.3)
	_zone_enter_tween.parallel().tween_property(_zone_enter_label, "scale", Vector2(1.0, 1.0), 0.3)
	_zone_enter_tween.tween_interval(1.0)
	_zone_enter_tween.tween_property(_zone_enter_label, "modulate:a", 0.0, 0.5)
	_zone_enter_tween.tween_callback(func(): _zone_enter_label.visible = false)

func _update_extract_indicator() -> void:
	if not _extract_indicator or not player:
		return

	# 找到最近的撤离点
	var nearest_extract: Node2D = null
	var nearest_dist = 999999.0

	for extract in _extract_entities:
		if not is_instance_valid(extract):
			continue
		var dist = player.position.distance_to(extract.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_extract = extract

	if not nearest_extract:
		_extract_indicator.visible = false
		return

	# 计算方向
	var dir = (nearest_extract.position - player.position).normalized()
	var viewport_size = get_viewport().get_visible_rect().size

	# 计算屏幕边缘位置
	var screen_center = viewport_size / 2
	var arrow_pos = screen_center + dir * (viewport_size.x * 0.4)

	# 限制在屏幕内
	arrow_pos.x = clampf(arrow_pos.x, INDICATOR_MARGIN, viewport_size.x - INDICATOR_MARGIN)
	arrow_pos.y = clampf(arrow_pos.y, INDICATOR_MARGIN, viewport_size.y - INDICATOR_MARGIN)

	_extract_indicator.visible = true
	_extract_arrow.position = arrow_pos - Vector2(10, 10)
	_extract_label.position = arrow_pos + Vector2(15, -8)

	# 显示距离
	var dist_text = ""
	if nearest_dist < 100:
		dist_text = "撤离点 (就在附近!)"
	elif nearest_dist < 500:
		dist_text = "撤离点 (%dm)" % int(nearest_dist / 10)
	else:
		dist_text = "撤离点 →"
	_extract_label.text = dist_text
