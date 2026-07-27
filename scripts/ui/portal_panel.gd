## 传送阵界面（仙侠风格）
## 传送点列表、传送操作
extends Control

const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)
const COLOR_PORTAL = Color(0.5, 0.4, 0.9)   # 传送紫色

var level_label: Label
var point_container: VBoxContainer
var teleport_btn: Button
var status_label: Label

var selected_point: String = ""

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
	_build_point_list(main_vbox)
	_build_teleport_button(main_vbox)
	_build_status(main_vbox)
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "🌀 传 送 阵"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())

	level_label = Label.new()
	level_label.text = "等级: 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", TEXT_BODY)
	hbox.add_child(level_label)

func _build_point_list(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 350))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "传 送 点"
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

	point_container = VBoxContainer.new()
	point_container.add_theme_constant_override("separation", 4)
	vbox.add_child(point_container)

	_refresh_points()

func _refresh_points() -> void:
	if not point_container:
		return

	for child in point_container.get_children():
		child.queue_free()

	var points = PortalSystem.get_all_points()
	if points.is_empty():
		var empty = Label.new()
		empty.text = "暂无传送点"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		point_container.add_child(empty)
		return

	for point_id in points:
		var point = PortalSystem.get_point_data(point_id)
		var is_unlocked = PortalSystem.is_unlocked(point_id)
		var can_teleport = PortalSystem.can_teleport(point_id)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(640, 40)

		var name = point.get("name", point_id)
		var desc = point.get("description", "")
		var status = ""
		if is_unlocked:
			if can_teleport:
				status = " ✅可传送"
			else:
				status = " 🔓已解锁"
		else:
			status = " 🔒未解锁"

		btn.text = "🌀 %s%s    %s" % [name, status, desc]
		btn.add_theme_font_size_override("font_size", 13)

		var bg_color = BTN_NORMAL
		var border_color = PANEL_BORDER.darkened(0.3)
		if not is_unlocked:
			bg_color = Color(0.08, 0.08, 0.1)
			border_color = Color(0.2, 0.2, 0.2)
		elif selected_point == point_id:
			bg_color = Color(0.15, 0.12, 0.25)
			border_color = COLOR_PORTAL

		var style = StyleBoxFlat.new()
		style.bg_color = bg_color
		style.border_color = border_color
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)

		var hover = StyleBoxFlat.new()
		hover.bg_color = BTN_HOVER
		hover.border_color = PANEL_BORDER
		hover.set_border_width_all(1)
		hover.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover)

		btn.add_theme_color_override("font_color", TEXT_BODY if is_unlocked else TEXT_DIM)
		btn.add_theme_color_override("font_hover_color", TEXT_TITLE)
		btn.disabled = not is_unlocked
		btn.pressed.connect(_on_point_selected.bind(point_id))
		point_container.add_child(btn)

func _build_teleport_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	teleport_btn = Button.new()
	teleport_btn.custom_minimum_size = Vector2(300, 50)
	teleport_btn.text = "🌀 传 送"
	teleport_btn.add_theme_font_size_override("font_size", 18)

	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_PORTAL.darkened(0.6)
	style.border_color = COLOR_PORTAL
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	teleport_btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = COLOR_PORTAL.darkened(0.4)
	hover.border_color = COLOR_PORTAL.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	teleport_btn.add_theme_stylebox_override("hover", hover)

	teleport_btn.add_theme_color_override("font_color", COLOR_PORTAL.lightened(0.3))
	teleport_btn.add_theme_color_override("font_hover_color", COLOR_PORTAL.lightened(0.6))
	teleport_btn.pressed.connect(_on_teleport_pressed)
	container.add_child(teleport_btn)

func _build_status(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 40))
	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", TEXT_BODY)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(status_label)

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
	var level = PortalSystem.get_portal_level()
	level_label.text = "等级: %d" % level
	_refresh_points()

func _on_point_selected(point_id: String) -> void:
	selected_point = point_id
	_refresh_points()

func _on_teleport_pressed() -> void:
	if selected_point == "":
		_set_status("请先选择传送点", Color(0.9, 0.3, 0.3))
		return

	if PortalSystem.teleport(selected_point):
		_set_status("传送成功！", COLOR_PORTAL)
		get_tree().change_scene_to_file("res://scenes/levels/open_world.tscn")
	else:
		_set_status("传送失败", Color(0.9, 0.3, 0.3))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")

func _set_status(text: String, color: Color) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
