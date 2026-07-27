## 修炼界面（仙侠风格）
## 境界信息、属性加成、突破操作
extends Control

const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)
const COLOR_REALM = Color(0.6, 0.4, 0.9)    # 境界紫色
const COLOR_BREAKTHROUGH = Color(0.9, 0.7, 0.2) # 突破金色

# 境界名称
const REALM_NAMES = ["炼气", "筑基", "金丹", "元婴", "化神"]

var level_label: Label
var realm_name_label: Label
var realm_desc_label: Label
var bonus_label: RichTextLabel
var cost_label: RichTextLabel
var breakthrough_btn: Button
var status_label: Label

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
	_build_realm_panel(main_vbox)
	_build_bonus_panel(main_vbox)
	_build_breakthrough_button(main_vbox)
	_build_cost_panel(main_vbox)
	_build_status(main_vbox)
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "🧘 修 炼 室"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())

	level_label = Label.new()
	level_label.text = "等级: 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", TEXT_BODY)
	hbox.add_child(level_label)

func _build_realm_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 120))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	realm_name_label = Label.new()
	realm_name_label.text = "当前境界: 炼气"
	realm_name_label.add_theme_font_size_override("font_size", 24)
	realm_name_label.add_theme_color_override("font_color", COLOR_REALM)
	realm_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(realm_name_label)

	realm_desc_label = Label.new()
	realm_desc_label.text = "初入仙途，感悟天地灵气"
	realm_desc_label.add_theme_font_size_override("font_size", 14)
	realm_desc_label.add_theme_color_override("font_color", TEXT_DIM)
	realm_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(realm_desc_label)

func _build_bonus_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 100))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "境 界 加 成"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	bonus_label = RichTextLabel.new()
	bonus_label.bbcode_enabled = true
	bonus_label.fit_content = true
	bonus_label.scroll_active = false
	bonus_label.add_theme_font_size_override("normal_font_size", 13)
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(bonus_label)

func _build_breakthrough_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	breakthrough_btn = Button.new()
	breakthrough_btn.custom_minimum_size = Vector2(400, 60)
	breakthrough_btn.text = "⚡ 突 破"
	breakthrough_btn.add_theme_font_size_override("font_size", 20)

	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BREAKTHROUGH.darkened(0.6)
	style.border_color = COLOR_BREAKTHROUGH
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	breakthrough_btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = COLOR_BREAKTHROUGH.darkened(0.4)
	hover.border_color = COLOR_BREAKTHROUGH.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	breakthrough_btn.add_theme_stylebox_override("hover", hover)

	var disabled = StyleBoxFlat.new()
	disabled.bg_color = BTN_NORMAL
	disabled.border_color = TEXT_DIM
	disabled.set_border_width_all(2)
	disabled.set_corner_radius_all(8)
	breakthrough_btn.add_theme_stylebox_override("disabled", disabled)

	breakthrough_btn.add_theme_color_override("font_color", COLOR_BREAKTHROUGH.lightened(0.3))
	breakthrough_btn.add_theme_color_override("font_hover_color", COLOR_BREAKTHROUGH.lightened(0.6))
	breakthrough_btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
	breakthrough_btn.pressed.connect(_on_breakthrough_pressed)
	container.add_child(breakthrough_btn)

func _build_cost_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 80))

	cost_label = RichTextLabel.new()
	cost_label.bbcode_enabled = true
	cost_label.fit_content = true
	cost_label.scroll_active = false
	cost_label.add_theme_font_size_override("normal_font_size", 13)
	panel.add_child(cost_label)

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

func _get_realm_desc(realm_idx: int) -> String:
	match realm_idx:
		0: return "初入仙途，感悟天地灵气"
		1: return "筑基成功，根基稳固"
		2: return "金丹大成，法力大增"
		3: return "元婴初现，神识通明"
		4: return "化神境界，超凡入圣"
	return ""

func _update_all() -> void:
	var level = BuildingSystem.get_building_level("training_room")
	level_label.text = "等级: %d" % level

	var realm_idx = RealmSystem.get_current_realm_index()
	var realm_name = RealmSystem.get_realm_name()
	realm_name_label.text = "当前境界: %s" % realm_name
	realm_desc_label.text = _get_realm_desc(realm_idx)

	var bonus = RealmSystem.get_realm_bonus()
	bonus_label.text = "[color=#B39966]攻击:[/color] [color=#66CC66]+%d[/color]    [color=#B39966]防御:[/color] [color=#66CC66]+%d[/color]    [color=#B39966]生命:[/color] [color=#66CC66]+%d[/color]" % [bonus.attack, bonus.defense, bonus.health]

	if RealmSystem.is_max_realm():
		breakthrough_btn.text = "已至化神境"
		breakthrough_btn.disabled = true
		cost_label.text = "[color=#888888]已达最高境界[/color]"
	else:
		var rate = RealmSystem.get_breakthrough_rate()
		breakthrough_btn.text = "⚡ 突破至%s (%d%%)" % [REALM_NAMES[realm_idx + 1], int(rate * 100)]
		breakthrough_btn.disabled = not RealmSystem.can_attempt_breakthrough()

		var cost = RealmSystem.get_breakthrough_cost()
		var cost_text = "[color=#B39966]突破消耗:[/color]\n"
		for res_id in cost:
			var need = cost[res_id]
			var have = GameManager.storage.get(res_id, 0)
			var color = "#66CC66" if have >= need else "#CC6666"
			cost_text += "[color=%s]%s: %d/%d[/color]  " % [color, _get_res_name(res_id), have, need]
		cost_label.text = cost_text

func _get_res_name(res_id: String) -> String:
	match res_id:
		"spirit_stone": return "灵石"
		"herb": return "灵草"
		"ore": return "矿石"
		"technique_fragment": return "功法残页"
	return res_id

func _on_breakthrough_pressed() -> void:
	if RealmSystem.attempt_breakthrough():
		_set_status("突破成功！境界提升！", COLOR_BREAKTHROUGH)
	else:
		_set_status("突破失败...下次再试", Color(0.9, 0.3, 0.3))
	_update_all()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")

func _set_status(text: String, color: Color) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
