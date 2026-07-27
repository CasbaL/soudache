## 游戏结束/胜利界面
## 显示结果、击杀数、返回洞府按钮
extends CanvasLayer

# 子节点引用
@onready var overlay: ColorRect = $Overlay
@onready var panel: VBoxContainer = $Overlay/Panel
@onready var title_label: Label = $Overlay/Panel/Title
@onready var stats_label: Label = $Overlay/Panel/Stats
@onready var return_btn: Button = $Overlay/Panel/ReturnButton

# 统计数据
var enemies_killed: int = 0
var items_collected: int = 0

func _ready() -> void:
	# 默认隐藏
	visible = false

	# 设置遮罩
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# 标题
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)

	# 统计
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 20)

	# 返回洞府按钮
	return_btn.text = "返回洞府"
	return_btn.pressed.connect(_on_return_pressed)

	# 连接信号
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)

	# 连接敌人击杀信号
	var tree = get_tree()
	if tree:
		tree.node_added.connect(_on_node_added)

## 统计敌人击杀
func _on_node_added(node: Node) -> void:
	if node.is_in_group("enemies"):
		if node.has_signal("died"):
			node.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_killed += 1

func _on_inventory_changed() -> void:
	items_collected = GameManager.inventory.size()

## 游戏状态变化
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.GAME_OVER:
			show_screen(false)
		GameManager.GameState.VICTORY:
			show_screen(true)

## 显示界面
func show_screen(is_victory: bool) -> void:
	if is_victory:
		title_label.text = "成功撤离"
		title_label.modulate = Color(1.0, 0.85, 0.0)  # 金色
		return_btn.text = "返回洞府"
	else:
		title_label.text = "陨落"
		title_label.modulate = Color(0.8, 0.2, 0.2)  # 红色
		return_btn.text = "返回洞府"

	stats_label.text = "击杀敌人: %d\n收集物品: %d / %d" % [
		enemies_killed,
		items_collected,
		GameManager.max_inventory_size
	]

	visible = true

## 返回洞府按钮按下
func _on_return_pressed() -> void:
	# 重置统计数据
	enemies_killed = 0
	items_collected = 0

	# 恢复游戏状态
	GameManager.current_state = GameManager.GameState.PLAYING
	get_tree().paused = false

	# 返回洞府
	SceneTransition.go_to_haven()
