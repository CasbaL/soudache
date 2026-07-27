## 建筑面板 UI
## 3x3 网格显示 9 栋建筑卡片，每张卡片显示名称/等级/升级按钮/消耗
extends Control

@onready var grid: GridContainer = $VBox/Grid
@onready var title_label: Label = $VBox/Title
@onready var detail_panel: VBoxContainer = $DetailPanel
@onready var detail_name: Label = $DetailPanel/Name
@onready var detail_desc: Label = $DetailPanel/Desc
@onready var detail_stats: Label = $DetailPanel/Stats
@onready var detail_cost: Label = $DetailPanel/Cost
@onready var upgrade_btn: Button = $DetailPanel/UpgradeBtn
@onready var close_btn: Button = $DetailPanel/CloseBtn

var selected_building: String = ""
var building_buttons: Dictionary = {}

func _ready() -> void:
	_create_building_grid()
	detail_panel.visible = false
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	BuildingSystem.building_upgraded.connect(_on_building_upgraded)
	BuildingSystem.resources_changed.connect(_refresh_grid)

func _create_building_grid() -> void:
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	for building_id in BuildingSystem.ALL_BUILDINGS:
		var card := _create_building_card(building_id)
		grid.add_child(card)
		building_buttons[building_id] = card

func _create_building_card(building_id: String) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 120)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var name_label = Label.new()
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	var level_label = Label.new()
	level_label.name = "Level"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(level_label)

	var bonus_label = Label.new()
	bonus_label.name = "Bonus"
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(bonus_label)

	var btn = Button.new()
	btn.name = "UpgradeBtn"
	btn.text = "详情"
	btn.pressed.connect(_on_card_clicked.bind(building_id))
	vbox.add_child(btn)

	return card

func _refresh_grid() -> void:
	for building_id in BuildingSystem.ALL_BUILDINGS:
		var card: PanelContainer = building_buttons.get(building_id)
		if card == null:
			continue
		var level = BuildingSystem.get_building_level(building_id)
		var bonus = BuildingSystem.get_building_bonus(building_id)
		var meta: Dictionary = BuildingData.META.get(building_id, {})
		var name_lbl: Label = card.get_node("VBox/Name")
		var level_lbl: Label = card.get_node("VBox/Level")
		var bonus_lbl: Label = card.get_node("VBox/Bonus")
		name_lbl.text = meta.get("name", building_id)
		level_lbl.text = "Lv.%d" % level
		if level >= BuildingSystem.MAX_LEVEL:
			bonus_lbl.text = "MAX"
		else:
			bonus_lbl.text = "+%.0f%% 效率" % (bonus * 100)

func _on_card_clicked(building_id: String) -> void:
	selected_building = building_id
	_show_detail(building_id)

func _show_detail(building_id: String) -> void:
	detail_panel.visible = true
	var meta: Dictionary = BuildingData.META.get(building_id, {})
	var level = BuildingSystem.get_building_level(building_id)
	var bonus = BuildingSystem.get_building_bonus(building_id)
	detail_name.text = "%s Lv.%d" % [meta.get("name", building_id), level]
	detail_desc.text = meta.get("description", "")
	detail_stats.text = "效率加成: +%.0f%%" % (bonus * 100)
	# 升级消耗
	if BuildingSystem.is_max_level(building_id):
		detail_cost.text = "已满级"
		upgrade_btn.disabled = true
		upgrade_btn.text = "已满级"
	else:
		var cost: Dictionary = BuildingSystem.get_upgrade_cost(building_id)
		var cost_parts: Array = []
		for res_id in cost:
			var owned: int = GameManager.storage.get(res_id, 0)
			var enough = owned >= cost[res_id]
			cost_parts.append("%s: %d/%d%s" % [_res_name(res_id), owned, cost[res_id], " ✓" if enough else " ✗"])
		detail_cost.text = "\n".join(cost_parts)
		upgrade_btn.disabled = not BuildingSystem.can_upgrade(building_id)
		upgrade_btn.text = "升级" if not upgrade_btn.disabled else "资源不足"

func _on_upgrade_pressed() -> void:
	if selected_building.is_empty():
		return
	BuildingSystem.upgrade_building(selected_building)
	_show_detail(selected_building)
	_refresh_grid()

func _on_close_pressed() -> void:
	detail_panel.visible = false
	selected_building = ""

func _on_building_upgraded(_building_id: String, _new_level: int) -> void:
	_refresh_grid()

static func _res_name(res_id: String) -> String:
	match res_id:
		"spirit_stone": return "灵石"
		"herb": return "灵草"
		"ore": return "矿石"
		"artifact_spirit": return "器灵"
		_: return res_id
