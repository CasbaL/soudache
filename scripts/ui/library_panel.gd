## 藏经阁界面（仙侠风格）
## 功法列表、学习操作、进度显示
extends Control

const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)
const COLOR_TECHNIQUE = Color(0.4, 0.6, 0.9)  # 功法蓝色

var level_label: Label
var technique_container: VBoxContainer
var detail_label: RichTextLabel
var learn_btn: Button
var status_label: Label

var selected_technique: String = ""

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
	_build_technique_list(main_vbox)
	_build_detail_panel(main_vbox)
	_build_learn_button(main_vbox)
	_build_status(main_vbox)
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "📜 藏 经 阁"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())

	level_label = Label.new()
	level_label.text = "等级: 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", TEXT_BODY)
	hbox.add_child(level_label)

func _build_technique_list(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 300))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "功 法"
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

	technique_container = VBoxContainer.new()
	technique_container.add_theme_constant_override("separation", 4)
	vbox.add_child(technique_container)

	_refresh_techniques()

func _refresh_techniques() -> void:
	if not technique_container:
		return

	for child in technique_container.get_children():
		child.queue_free()

	var techniques = TechniqueSystem.get_unlocked_techniques()
	if techniques.is_empty():
		var empty = Label.new()
		empty.text = "暂无功法  —  升级藏经阁解锁更多"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		technique_container.add_child(empty)
		return

	for tech_id in techniques:
		var tech = TechniqueSystem.get_technique_data(tech_id)
		var is_learned = TechniqueSystem.is_learned(tech_id)
		var is_learning = TechniqueSystem.is_learning(tech_id)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(640, 40)

		var name = tech.get("name", tech_id)
		var desc = tech.get("description", "")
		var status = ""
		if is_learned:
			status = " ✅已学"
		elif is_learning:
			status = " ⏳学习中"

		btn.text = "📖 %s%s    %s" % [name, status, desc]
		btn.add_theme_font_size_override("font_size", 13)

		var bg_color = BTN_NORMAL
		var border_color = PANEL_BORDER.darkened(0.3)
		if is_learned:
			bg_color = Color(0.1, 0.2, 0.1)
			border_color = Color(0.3, 0.7, 0.3)
		elif is_learning:
			bg_color = Color(0.15, 0.15, 0.2)
			border_color = COLOR_TECHNIQUE
		elif selected_technique == tech_id:
			bg_color = Color(0.15, 0.18, 0.25)
			border_color = COLOR_TECHNIQUE

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

		btn.add_theme_color_override("font_color", TEXT_BODY if not is_learned else Color(0.5, 0.8, 0.5))
		btn.add_theme_color_override("font_hover_color", TEXT_TITLE)
		btn.pressed.connect(_on_technique_selected.bind(tech_id))
		technique_container.add_child(btn)

func _build_detail_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 100))

	detail_label = RichTextLabel.new()
	detail_label.bbcode_enabled = true
	detail_label.fit_content = true
	detail_label.scroll_active = false
	detail_label.add_theme_font_size_override("normal_font_size", 13)
	panel.add_child(detail_label)

	_update_detail()

func _update_detail() -> void:
	if not detail_label:
		return

	if selected_technique == "":
		detail_label.text = "[color=#888888]选择功法查看详情[/color]"
		return

	var tech = TechniqueSystem.get_technique_data(selected_technique)
	var name = tech.get("name", "")
	var desc = tech.get("description", "")
	var effect = tech.get("effect", "")
	var learn_time = tech.get("learn_time", 0)

	var text = "[color=#8CB4F2]%s[/color]\n" % name
	text += "[color=#CCCCCC]%s[/color]\n" % desc
	if effect != "":
		text += "[color=#B39966]效果:[/color] [color=#66CC66]%s[/color]\n" % effect
	text += "[color=#B39966]学习时间:[/color] %d秒" % learn_time

	detail_label.text = text

func _build_learn_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	learn_btn = Button.new()
	learn_btn.custom_minimum_size = Vector2(300, 50)
	learn_btn.text = "📖 开 始 学 习"
	learn_btn.add_theme_font_size_override("font_size", 18)

	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_TECHNIQUE.darkened(0.6)
	style.border_color = COLOR_TECHNIQUE
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	learn_btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = COLOR_TECHNIQUE.darkened(0.4)
	hover.border_color = COLOR_TECHNIQUE.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	learn_btn.add_theme_stylebox_override("hover", hover)

	learn_btn.add_theme_color_override("font_color", COLOR_TECHNIQUE.lightened(0.3))
	learn_btn.add_theme_color_override("font_hover_color", COLOR_TECHNIQUE.lightened(0.6))
	learn_btn.pressed.connect(_on_learn_pressed)
	container.add_child(learn_btn)

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
	var level = BuildingSystem.get_building_level("library")
	level_label.text = "等级: %d" % level
	_refresh_techniques()
	_update_detail()

func _on_technique_selected(tech_id: String) -> void:
	selected_technique = tech_id
	_refresh_techniques()
	_update_detail()

func _on_learn_pressed() -> void:
	if selected_technique == "":
		_set_status("请先选择功法", Color(0.9, 0.3, 0.3))
		return

	if TechniqueSystem.start_learning(selected_technique):
		var tech = TechniqueSystem.get_technique_data(selected_technique)
		_set_status("开始学习: %s" % tech.get("name", ""), COLOR_TECHNIQUE)
		_update_all()
	else:
		_set_status("学习失败", Color(0.9, 0.3, 0.3))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")

func _set_status(text: String, color: Color) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
