## 游戏内UI
## 显示血量、背包、技能等
extends CanvasLayer

# 节点引用
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var layer_label: Label = $LayerLabel
@onready var inventory_label: Label = $InventoryLabel
@onready var skill_1_button: Button = $SkillBar/Skill1Button
@onready var skill_2_button: Button = $SkillBar/Skill2Button
@onready var skill_3_button: Button = $SkillBar/Skill3Button
@onready var dodge_button: Button = $DodgeButton
@onready var pause_button: Button = $PauseButton
@onready var joystick = $VirtualJoystick

# 玩家引用
var player: Player = null

func _ready() -> void:
	# 连接按钮信号
	skill_1_button.pressed.connect(_on_skill_1_pressed)
	skill_2_button.pressed.connect(_on_skill_2_pressed)
	skill_3_button.pressed.connect(_on_skill_3_pressed)
	dodge_button.pressed.connect(_on_dodge_pressed)
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

	# 连接虚拟摇杆到玩家
	if joystick:
		joystick.joystick_input.connect(_on_joystick_input)

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

## 暂停按钮按下
func _on_pause_pressed() -> void:
	GameManager.pause_game()

## 游戏状态变化
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			# 显示暂停菜单
			show_pause_menu()
		GameManager.GameState.GAME_OVER:
			# 显示游戏结束UI
			show_game_over()
		GameManager.GameState.VICTORY:
			# 显示胜利UI
			show_victory()

## 背包变化
func _on_inventory_changed() -> void:
	update_inventory()

## 层数变化
func _on_layer_changed(new_layer: int) -> void:
	update_layer(new_layer)

## 显示暂停菜单
func show_pause_menu() -> void:
	# TODO: 实现暂停菜单
	print("游戏暂停")

## 显示游戏结束
func show_game_over() -> void:
	# TODO: 实现游戏结束UI
	print("游戏结束")

## 显示胜利
func show_victory() -> void:
	# TODO: 实现胜利UI
	print("胜利！")
