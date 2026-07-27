## 宝库界面（仙侠风格）
## 宝库物品、保护率、存放操作
extends Control

const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const COLOR_VAULT = Color(0.9, 0.7, 0.2)   # 宝库金色

var level_label: Label
var protection_label: Label
var item_container: VBoxContainer

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
	_build_protection_panel(main_vbox)
	_build_item_list(main_vbox)
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "💎 宝 库"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())

	level_label = Label.new()
	level_label.text = "等级: 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", TEXT_BODY)
	hbox.add_child(level_label)

func _build_protection_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 60))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	protection_label = Label.new()
	protection_label.text = "保护率: 50%"
	protection_label.add_theme_font_size_override("font_size", 20)
	protection_label.add_theme_color_override("font_color", COLOR_VAULT)
	protection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(protection_label)

	var desc = Label.new()
	desc.text = "陨落后宝库物品有概率保留"
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", TEXT_DIM)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

func _build_item_list(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 300))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "宝 库 物 品"
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

	item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 4)
	vbox.add_child(item_container)

	_refresh_items()

func _refresh_items() -> void:
	if not item_container:
		return

	for child in item_container.get_children():
		child.queue_free()

	var items = TreasureVaultSystem.get_vault_items()
	if items.is_empty():
		var empty = Label.new()
		empty.text = "宝库为空  —  在探索中收集珍稀物品吧"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_container.add_child(empty)
		return

	for slot in items:
		var item = items[slot]
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		item_container.add_child(hbox)

		var icon_label = Label.new()
		icon_label.text = "✨"
		icon_label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(icon_label)

		var name_label = Label.new()
		name_label.text = item.get("name", "未知物品")
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", COLOR_VAULT)
		hbox.add_child(name_label)

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
	var level = TreasureVaultSystem.get_vault_level()
	level_label.text = "等级: %d" % level

	var rate = TreasureVaultSystem.get_protection_rate()
	protection_label.text = "保护率: %d%%" % int(rate * 100)

	_refresh_items()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
