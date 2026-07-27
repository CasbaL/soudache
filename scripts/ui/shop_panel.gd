## 商店界面（仙侠风格）
## 商品列表、灵石显示、购买操作
extends Control

const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)
const COLOR_SHOP = Color(0.9, 0.75, 0.3)    # 商店金色
const COLOR_BUY = Color(0.3, 0.8, 0.5)      # 购买绿色

var stone_label: Label
var item_container: VBoxContainer
var detail_label: RichTextLabel
var buy_btn: Button
var status_label: Label

var selected_item: String = ""

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
	_build_item_list(main_vbox)
	_build_detail_panel(main_vbox)
	_build_buy_button(main_vbox)
	_build_status(main_vbox)
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "🏪 商 店"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())

	stone_label = Label.new()
	stone_label.text = "💎 0"
	stone_label.add_theme_font_size_override("font_size", 16)
	stone_label.add_theme_color_override("font_color", COLOR_SHOP)
	hbox.add_child(stone_label)

func _build_item_list(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 350))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "商 品"
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

	item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 4)
	vbox.add_child(item_container)

	_refresh_items()

func _refresh_items() -> void:
	if not item_container:
		return

	for child in item_container.get_children():
		child.queue_free()

	var items = ShopSystem.get_unlocked_items()
	if items.is_empty():
		var empty = Label.new()
		empty.text = "暂无商品  —  升级商店解锁更多"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_container.add_child(empty)
		return

	for item_id in items:
		var item = ShopSystem.get_item_data(item_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(640, 40)

		var name = item.get("name", item_id)
		var price = item.get("price", 0)
		var desc = item.get("description", "")
		var item_type = item.get("type", 0)

		var icon = _get_type_icon(item_type)
		btn.text = "%s %s    💎%d    %s" % [icon, name, price, desc]
		btn.add_theme_font_size_override("font_size", 13)

		var can_afford = GameManager.storage.get("spirit_stone", 0) >= price
		var style = StyleBoxFlat.new()
		style.bg_color = BTN_NORMAL if selected_item != item_id else Color(0.2, 0.18, 0.10)
		style.border_color = PANEL_BORDER.darkened(0.3) if selected_item != item_id else COLOR_SHOP
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)

		var hover = StyleBoxFlat.new()
		hover.bg_color = BTN_HOVER
		hover.border_color = PANEL_BORDER
		hover.set_border_width_all(1)
		hover.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover)

		btn.add_theme_color_override("font_color", TEXT_BODY if can_afford else TEXT_DIM)
		btn.add_theme_color_override("font_hover_color", TEXT_TITLE)
		btn.pressed.connect(_on_item_selected.bind(item_id))
		item_container.add_child(btn)

func _get_type_icon(item_type: int) -> String:
	match item_type:
		0: return "🌱"  # SEED
		1: return "📜"  # RECIPE
		2: return "📐"  # Blueprint
		3: return "📦"  # MATERIAL
		4: return "✨"  # SPECIAL
	return "📦"

func _build_detail_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 80))

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

	if selected_item == "":
		detail_label.text = "[color=#888888]选择商品查看详情[/color]"
		return

	var item = ShopSystem.get_item_data(selected_item)
	var name = item.get("name", "")
	var desc = item.get("description", "")
	var price = item.get("price", 0)
	var have = GameManager.storage.get("spirit_stone", 0)
	var can_afford = have >= price

	var text = "[color=#F2D98C]%s[/color]\n" % name
	text += "[color=#CCCCCC]%s[/color]\n" % desc
	var price_color = "#66CC66" if can_afford else "#CC6666"
	text += "[color=%s]价格: 💎 %d (拥有: %d)[/color]" % [price_color, price, have]

	detail_label.text = text

func _build_buy_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(300, 50)
	buy_btn.text = "💰 购 买"
	buy_btn.add_theme_font_size_override("font_size", 18)

	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BUY.darkened(0.6)
	style.border_color = COLOR_BUY
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	buy_btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = COLOR_BUY.darkened(0.4)
	hover.border_color = COLOR_BUY.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	buy_btn.add_theme_stylebox_override("hover", hover)

	buy_btn.add_theme_color_override("font_color", COLOR_BUY.lightened(0.3))
	buy_btn.add_theme_color_override("font_hover_color", COLOR_BUY.lightened(0.6))
	buy_btn.pressed.connect(_on_buy_pressed)
	container.add_child(buy_btn)

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
	stone_label.text = "💎 %d" % GameManager.storage.get("spirit_stone", 0)
	_refresh_items()
	_update_detail()

func _on_item_selected(item_id: String) -> void:
	selected_item = item_id
	_refresh_items()
	_update_detail()

func _on_buy_pressed() -> void:
	if selected_item == "":
		_set_status("请先选择商品", Color(0.9, 0.3, 0.3))
		return

	if ShopSystem.purchase_item(selected_item):
		var item = ShopSystem.get_item_data(selected_item)
		_set_status("购买成功: %s" % item.get("name", ""), COLOR_BUY)
		_update_all()
	else:
		_set_status("购买失败（灵石不足）", Color(0.9, 0.3, 0.3))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")

func _set_status(text: String, color: Color) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
