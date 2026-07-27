## 仓库界面（仙侠风格）
## 资源存储显示、容量管理
extends Control

const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const COLOR_STORAGE = Color(0.5, 0.7, 0.9)  # 仓库蓝色

var level_label: Label
var resource_container: VBoxContainer

func _ready() -> void:
	_build_ui()
	_update_all()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.10)
	add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)

	_add_spacer(main_vbox, 15)
	_build_header(main_vbox)
	_build_resource_panel(main_vbox)
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "📦 仓 库"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())

	level_label = Label.new()
	level_label.text = "等级: 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", TEXT_BODY)
	hbox.add_child(level_label)

func _build_resource_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 400))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "资 源 存 储"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = PANEL_BORDER.darkened(0.5)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	resource_container = VBoxContainer.new()
	resource_container.add_theme_constant_override("separation", 6)
	vbox.add_child(resource_container)

	_refresh_resources()

func _refresh_resources() -> void:
	if not resource_container:
		return

	for child in resource_container.get_children():
		child.queue_free()

	var capacity = GameManager.get_storage_capacity()
	var resources = [
		{"id": "spirit_stone", "icon": "💎", "name": "灵石"},
		{"id": "herb", "icon": "🌿", "name": "灵草"},
		{"id": "ore", "icon": "⛏", "name": "矿石"},
		{"id": "fire_crystal", "icon": "🔥", "name": "火晶石"},
		{"id": "gear", "icon": "⚙", "name": "齿轮"},
		{"id": "technique_fragment", "icon": "📜", "name": "功法残页"},
	]

	for res in resources:
		var have = GameManager.storage.get(res.id, 0)
		var max = capacity.get(res.id, 0)
		if max == 0 and have == 0:
			continue

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		resource_container.add_child(hbox)

		# 图标+名称
		var name_label = Label.new()
		name_label.text = "%s %s" % [res.icon, res.name]
		name_label.custom_minimum_size = Vector2(150, 0)
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", TEXT_BODY)
		hbox.add_child(name_label)

		# 数量
		var amount_label = Label.new()
		amount_label.text = "%d" % have
		amount_label.custom_minimum_size = Vector2(100, 0)
		amount_label.add_theme_font_size_override("font_size", 14)
		amount_label.add_theme_color_override("font_color", COLOR_STORAGE if have > 0 else TEXT_DIM)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(amount_label)

		# 容量
		if max > 0:
			var cap_label = Label.new()
			cap_label.text = "/ %d" % max
			cap_label.custom_minimum_size = Vector2(100, 0)
			cap_label.add_theme_font_size_override("font_size", 14)
			cap_label.add_theme_color_override("font_color", TEXT_DIM)
			cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hbox.add_child(cap_label)

			# 容量条
			var bar = ProgressBar.new()
			bar.custom_minimum_size = Vector2(150, 16)
			bar.max_value = max
			bar.value = have
			bar.show_percentage = false

			var bar_bg = StyleBoxFlat.new()
			bar_bg.bg_color = Color(0.15, 0.15, 0.2)
			bar_bg.set_corner_radius_all(3)
			bar.add_theme_stylebox_override("background", bar_bg)

			var bar_fill = StyleBoxFlat.new()
			var fill_ratio = float(have) / float(max) if max > 0 else 0.0
			if fill_ratio > 0.9:
				bar_fill.bg_color = Color(0.9, 0.3, 0.3)
			elif fill_ratio > 0.7:
				bar_fill.bg_color = Color(0.9, 0.7, 0.2)
			else:
				bar_fill.bg_color = COLOR_STORAGE
			bar_fill.set_corner_radius_all(3)
			bar.add_theme_stylebox_override("fill", bar_fill)

			hbox.add_child(bar)

func _build_footer(parent: Control) -> void:
	_add_spacer(parent, 20)

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

func _update_all() -> void:
	var level = BuildingSystem.get_building_level("warehouse")
	level_label.text = "等级: %d" % level
	_refresh_resources()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
