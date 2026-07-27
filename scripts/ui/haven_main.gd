## 洞府主界面（优化版）
## 显示所有建筑、战斗记录、层进度、探索统计
extends Control

# 颜色常量
const COLOR_TITLE: Color = Color(0.9, 0.8, 0.5)
const COLOR_RESOURCE: Color = Color(0.8, 0.8, 0.7)
const COLOR_BUILDING: Color = Color(0.7, 0.85, 1.0)
const COLOR_COMBAT: Color = Color(0.9, 0.5, 0.3)
const COLOR_SUCCESS: Color = Color(0.3, 0.9, 0.4)
const COLOR_WARNING: Color = Color(0.9, 0.7, 0.2)

# 建筑按钮引用（匹配场景节点路径）
@onready var explore_btn: Button = $ExploreButton
@onready var equipment_btn: Button = $EquipmentButton
@onready var alchemy_furnace_btn: Button = $BuildingGrid/AlchemyFurnace
@onready var forge_btn: Button = $BuildingGrid/Forge
@onready var training_room_btn: Button = $BuildingGrid/TrainingRoom
@onready var library_btn: Button = $BuildingGrid/Library
@onready var farm_btn: Button = $BuildingGrid/Farm
@onready var warehouse_btn: Button = $BuildingGrid/Warehouse
@onready var portal_btn: Button = $BuildingGrid/Portal
@onready var shop_btn: Button = $BuildingGrid/Shop
@onready var treasure_vault_btn: Button = $BuildingGrid/TreasureVault
@onready var inventory_btn: Button = $InventoryButton
@onready var back_btn: Button = $BackButton

# 资源显示（匹配场景节点路径）
@onready var spirit_stone_label: Label = $Resources/SpiritStone
@onready var herb_label: Label = $Resources/Herb
@onready var ore_label: Label = $Resources/Ore

# 标题
@onready var title: Label = $Title

# 新增 UI 元素（动态创建）
var combat_power_label: Label = null
var layer_progress_label: Label = null
var stats_panel: VBoxContainer = null
var last_run_label: Label = null
var tips_label: Label = null

func _ready() -> void:
	# 连接按钮信号
	explore_btn.pressed.connect(_on_explore_pressed)
	equipment_btn.pressed.connect(_on_equipment_pressed)
	alchemy_furnace_btn.pressed.connect(_on_building_pressed.bind("alchemy_furnace"))
	forge_btn.pressed.connect(_on_building_pressed.bind("forge"))
	training_room_btn.pressed.connect(_on_building_pressed.bind("training_room"))
	library_btn.pressed.connect(_on_building_pressed.bind("library"))
	farm_btn.pressed.connect(_on_building_pressed.bind("farm"))
	warehouse_btn.pressed.connect(_on_building_pressed.bind("warehouse"))
	portal_btn.pressed.connect(_on_building_pressed.bind("portal"))
	shop_btn.pressed.connect(_on_building_pressed.bind("shop"))
	treasure_vault_btn.pressed.connect(_on_building_pressed.bind("treasure_vault"))
	inventory_btn.pressed.connect(_on_warehouse_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	# 创建额外 UI 元素
	_create_enhanced_ui()

	# 更新所有显示
	_update_all()

## 创建增强 UI 元素
func _create_enhanced_ui() -> void:
	# 战斗力标签（添加到 Resources 下方）
	combat_power_label = Label.new()
	combat_power_label.name = "CombatPower"
	combat_power_label.add_theme_font_size_override("font_size", 14)
	combat_power_label.add_theme_color_override("font_color", COLOR_COMBAT)
	combat_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_power_label.position = Vector2(0, 105)
	combat_power_label.size = Vector2(720, 20)
	add_child(combat_power_label)

	# 层进度标签
	layer_progress_label = Label.new()
	layer_progress_label.name = "LayerProgress"
	layer_progress_label.add_theme_font_size_override("font_size", 12)
	layer_progress_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	layer_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer_progress_label.position = Vector2(0, 125)
	layer_progress_label.size = Vector2(720, 20)
	add_child(layer_progress_label)

	# 上次探索记录
	last_run_label = Label.new()
	last_run_label.name = "LastRun"
	last_run_label.add_theme_font_size_override("font_size", 12)
	last_run_label.add_theme_color_override("font_color", COLOR_RESOURCE)
	last_run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	last_run_label.position = Vector2(0, 900)
	last_run_label.size = Vector2(720, 20)
	add_child(last_run_label)

	# 提示标签
	tips_label = Label.new()
	tips_label.name = "Tips"
	tips_label.add_theme_font_size_override("font_size", 11)
	tips_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	tips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_label.position = Vector2(100, 950)
	tips_label.size = Vector2(520, 40)
	add_child(tips_label)

## 更新所有显示
func _update_all() -> void:
	_update_resources()
	_update_combat_power()
	_update_layer_progress()
	_update_last_run()
	_update_tips()
	_update_title()
	_style_buttons()

## 更新资源显示
func _update_resources() -> void:
	var stone = GameManager.storage.get("spirit_stone", 0)
	var herb = GameManager.storage.get("herb", 0)
	var ore = GameManager.storage.get("ore", 0)
	spirit_stone_label.text = "💎 灵石: %d" % stone
	herb_label.text = "🌿 灵草: %d" % herb
	ore_label.text = "⛏ 矿石: %d" % ore

	# 根据数量高亮资源
	spirit_stone_label.modulate = COLOR_RESOURCE if stone > 0 else Color(0.5, 0.5, 0.5)
	herb_label.modulate = COLOR_RESOURCE if herb > 0 else Color(0.5, 0.5, 0.5)
	ore_label.modulate = COLOR_RESOURCE if ore > 0 else Color(0.5, 0.5, 0.5)

## 更新标题
func _update_title() -> void:
	var cp = GameManager.get_combat_power()
	var recommended = GameManager.get_recommended_layer()
	title.text = "洞府  |  战斗力: %d  |  推荐: 第%d层" % [cp, recommended]

## 更新战斗力显示
func _update_combat_power() -> void:
	if not combat_power_label:
		return
	var cp = GameManager.get_combat_power()
	combat_power_label.text = "⚔ 战斗力: %d" % cp

## 更新层进度显示
func _update_layer_progress() -> void:
	if not layer_progress_label:
		return
	var current_layer = GameManager.current_layer
	var max_layer = 3

	var progress_text = "进度: "
	for i in range(1, max_layer + 1):
		if i < current_layer:
			progress_text += "✅ "
		elif i == current_layer:
			progress_text += "🔵 "
		else:
			progress_text += "⬜ "

	progress_text += "第%d/%d层" % [current_layer, max_layer]
	layer_progress_label.text = progress_text

## 更新上次探索记录
func _update_last_run() -> void:
	if not last_run_label:
		return
	# 显示当前层数信息
	var current_layer = GameManager.current_layer
	last_run_label.text = "当前进度: 第%d层" % current_layer

## 更新提示
func _update_tips() -> void:
	if not tips_label:
		return
	var tips = [
		"提示: 探索大地图时，注意撤离点的位置",
		"提示: 精英区域风险高，但奖励丰厚",
		"提示: 在洞府中强化装备可以提升战斗力",
		"提示: 炼丹可以获得临时增益效果",
		"提示: 宝库中的物品不会在陨落后丢失",
	]
	tips_label.text = tips[randi() % tips.size()]

## 统一按钮样式
func _style_buttons() -> void:
	explore_btn.add_theme_font_size_override("font_size", 20)
	equipment_btn.add_theme_font_size_override("font_size", 16)

	var building_btns = [
		alchemy_furnace_btn, forge_btn, training_room_btn,
		library_btn, farm_btn, warehouse_btn,
		portal_btn, shop_btn, treasure_vault_btn
	]
	for btn in building_btns:
		btn.add_theme_font_size_override("font_size", 14)

## 世界探索按钮
func _on_explore_pressed() -> void:
	print("[HavenMain] 进入世界探索")
	SceneTransition.go_to_explore()

## 装备按钮
func _on_equipment_pressed() -> void:
	print("[HavenMain] 打开装备界面")
	SceneTransition.change_scene("res://scenes/ui/equipment_panel.tscn")

## 仓库按钮
func _on_warehouse_pressed() -> void:
	print("[HavenMain] 打开仓库界面")
	SceneTransition.change_scene("res://scenes/ui/warehouse_panel.tscn")

## 返回门派选择
func _on_back_pressed() -> void:
	print("[HavenMain] 返回门派选择")
	SceneTransition.change_scene("res://scenes/ui/faction_select.tscn")

## 建筑按钮点击
func _on_building_pressed(building_id: String) -> void:
	print("[HavenMain] 点击建筑: %s" % building_id)

	var scene_path = ""
	match building_id:
		"alchemy_furnace":
			scene_path = "res://scenes/ui/alchemy_panel.tscn"
		"forge":
			scene_path = "res://scenes/ui/forge_panel.tscn"
		"training_room":
			scene_path = "res://scenes/ui/training_panel.tscn"
		"library":
			scene_path = "res://scenes/ui/library_panel.tscn"
		"farm":
			scene_path = "res://scenes/ui/farm_panel.tscn"
		"warehouse":
			scene_path = "res://scenes/ui/warehouse_panel.tscn"
		"portal":
			scene_path = "res://scenes/ui/portal_panel.tscn"
		"shop":
			scene_path = "res://scenes/ui/shop_panel.tscn"
		"treasure_vault":
			scene_path = "res://scenes/ui/vault_panel.tscn"

	if scene_path != "":
		SceneTransition.change_scene(scene_path)
