## 灵田界面（仙侠风格）
## 田地可视化、种子选择、生长进度、一键收获
extends Control

# 颜色常量
const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)
const COLOR_GROWING = Color(0.3, 0.7, 0.3)
const COLOR_READY = Color(0.9, 0.8, 0.2)
const COLOR_EMPTY = Color(0.3, 0.3, 0.3)
const COLOR_SOIL = Color(0.25, 0.18, 0.10)

# 节点引用（全部动态创建）
var level_label: Label
var slot_container: GridContainer
var seed_list: VBoxContainer
var status_label: Label

# 当前选中的种子
var selected_seed: String = ""

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_build_ui()
	_update_all()

func _process(_delta: float) -> void:
	# 每秒更新生长进度
	_update_slots()

# ============================================================
# UI 构建
# ============================================================

func _build_ui() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.10)
	add_child(bg)

	# 主滚动容器
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)

	_add_spacer(main_vbox, 15)

	# ── 标题栏 ──
	_build_header(main_vbox)

	# ── 田地可视化 ──
	_build_field_panel(main_vbox)

	# ── 种子选择 ──
	_build_seed_panel(main_vbox)

	# ── 状态信息 ──
	_build_status_panel(main_vbox)

	# ── 操作按钮 ──
	_build_actions(main_vbox)

	# ── 返回按钮 ──
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "🌱 灵 田"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())  # spacer

	level_label = Label.new()
	level_label.text = "等级: 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", TEXT_BODY)
	hbox.add_child(level_label)

# ============================================================
# 田地可视化
# ============================================================

func _build_field_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 280))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "田 地"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", TEXT_TITLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = PANEL_BORDER.darkened(0.5)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# 田地格子容器
	slot_container = GridContainer.new()
	slot_container.columns = 5
	slot_container.add_theme_constant_override("h_separation", 10)
	slot_container.add_theme_constant_override("v_separation", 10)
	# GridContainer doesn't have alignment in Godot 4
	vbox.add_child(slot_container)

func _update_slots() -> void:
	if not slot_container:
		return

	# 清空旧格子
	for child in slot_container.get_children():
		child.queue_free()

	var max_slots = FarmSystem.get_max_slots()

	for i in range(max_slots):
		var slot_data = FarmSystem.get_slot_status(i)
		var slot_ui = _create_slot_visual(i, slot_data)
		slot_container.add_child(slot_ui)

func _create_slot_visual(slot_index: int, data: Dictionary) -> Control:
	var status = data.get("status", "empty")

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 100)

	# 根据状态设置样式
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	match status:
		"empty":
			style.bg_color = COLOR_SOIL.darkened(0.3)
			style.border_color = COLOR_SOIL
			btn.text = "🟫\n空田地\n\n点击种植"
			btn.add_theme_color_override("font_color", TEXT_DIM)
			btn.pressed.connect(_on_slot_clicked.bind(slot_index))
		"growing":
			style.bg_color = COLOR_SOIL
			style.border_color = COLOR_GROWING.darkened(0.3)
			var progress = FarmSystem.get_growth_progress(slot_index)
			var percent = int(progress * 100)
			var crop_name = data.get("output_name", "?")
			btn.text = "🌱 %s\n生长中 %d%%\n%s" % [crop_name, percent, _get_progress_bar(progress)]
			btn.add_theme_color_override("font_color", COLOR_GROWING)
		"ready":
			style.bg_color = COLOR_SOIL.lightened(0.1)
			style.border_color = COLOR_READY
			var crop_name = data.get("output_name", "?")
			var amount = data.get("output_amount", 1)
			btn.text = "✨ %s\n可收获!\n数量: %d" % [crop_name, amount]
			btn.add_theme_color_override("font_color", COLOR_READY)
			btn.pressed.connect(_on_harvest_slot.bind(slot_index))

	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = hover.bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = pressed.bg_color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 11)
	return btn

func _get_progress_bar(progress: float) -> String:
	var filled = int(progress * 10)
	var empty = 10 - filled
	return "[" + "█".repeat(filled) + "░".repeat(empty) + "]"

# ============================================================
# 种子选择面板
# ============================================================

func _build_seed_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 200))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "种 子"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", TEXT_TITLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = PANEL_BORDER.darkened(0.5)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# 种子列表
	seed_list = VBoxContainer.new()
	seed_list.add_theme_constant_override("separation", 4)
	vbox.add_child(seed_list)

	_refresh_seed_list()

func _refresh_seed_list() -> void:
	if not seed_list:
		return

	for child in seed_list.get_children():
		child.queue_free()

	var seeds = [
		{"id": "herb_seed", "icon": "🌿", "name": "普通灵草种子", "output": "灵草×3", "time": "30分钟"},
		{"id": "quality_herb_seed", "icon": "🌿", "name": "优质灵草种子", "output": "灵草×8", "time": "2小时"},
		{"id": "rare_herb_seed", "icon": "🌿", "name": "稀有灵草种子", "output": "灵草×20", "time": "6小时"},
		{"id": "ore_seed", "icon": "⛏", "name": "普通矿石种子", "output": "矿石×3", "time": "30分钟"},
		{"id": "quality_ore_seed", "icon": "⛏", "name": "优质矿石种子", "output": "矿石×8", "time": "2小时"},
		{"id": "rare_ore_seed", "icon": "⛏", "name": "稀有矿石种子", "output": "矿石×20", "time": "6小时"},
	]

	var has_any_seed = false

	for seed in seeds:
		var amount = GameManager.storage.get(seed.id, 0)
		if amount <= 0:
			continue
		has_any_seed = true

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(640, 35)
		btn.text = "%s %s  ×%d    产出: %s    生长: %s" % [
			seed.icon, seed.name, amount, seed.output, seed.time
		]
		btn.add_theme_font_size_override("font_size", 12)

		var style = StyleBoxFlat.new()
		style.bg_color = BTN_NORMAL if selected_seed != seed.id else Color(0.2, 0.25, 0.15)
		style.border_color = PANEL_BORDER.darkened(0.3) if selected_seed != seed.id else COLOR_GROWING
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)

		var hover = StyleBoxFlat.new()
		hover.bg_color = BTN_HOVER
		hover.border_color = PANEL_BORDER
		hover.set_border_width_all(1)
		hover.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover)

		btn.add_theme_color_override("font_color", TEXT_BODY)
		btn.add_theme_color_override("font_hover_color", TEXT_TITLE)
		btn.pressed.connect(_on_seed_selected.bind(seed.id))
		seed_list.add_child(btn)

	if not has_any_seed:
		var empty_label = Label.new()
		empty_label.text = "暂无种子  —  击败敌人或在商店购买可获得种子"
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", TEXT_DIM)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seed_list.add_child(empty_label)

# ============================================================
# 状态信息
# ============================================================

func _build_status_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 40))

	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", TEXT_BODY)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(status_label)

# ============================================================
# 操作按钮
# ============================================================

func _build_actions(parent: Control) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	# 一键收获按钮
	var harvest_btn = Button.new()
	harvest_btn.custom_minimum_size = Vector2(200, 50)
	harvest_btn.text = "🌾 一键收获"
	harvest_btn.add_theme_font_size_override("font_size", 16)
	_style_action_button(harvest_btn, COLOR_READY.darkened(0.3))
	harvest_btn.pressed.connect(_on_harvest_all_pressed)
	hbox.add_child(harvest_btn)

func _style_action_button(btn: Button, accent_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = accent_color.darkened(0.5)
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = accent_color.darkened(0.3)
	hover.border_color = accent_color.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", accent_color.lightened(0.3))
	btn.add_theme_color_override("font_hover_color", accent_color.lightened(0.6))

# ============================================================
# 底部
# ============================================================

func _build_footer(parent: Control) -> void:
	_add_spacer(parent, 10)

	var container = CenterContainer.new()
	parent.add_child(container)

	var back_btn = Button.new()
	back_btn.text = "返回洞府"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", TEXT_DIM)
	back_btn.add_theme_color_override("font_hover_color", TEXT_BODY)
	back_btn.pressed.connect(_on_back_pressed)
	container.add_child(back_btn)

	_add_spacer(parent, 20)

# ============================================================
# 工具函数
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

func _add_spacer(parent: Control, height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)

# ============================================================
# 数据更新
# ============================================================

func _update_all() -> void:
	var level = BuildingSystem.get_building_level("farm")
	level_label.text = "等级: %d  (田地: %d块)" % [level, FarmSystem.get_max_slots()]
	_update_slots()
	_refresh_seed_list()
	_update_status()

func _update_status() -> void:
	if not status_label:
		return

	var growing = 0
	var ready = 0
	var max_slots = FarmSystem.get_max_slots()
	for i in range(max_slots):
		var data = FarmSystem.get_slot_status(i)
		match data.get("status", "empty"):
			"growing":
				growing += 1
			"ready":
				ready += 1

	if ready > 0:
		status_label.text = "✨ %d块田地可收获！" % ready
		status_label.add_theme_color_override("font_color", COLOR_READY)
	elif growing > 0:
		status_label.text = "🌱 %d块田地生长中..." % growing
		status_label.add_theme_color_override("font_color", COLOR_GROWING)
	else:
		status_label.text = "田地空闲，选择种子种植吧"
		status_label.add_theme_color_override("font_color", TEXT_DIM)

# ============================================================
# 回调
# ============================================================

func _on_seed_selected(seed_id: String) -> void:
	selected_seed = seed_id
	_refresh_seed_list()

func _on_slot_clicked(slot_index: int) -> void:
	if selected_seed == "":
		_set_status("请先选择种子", COLOR_READY)
		return

	if FarmSystem.plant_crop(selected_seed):
		var crop_data = FarmSystem.get_crop_data(selected_seed)
		_set_status("种植成功: %s" % crop_data.get("name", ""), COLOR_GROWING)
		selected_seed = ""
		_update_all()
	else:
		_set_status("种植失败（无空田地或种子不足）", Color(0.9, 0.3, 0.3))

func _on_harvest_slot(slot_index: int) -> void:
	var result = FarmSystem.harvest_crop(slot_index)
	if not result.is_empty():
		_set_status("收获: %s ×%d" % [result.get("output_name", ""), result.get("amount", 0)], COLOR_READY)
		_update_all()

func _on_harvest_all_pressed() -> void:
	var harvested = FarmSystem.harvest_all()
	if harvested.is_empty():
		_set_status("没有可收获的作物", TEXT_DIM)
	else:
		var total = 0
		for item in harvested:
			total += item.get("amount", 0)
		_set_status("收获 %d 个作物，共 %d 资源！" % [harvested.size(), total], COLOR_READY)
	_update_all()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")

func _set_status(text: String, color: Color) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
