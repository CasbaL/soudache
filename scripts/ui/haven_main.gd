## 洞府主界面（仙侠水墨风）
## 全代码构建UI，深蓝金色配色，圆角面板，秘境选择
extends Control

# ============================================================
# 颜色常量（仙侠风格）
# ============================================================

const BG_TOP = Color(0.04, 0.05, 0.10)
const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)
const BTN_EXPLORE = Color(0.77, 0.64, 0.35)

# 秘境主题色
const AREA_COLORS = {
	1: Color(0.2, 0.6, 0.3),   # 幽竹林 - 绿
	2: Color(0.8, 0.35, 0.15), # 火焰山 - 红橙
	3: Color(0.5, 0.45, 0.7),  # 天机阁 - 紫
}

# ============================================================
# 节点引用
# ============================================================

var stone_label: Label
var herb_label: Label
var ore_label: Label
var combat_power_label: Label
var building_btns: Dictionary = {}
var tips_label: Label

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_build_ui()
	_update_all()

# ============================================================
# UI 构建
# ============================================================

func _build_ui() -> void:
	_draw_background()

	var main_scroll = ScrollContainer.new()
	main_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.follow_focus = true
	add_child(main_scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 12)
	main_scroll.add_child(main_vbox)

	_add_spacer(main_vbox, 20)
	_build_resource_bar(main_vbox)
	_build_character_panel(main_vbox)
	_build_area_selection(main_vbox)
	_build_building_groups(main_vbox)
	_build_equipment_button(main_vbox)
	_build_footer(main_vbox)

func _draw_background() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = BG_TOP
	add_child(bg)

# ============================================================
# 资源栏
# ============================================================

func _build_resource_bar(parent: Control) -> void:
	var bar = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	bar.add_child(hbox)

	stone_label = _create_label("💎 0", 16, TEXT_BODY)
	stone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(stone_label)
	_add_vseparator(hbox)

	herb_label = _create_label("🌿 0", 16, TEXT_BODY)
	herb_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	herb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(herb_label)
	_add_vseparator(hbox)

	ore_label = _create_label("⛏ 0", 16, TEXT_BODY)
	ore_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(ore_label)

# ============================================================
# 角色信息面板
# ============================================================

func _build_character_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	combat_power_label = _create_label("⚔ 战斗力: 0", 18, TEXT_TITLE)
	combat_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(combat_power_label)

# ============================================================
# 秘境选择（替代旧的层系统）
# ============================================================

func _build_area_selection(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 260))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = _create_label("选 择 秘 境", 18, TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", _create_separator_style())
	vbox.add_child(sep)

	# 三个秘境卡片
	var areas = [
		{"layer": 1, "name": "幽竹林", "icon": "🎋", "desc": "竹妖横行，灵草丰茂", "diff": "★☆☆", "boss": "竹妖王"},
		{"layer": 2, "name": "火焰山", "icon": "🔥", "desc": "熔岩遍地，火灵肆虐", "diff": "★★☆", "boss": "火魔"},
		{"layer": 3, "name": "天机阁", "icon": "⚙", "desc": "机关重重，齿轮转动", "diff": "★★★", "boss": "天机老人"},
	]

	for area in areas:
		_build_area_card(vbox, area)

func _build_area_card(parent: Control, area: Dictionary) -> void:
	var layer = area.layer
	var color = AREA_COLORS.get(layer, TEXT_BODY)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(640, 55)

	# 卡片内容
	btn.text = "%s  %s    %s    Boss: %s    难度: %s" % [
		area.icon, area.name, area.desc, area.boss, area.diff
	]
	btn.add_theme_font_size_override("font_size", 14)

	# 样式
	var style = StyleBoxFlat.new()
	style.bg_color = BTN_NORMAL
	style.border_color = color.darkened(0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = color.darkened(0.6)
	hover.border_color = color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	hover.content_margin_left = 12
	hover.content_margin_right = 12
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = color.darkened(0.7)
	pressed.border_color = color.lightened(0.2)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(6)
	pressed.content_margin_left = 12
	pressed.content_margin_right = 12
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", color.lightened(0.3))
	btn.add_theme_color_override("font_hover_color", color.lightened(0.6))
	btn.pressed.connect(_on_area_selected.bind(layer))
	parent.add_child(btn)

# ============================================================
# 建筑分组
# ============================================================

func _build_building_groups(parent: Control) -> void:
	_build_group(parent, "修 炼", [
		{"id": "training_room", "icon": "🧘", "name": "修炼室"},
		{"id": "library", "icon": "📜", "name": "藏经阁"},
		{"id": "farm", "icon": "🌱", "name": "灵田"},
	])
	_build_group(parent, "炼 制", [
		{"id": "alchemy_furnace", "icon": "⚗", "name": "炼丹炉"},
		{"id": "forge", "icon": "🔨", "name": "炼器台"},
		{"id": "shop", "icon": "🏪", "name": "商店"},
	])
	_build_group(parent, "存 储", [
		{"id": "warehouse", "icon": "📦", "name": "仓库"},
		{"id": "treasure_vault", "icon": "💎", "name": "宝库"},
		{"id": "portal", "icon": "🌀", "name": "传送阵"},
	])

func _build_group(parent: Control, group_name: String, items: Array) -> void:
	var panel = _create_panel(parent, Vector2(680, 120))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var group_label = _create_label(group_name, 15, TEXT_TITLE)
	group_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(group_label)

	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", _create_separator_style())
	vbox.add_child(sep)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	for item in items:
		var btn = _create_building_button(item.icon, item.name, item.id)
		hbox.add_child(btn)
		building_btns[item.id] = btn

func _create_building_button(icon: String, btn_name: String, building_id: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(180, 60)
	btn.text = "%s\n%s" % [icon, btn_name]
	btn.add_theme_font_size_override("font_size", 14)

	var style = StyleBoxFlat.new()
	style.bg_color = BTN_NORMAL
	style.border_color = PANEL_BORDER.darkened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = BTN_HOVER
	hover.border_color = PANEL_BORDER
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = BTN_NORMAL.darkened(0.2)
	pressed.border_color = PANEL_BORDER
	pressed.set_border_width_all(1)
	pressed.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", TEXT_BODY)
	btn.add_theme_color_override("font_hover_color", TEXT_TITLE)
	btn.pressed.connect(_on_building_pressed.bind(building_id))
	return btn

# ============================================================
# 装备按钮
# ============================================================

func _build_equipment_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(300, 50)
	btn.text = "🛡  装  备"
	btn.add_theme_font_size_override("font_size", 18)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.22, 0.90)
	style.border_color = PANEL_BORDER.darkened(0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.18, 0.22, 0.30, 0.95)
	hover.border_color = PANEL_BORDER
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", TEXT_BODY)
	btn.add_theme_color_override("font_hover_color", TEXT_TITLE)
	btn.pressed.connect(_on_equipment_pressed)
	container.add_child(btn)

# ============================================================
# 底部
# ============================================================

func _build_footer(parent: Control) -> void:
	_add_spacer(parent, 10)

	tips_label = _create_label("", 12, TEXT_DIM)
	tips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(tips_label)

	_add_spacer(parent, 10)

	var back_container = CenterContainer.new()
	parent.add_child(back_container)

	var back_btn = Button.new()
	back_btn.text = "返回门派选择"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", TEXT_DIM)
	back_btn.add_theme_color_override("font_hover_color", TEXT_BODY)
	back_btn.pressed.connect(_on_back_pressed)
	back_container.add_child(back_btn)

	_add_spacer(parent, 20)

# ============================================================
# UI 工具函数
# ============================================================

func _create_panel(parent: Control, min_size: Vector2) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = min_size

	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER.darkened(0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	parent.add_child(panel)
	return panel

func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _create_separator_style() -> StyleBoxLine:
	var style = StyleBoxLine.new()
	style.color = PANEL_BORDER.darkened(0.5)
	style.thickness = 1
	return style

func _add_spacer(parent: Control, height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)

func _add_vseparator(parent: Control) -> void:
	var sep = VSeparator.new()
	sep.add_theme_stylebox_override("separator", _create_separator_style())
	parent.add_child(sep)

# ============================================================
# 数据更新
# ============================================================

func _update_all() -> void:
	_update_resources()
	_update_combat_power()
	_update_tips()

func _update_resources() -> void:
	var stone = GameManager.storage.get("spirit_stone", 0)
	var herb = GameManager.storage.get("herb", 0)
	var ore = GameManager.storage.get("ore", 0)
	stone_label.text = "💎 %d" % stone
	herb_label.text = "🌿 %d" % herb
	ore_label.text = "⛏ %d" % ore

func _update_combat_power() -> void:
	var cp = GameManager.get_combat_power()
	combat_power_label.text = "⚔ 战斗力: %d" % cp

func _update_tips() -> void:
	var tips = [
		"💡 不同秘境有不同敌人和Boss，选择适合自己的",
		"💡 精英区域风险高，但奖励丰厚",
		"💡 在洞府中强化装备可以提升战斗力",
		"💡 炼丹可以获得临时增益效果",
		"💡 宝库中的物品不会在陨落后丢失",
	]
	tips_label.text = tips[randi() % tips.size()]

# ============================================================
# 按钮回调
# ============================================================

## 选择秘境进入探索
func _on_area_selected(layer: int) -> void:
	GameManager.current_layer = layer
	SceneTransition.go_to_explore()

func _on_equipment_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/equipment_panel.tscn")

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/faction_select.tscn")

func _on_building_pressed(building_id: String) -> void:
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
