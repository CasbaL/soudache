## 门派选择界面（仙侠风格）
## 点击卡片直接选择，简化操作流程
extends Control

# 颜色常量
const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)

# 门派颜色
const FACTION_COLORS = {
	"sword": Color(0.9, 0.75, 0.2),     # 金色
	"talisman": Color(0.3, 0.5, 0.9),   # 蓝色
	"pill": Color(0.3, 0.8, 0.4),       # 绿色
}

# 门派信息
const FACTIONS = [
	{
		"id": "sword",
		"name": "剑修",
		"title": "剑气凌云",
		"icon": "⚔",
		"desc": "近战高爆发，剑气纵横",
		"tags": ["近战", "高爆发", "剑气"],
		"stats": {"hp": 500, "atk": 120, "def": 50, "spd": 100},
		"skills": ["剑气斩", "万剑归宗", "剑意护体"],
		"difficulty": "★☆☆",
	},
	{
		"id": "talisman",
		"name": "符修",
		"title": "符咒通灵",
		"icon": "📜",
		"desc": "远程控制，符咒连击",
		"tags": ["远程", "控制", "符咒"],
		"stats": {"hp": 400, "atk": 100, "def": 40, "spd": 80},
		"skills": ["雷符", "火符连击", "天雷阵"],
		"difficulty": "★★☆",
	},
	{
		"id": "pill",
		"name": "丹修",
		"title": "丹道长生",
		"icon": "⚗",
		"desc": "坦克治疗，丹药辅助",
		"tags": ["坦克", "治疗", "辅助"],
		"stats": {"hp": 700, "atk": 80, "def": 80, "spd": 70},
		"skills": ["回春术", "九转还魂", "丹火护体"],
		"difficulty": "★★★",
	},
]

# 节点引用
var info_panel: PanelContainer
var info_name: Label
var info_desc: Label
var stats_container: VBoxContainer
var skills_label: Label
var select_btn: Button

var selected_faction: String = ""

func _ready() -> void:
	_build_ui()

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
	main_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(main_vbox)

	_add_spacer(main_vbox, 30)

	# 标题
	var title = Label.new()
	title.text = "选 择 门 派"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "踏上修仙之路"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", TEXT_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(subtitle)

	_add_spacer(main_vbox, 10)

	# 门派卡片
	for faction in FACTIONS:
		_build_faction_card(main_vbox, faction)

	# 详情面板
	_build_info_panel(main_vbox)

	# 确认按钮
	_build_select_button(main_vbox)

	_add_spacer(main_vbox, 20)

func _build_faction_card(parent: Control, faction: Dictionary) -> void:
	var color = FACTION_COLORS.get(faction.id, TEXT_BODY)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(640, 80)

	var tags_text = "  ".join(faction.tags)
	btn.text = "%s  %s · %s    %s    %s    难度: %s" % [
		faction.icon, faction.name, faction.title,
		faction.desc, tags_text, faction.difficulty
	]
	btn.add_theme_font_size_override("font_size", 15)

	# 样式
	var style = StyleBoxFlat.new()
	style.bg_color = BTN_NORMAL
	style.border_color = color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = color.darkened(0.6)
	hover.border_color = color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = color.darkened(0.7)
	pressed.border_color = color.lightened(0.2)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(8)
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", color.lightened(0.3))
	btn.add_theme_color_override("font_hover_color", color.lightened(0.6))
	btn.pressed.connect(_on_faction_selected.bind(faction.id))
	parent.add_child(btn)

func _build_info_panel(parent: Control) -> void:
	info_panel = _create_panel(parent, Vector2(680, 250))
	info_panel.visible = false

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	info_panel.add_child(vbox)

	info_name = Label.new()
	info_name.text = ""
	info_name.add_theme_font_size_override("font_size", 20)
	info_name.add_theme_color_override("font_color", TEXT_TITLE)
	info_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_name)

	info_desc = Label.new()
	info_desc.text = ""
	info_desc.add_theme_font_size_override("font_size", 14)
	info_desc.add_theme_color_override("font_color", TEXT_BODY)
	info_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_desc)

	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = PANEL_BORDER.darkened(0.5)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# 属性条
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_container)

	var sep2 = HSeparator.new()
	sep2.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep2)

	# 技能
	skills_label = Label.new()
	skills_label.text = ""
	skills_label.add_theme_font_size_override("font_size", 13)
	skills_label.add_theme_color_override("font_color", TEXT_BODY)
	skills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skills_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(skills_label)

func _build_select_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	select_btn = Button.new()
	select_btn.custom_minimum_size = Vector2(400, 60)
	select_btn.text = "⚔ 踏 上 修 仙 路"
	select_btn.add_theme_font_size_override("font_size", 22)
	select_btn.disabled = true

	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BORDER.darkened(0.6)
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	select_btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = PANEL_BORDER.darkened(0.4)
	hover.border_color = PANEL_BORDER.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	select_btn.add_theme_stylebox_override("hover", hover)

	var disabled = StyleBoxFlat.new()
	disabled.bg_color = BTN_NORMAL
	disabled.border_color = TEXT_DIM
	disabled.set_border_width_all(2)
	disabled.set_corner_radius_all(8)
	select_btn.add_theme_stylebox_override("disabled", disabled)

	select_btn.add_theme_color_override("font_color", PANEL_BORDER.lightened(0.3))
	select_btn.add_theme_color_override("font_hover_color", PANEL_BORDER.lightened(0.6))
	select_btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
	select_btn.pressed.connect(_on_select_pressed)
	container.add_child(select_btn)

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

func _get_stat_bar(label_text: String, value: int, max_val: int, color: Color) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT_DIM)
	hbox.add_child(label)

	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = max_val
	bar.value = value
	bar.show_percentage = false

	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.15, 0.2)
	bar_bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = color
	bar_fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", bar_fill)

	hbox.add_child(bar)

	var val_label = Label.new()
	val_label.text = str(value)
	val_label.custom_minimum_size = Vector2(40, 0)
	val_label.add_theme_font_size_override("font_size", 13)
	val_label.add_theme_color_override("font_color", color)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(val_label)

	return hbox

# ============================================================
# 回调
# ============================================================

func _on_faction_selected(faction_id: String) -> void:
	selected_faction = faction_id
	select_btn.disabled = false

	# 找到门派数据
	var faction_data = null
	for f in FACTIONS:
		if f.id == faction_id:
			faction_data = f
			break

	if not faction_data:
		return

	var color = FACTION_COLORS.get(faction_id, TEXT_BODY)

	# 更新详情面板
	info_panel.visible = true
	info_name.text = "%s · %s" % [faction_data.name, faction_data.title]
	info_name.add_theme_color_override("font_color", color)

	info_desc.text = faction_data.desc

	# 更新属性条
	for child in stats_container.get_children():
		child.queue_free()

	var stats = faction_data.stats
	stats_container.add_child(_get_stat_bar("生命", stats.hp, 800, Color(0.3, 0.8, 0.4)))
	stats_container.add_child(_get_stat_bar("攻击", stats.atk, 150, Color(0.9, 0.4, 0.3)))
	stats_container.add_child(_get_stat_bar("防御", stats.def, 100, Color(0.4, 0.6, 0.9)))
	stats_container.add_child(_get_stat_bar("速度", stats.spd, 120, Color(0.9, 0.8, 0.3)))

	# 更新技能
	var skill_text = "技能: "
	for i in range(faction_data.skills.size()):
		if i > 0:
			skill_text += "  ·  "
		skill_text += faction_data.skills[i]
	skills_label.text = skill_text
	skills_label.add_theme_color_override("font_color", color.lightened(0.2))

func _on_select_pressed() -> void:
	if selected_faction == "":
		return

	FactionSystem.select_faction(selected_faction)
	SceneTransition.go_to_haven()
