## 游戏结束/胜利界面（优化版）
## 显示结果、击杀数、收集资源、层进度、奖励预览
extends CanvasLayer

# 颜色常量
const COLOR_VICTORY: Color = Color(1.0, 0.85, 0.0)
const COLOR_DEFEAT: Color = Color(0.8, 0.2, 0.2)
const COLOR_STAT: Color = Color(0.7, 0.85, 1.0)
const COLOR_REWARD: Color = Color(0.3, 0.9, 0.5)
const COLOR_WARNING: Color = Color(0.9, 0.7, 0.2)

# 子节点引用
@onready var overlay: ColorRect = $Overlay
@onready var panel: VBoxContainer = $Overlay/Panel
@onready var title_label: Label = $Overlay/Panel/Title
@onready var stats_label: Label = $Overlay/Panel/Stats
@onready var return_btn: Button = $Overlay/Panel/ReturnButton

# 新增 UI 元素
var layer_label: Label = null
var time_label: Label = null
var kill_label: Label = null
var collect_label: Label = null
var resource_label: Label = null
var reward_label: Label = null
var tip_label: Label = null

# 统计数据
var enemies_killed: int = 0
var items_collected: int = 0
var resources_gained: Dictionary = {}
var start_time: float = 0.0
var current_layer: int = 1

func _ready() -> void:
	# 默认隐藏
	visible = false

	# 设置遮罩
	overlay.color = Color(0, 0, 0, 0.85)
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

	# 创建增强 UI
	_create_enhanced_ui()

	# 连接信号
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)

	# 连接敌人击杀信号
	var tree = get_tree()
	if tree:
		tree.node_added.connect(_on_node_added)

## 创建增强 UI
func _create_enhanced_ui() -> void:
	# 层显示
	layer_label = Label.new()
	layer_label.name = "LayerLabel"
	layer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer_label.add_theme_font_size_override("font_size", 18)
	layer_label.add_theme_color_override("font_color", COLOR_STAT)
	panel.add_child(layer_label)

	# 时间显示
	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", COLOR_STAT)
	panel.add_child(time_label)

	# 击杀显示
	kill_label = Label.new()
	kill_label.name = "KillLabel"
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kill_label.add_theme_font_size_override("font_size", 16)
	kill_label.add_theme_color_override("font_color", COLOR_REWARD)
	panel.add_child(kill_label)

	# 收集显示
	collect_label = Label.new()
	collect_label.name = "CollectLabel"
	collect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collect_label.add_theme_font_size_override("font_size", 16)
	collect_label.add_theme_color_override("font_color", COLOR_REWARD)
	panel.add_child(collect_label)

	# 资源显示
	resource_label = Label.new()
	resource_label.name = "ResourceLabel"
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resource_label.add_theme_font_size_override("font_size", 14)
	resource_label.add_theme_color_override("font_color", COLOR_STAT)
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(resource_label)

	# 奖励显示
	reward_label = Label.new()
	reward_label.name = "RewardLabel"
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.add_theme_color_override("font_color", COLOR_REWARD)
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(reward_label)

	# 提示
	tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 12)
	tip_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(tip_label)

## 统计敌人击杀
func _on_node_added(node: Node) -> void:
	if node.is_in_group("enemies"):
		if node.has_signal("died"):
			node.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_killed += 1

func _on_inventory_changed() -> void:
	items_collected = GameManager.inventory.size()
	# 统计资源
	for item in GameManager.inventory:
		var id = item.get("id", "")
		var amount = item.get("amount", 1)
		resources_gained[id] = resources_gained.get(id, 0) + amount

## 游戏状态变化
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.GAME_OVER:
			show_screen(false)
		GameManager.GameState.VICTORY:
			show_screen(true)

## 显示界面
func show_screen(is_victory: bool) -> void:
	# 计算时间
	var elapsed_time = Time.get_ticks_msec() / 1000.0 - start_time
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60

	# 获取当前层
	current_layer = GameManager.current_layer

	if is_victory:
		title_label.text = "成功撤离"
		title_label.modulate = COLOR_VICTORY
		return_btn.text = "返回洞府"
	else:
		title_label.text = "陨落"
		title_label.modulate = COLOR_DEFEAT
		return_btn.text = "返回洞府"

	# 层显示
	if layer_label:
		layer_label.text = "第 %d 层" % current_layer

	# 时间显示
	if time_label:
		time_label.text = "探索时间: %d分%d秒" % [minutes, seconds]

	# 击杀显示
	if kill_label:
		kill_label.text = "击杀敌人: %d" % enemies_killed

	# 收集显示
	if collect_label:
		collect_label.text = "收集物品: %d / %d" % [items_collected, GameManager.max_inventory_size]

	# 资源显示
	if resource_label:
		var res_text = "获得资源:\n"
		for res_id in resources_gained:
			var amount = resources_gained[res_id]
			var name = _get_resource_name(res_id)
			res_text += "• %s: %d\n" % [name, amount]
		resource_label.text = res_text.strip_edges() if resources_gained.size() > 0 else "无资源获得"

	# 奖励显示
	if reward_label:
		if is_victory:
			var rewards = _calculate_victory_rewards()
			var reward_text = "撤离奖励:\n"
			for reward in rewards:
				reward_text += "• %s: %d\n" % [reward.get("name", ""), reward.get("amount", 0)]
			reward_label.text = reward_text.strip_edges()
		else:
			reward_label.text = "陨落后丢失背包中非宝库物品"

	# 提示
	if tip_label:
		tip_label.text = _get_tip(is_victory)

	visible = true

	# 动画效果
	_animate_entrance()

## 计算撤离奖励
func _calculate_victory_rewards() -> Array:
	var rewards = []

	# 根据层数给予不同奖励
	match current_layer:
		1:
			rewards.append({"id": "spirit_stone", "name": "灵石", "amount": 100})
			rewards.append({"id": "herb", "name": "灵草", "amount": 20})
		2:
			rewards.append({"id": "spirit_stone", "name": "灵石", "amount": 300})
			rewards.append({"id": "herb", "name": "灵草", "amount": 50})
			rewards.append({"id": "ore", "name": "矿石", "amount": 30})
		3:
			rewards.append({"id": "spirit_stone", "name": "灵石", "amount": 500})
			rewards.append({"id": "herb", "name": "灵草", "amount": 80})
			rewards.append({"id": "ore", "name": "矿石", "amount": 50})

	# 击杀奖励
	if enemies_killed > 10:
		rewards.append({"id": "spirit_stone", "name": "灵石(击杀奖励)", "amount": enemies_killed * 5})

	return rewards

## 获取资源名称
func _get_resource_name(resource_id: String) -> String:
	match resource_id:
		"spirit_stone": return "灵石"
		"herb": return "灵草"
		"ore": return "矿石"
		"chest": return "宝箱"
		"fire_crystal": return "火晶石"
		"gear": return "齿轮"
		"technique_fragment": return "功法残页"
		"equipment": return "装备"
	return "未知"

## 获取提示
func _get_tip(is_victory: bool) -> String:
	if is_victory:
		var tips = [
			"提示: 返回洞府后可以强化装备提升战斗力",
			"提示: 收集的资源可以用来建造和炼丹",
			"提示: 尝试探索更高层获取更好奖励",
		]
		return tips[randi() % tips.size()]
	else:
		var tips = [
			"提示: 宝库中的物品不会在陨落后丢失",
			"提示: 提升境界可以增加基础属性",
			"提示: 在洞府中修炼可以提升技能等级",
		]
		return tips[randi() % tips.size()]

## 入场动画
func _animate_entrance() -> void:
	# 面板从小变大
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.3)

## 返回洞府按钮按下
func _on_return_pressed() -> void:
	# 保存探索记录
	_save_run_stats()

	# 重置统计数据
	enemies_killed = 0
	items_collected = 0
	resources_gained.clear()

	# 恢复游戏状态
	GameManager.current_state = GameManager.GameState.PLAYING
	get_tree().paused = false

	# 返回洞府
	SceneTransition.go_to_haven()

## 保存探索记录（暂不实现）
func _save_run_stats() -> void:
	pass
