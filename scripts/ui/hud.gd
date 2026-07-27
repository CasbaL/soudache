## 游戏内UI（大地图版本）
## 显示血量、背包、技能、大招充能、区域信息等
extends CanvasLayer

# 统一UI颜色常量
const COLOR_HEALTH_HIGH: Color = Color(0.2, 0.8, 0.2)
const COLOR_HEALTH_MID: Color = Color(0.9, 0.8, 0.1)
const COLOR_HEALTH_LOW: Color = Color(0.9, 0.2, 0.2)
const COLOR_ULTIMATE: Color = Color(0.8, 0.6, 1.0)
const COLOR_SKILL_READY: Color = Color(1.0, 1.0, 1.0)
const COLOR_SKILL_COOLDOWN: Color = Color(0.5, 0.5, 0.5)

# 区域类型枚举值（与MapZone.ZoneType对应）
const ZONE_TYPE_SPAWN = 0
const ZONE_TYPE_COMBAT = 1
const ZONE_TYPE_RESOURCE = 2
const ZONE_TYPE_ELITE = 3
const ZONE_TYPE_BOSS = 4
const ZONE_TYPE_EXTRACT = 5
const ZONE_TYPE_NPC = 6
const ZONE_TYPE_HAZARD = 7

# 区域类型颜色
const ZONE_COLORS: Dictionary = {
	ZONE_TYPE_SPAWN: Color(0.2, 0.8, 0.3),
	ZONE_TYPE_COMBAT: Color(0.9, 0.5, 0.2),
	ZONE_TYPE_RESOURCE: Color(0.3, 0.7, 0.4),
	ZONE_TYPE_ELITE: Color(0.9, 0.3, 0.3),
	ZONE_TYPE_BOSS: Color(1.0, 0.2, 0.2),
	ZONE_TYPE_EXTRACT: Color(0.2, 0.7, 0.9),
	ZONE_TYPE_NPC: Color(0.9, 0.8, 0.3),
	ZONE_TYPE_HAZARD: Color(0.7, 0.3, 0.7),
}

# 节点引用
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var layer_label: Label = $LayerLabel
@onready var inventory_label: Label = $InventoryLabel
@onready var skill_1_button: Button = $SkillBar/Skill1Button
@onready var skill_2_button: Button = $SkillBar/Skill2Button
@onready var skill_3_button: Button = $SkillBar/Skill3Button
@onready var dodge_button: Button = $DodgeButton
@onready var ultimate_button: Button = $UltimateButton
@onready var pause_button: Button = $PauseButton
@onready var joystick = $VirtualJoystick

# 大招充能条（动态创建）
var ultimate_bar: ProgressBar = null
var ultimate_label: Label = null

# 区域信息面板（动态创建）
var zone_info_panel: PanelContainer = null
var zone_name_label: Label = null
var zone_type_label: Label = null
var zone_difficulty_label: Label = null

# 兴趣点指示器（动态创建）
var poi_indicators: Dictionary = {}  # { type: Control }

# 玩家引用
var player: Player = null

func _ready() -> void:
	# 连接按钮信号
	skill_1_button.pressed.connect(_on_skill_1_pressed)
	skill_2_button.pressed.connect(_on_skill_2_pressed)
	skill_3_button.pressed.connect(_on_skill_3_pressed)
	dodge_button.pressed.connect(_on_dodge_pressed)
	ultimate_button.pressed.connect(_on_ultimate_pressed)
	pause_button.pressed.connect(_on_pause_pressed)

	# 连接游戏管理器信号
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.layer_changed.connect(_on_layer_changed)

## 初始化
func initialize(player_ref: Player) -> void:
	player = player_ref

	# 初始化血量显示
	update_health(player.current_health, player.max_health)

	# 初始化层数显示
	update_layer(GameManager.current_layer)

	# 初始化背包显示
	update_inventory()

	# 创建大招充能条
	_create_ultimate_bar()

	# 创建区域信息面板
	_create_zone_info_panel()

	# 连接虚拟摇杆到玩家
	if joystick:
		joystick.joystick_input.connect(_on_joystick_input)

	# 连接大招充能信号
	FactionSystem.ultimate_charge_changed.connect(_on_ultimate_charge_changed)
	FactionSystem.ultimate_ready.connect(_on_ultimate_ready)

	# 统一按钮样式
	_style_buttons()

## 虚拟摇杆输入
func _on_joystick_input(direction: Vector2) -> void:
	if player:
		player.set_joystick_input(direction)

## 更新血量显示
func update_health(current: int, max_val: int) -> void:
	health_bar.max_value = max_val
	health_bar.value = current
	health_label.text = "%d / %d" % [current, max_val]

	# 根据血量百分比改变颜色
	var health_percent = float(current) / float(max_val)
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

## 更新层数显示
func update_layer(current_layer: int) -> void:
	layer_label.text = "第 %d 层" % current_layer

## 更新背包显示
func update_inventory() -> void:
	var count = GameManager.inventory.size()
	var max_count = GameManager.max_inventory_size
	inventory_label.text = "背包: %d / %d" % [count, max_count]

## 更新区域信息显示
func update_zone_info(zone) -> void:
	if not zone_info_panel or not zone:
		return

	# 更新区域名称
	if zone_name_label:
		zone_name_label.text = zone.get_type_name()

	# 更新区域类型
	if zone_type_label:
		zone_type_label.text = _get_zone_description(zone)

	# 更新难度
	if zone_difficulty_label:
		var difficulty = zone.get("difficulty")
		if difficulty and difficulty > 0:
			zone_difficulty_label.text = "难度: " + "★".repeat(difficulty)
			zone_difficulty_label.visible = true
		else:
			zone_difficulty_label.visible = false

	# 更新颜色
	var zone_type = zone.get("type")
	var color = ZONE_COLORS.get(zone_type, Color.WHITE)
	zone_info_panel.modulate = color

	# 显示面板
	zone_info_panel.visible = true

	# 淡入动画
	zone_info_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(zone_info_panel, "modulate:a", 1.0, 0.3)

## 隐藏区域信息
func hide_zone_info() -> void:
	if zone_info_panel:
		zone_info_panel.visible = false

## 获取区域描述
func _get_zone_description(zone) -> String:
	var zone_type = zone.get("type")
	match zone_type:
		ZONE_TYPE_SPAWN:
			return "安全区域"
		ZONE_TYPE_COMBAT:
			return "危险区域 - 有敌人出没"
		ZONE_TYPE_RESOURCE:
			return "资源丰富"
		ZONE_TYPE_ELITE:
			return "精英区域 - 高风险高回报"
		ZONE_TYPE_BOSS:
			return "Boss领域"
		ZONE_TYPE_EXTRACT:
			return "可安全撤离"
		ZONE_TYPE_NPC:
			return "有NPC驻留"
		ZONE_TYPE_HAZARD:
			return "环境危险"
	return ""

## 技能1按钮按下
func _on_skill_1_pressed() -> void:
	if player:
		player.use_skill_1()

## 技能2按钮按下
func _on_skill_2_pressed() -> void:
	if player:
		player.use_skill_2()

## 技能3按钮按下
func _on_skill_3_pressed() -> void:
	if player:
		player.use_skill_3()

## 闪避按钮按下
func _on_dodge_pressed() -> void:
	if player:
		player.dodge()

## 大招按钮按下
func _on_ultimate_pressed() -> void:
	if player:
		player.use_ultimate()

## 暂停按钮按下
func _on_pause_pressed() -> void:
	GameManager.pause_game()

## 游戏状态变化
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			show_pause_menu()
		GameManager.GameState.GAME_OVER:
			show_game_over()
		GameManager.GameState.VICTORY:
			show_victory()

## 背包变化
func _on_inventory_changed() -> void:
	update_inventory()

## 层数变化
func _on_layer_changed(new_layer: int) -> void:
	update_layer(new_layer)

## 显示暂停菜单
func show_pause_menu() -> void:
	print("游戏暂停")

## 显示游戏结束
func show_game_over() -> void:
	print("游戏结束")

## 显示胜利
func show_victory() -> void:
	print("胜利！")

## 创建大招充能条
func _create_ultimate_bar() -> void:
	ultimate_bar = ProgressBar.new()
	ultimate_bar.min_value = 0
	ultimate_bar.max_value = 100
	ultimate_bar.value = 0
	ultimate_bar.show_percentage = false
	ultimate_bar.custom_minimum_size = Vector2(150, 12)
	ultimate_bar.position = Vector2(550, 1165)
	ultimate_bar.modulate = COLOR_ULTIMATE
	add_child(ultimate_bar)

	ultimate_label = Label.new()
	ultimate_label.text = "大招: 0%"
	ultimate_label.add_theme_font_size_override("font_size", 12)
	ultimate_label.add_theme_color_override("font_color", COLOR_ULTIMATE)
	ultimate_label.position = Vector2(550, 1150)
	add_child(ultimate_label)

## 创建区域信息面板
func _create_zone_info_panel() -> void:
	# 创建面板容器
	zone_info_panel = PanelContainer.new()
	zone_info_panel.name = "ZoneInfoPanel"
	zone_info_panel.position = Vector2(20, 110)
	zone_info_panel.custom_minimum_size = Vector2(200, 60)

	# 设置面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.border_color = Color(0.5, 0.5, 0.5, 0.5)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	zone_info_panel.add_theme_stylebox_override("panel", style)

	# 创建垂直布局
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	zone_info_panel.add_child(vbox)

	# 区域名称
	zone_name_label = Label.new()
	zone_name_label.name = "ZoneName"
	zone_name_label.add_theme_font_size_override("font_size", 16)
	zone_name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(zone_name_label)

	# 区域类型描述
	zone_type_label = Label.new()
	zone_type_label.name = "ZoneType"
	zone_type_label.add_theme_font_size_override("font_size", 11)
	zone_type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(zone_type_label)

	# 难度
	zone_difficulty_label = Label.new()
	zone_difficulty_label.name = "Difficulty"
	zone_difficulty_label.add_theme_font_size_override("font_size", 11)
	zone_difficulty_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(zone_difficulty_label)

	zone_info_panel.visible = false
	add_child(zone_info_panel)

## 大招充能变化
func _on_ultimate_charge_changed(current: float, maximum: float) -> void:
	if ultimate_bar:
		ultimate_bar.value = (current / maximum) * 100.0
	if ultimate_label:
		ultimate_label.text = "大招: %d%%" % int((current / maximum) * 100)

## 大招就绪
func _on_ultimate_ready() -> void:
	if ultimate_button:
		ultimate_button.modulate = Color(1.0, 0.8, 0.0)
	if ultimate_label:
		ultimate_label.text = "大招: 就绪！"

## 统一按钮样式
func _style_buttons() -> void:
	var button_font_size = 16
	for btn in [skill_1_button, skill_2_button, skill_3_button]:
		btn.add_theme_font_size_override("font_size", button_font_size)
		btn.custom_minimum_size = Vector2(80, 50)

	dodge_button.add_theme_font_size_override("font_size", button_font_size)
	dodge_button.custom_minimum_size = Vector2(150, 25)

	ultimate_button.add_theme_font_size_override("font_size", button_font_size)
	ultimate_button.custom_minimum_size = Vector2(150, 40)

	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.custom_minimum_size = Vector2(50, 30)
