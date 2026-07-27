## 背包面板（仙侠风格）
## 网格显示物品、详情面板、使用/丢弃操作
extends PanelContainer

# 配置
@export var columns: int = 5
@export var slot_size: Vector2 = Vector2(100, 100)

# 颜色常量
const PANEL_BG = Color(0.10, 0.12, 0.18, 0.95)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const SLOT_EMPTY = Color(0.15, 0.15, 0.20, 0.8)
const SLOT_BORDER = Color(0.3, 0.3, 0.35)

# 稀有度颜色
const RARITY_COLORS = {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.8, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
	"legendary": Color(1.0, 0.8, 0.0),
	"blue": Color(0.3, 0.5, 1.0),
	"purple": Color(0.7, 0.3, 1.0),
	"gold": Color(1.0, 0.8, 0.0),
}

# 物品图标映射
const ITEM_ICONS = {
	"spirit_stone": "💎",
	"herb": "🌿",
	"ore": "⛏",
	"chest": "📦",
	"fire_crystal": "🔥",
	"gear": "⚙",
	"technique_fragment": "📜",
	"equipment": "⚔",
	"herb_seed": "🌱",
	"ore_seed": "🪨",
	"quality_herb_seed": "🌿",
	"quality_ore_seed": "🪨",
	"rare_herb_seed": "🌿",
	"rare_ore_seed": "🪨",
	"restore_pill": "💊",
	"shield_pill": "🛡",
	"attack_pill": "⚔",
	"defense_pill": "🛡",
	"crit_pill": "💥",
	"dodge_pill": "💨",
}

# 子节点引用
var title_label: Label
var grid: GridContainer
var detail_panel: PanelContainer
var detail_label: RichTextLabel
var use_btn: Button
var discard_btn: Button
var close_btn: Button

# 物品槽位
var slots: Array[PanelContainer] = []
var selected_slot: int = -1

# 信号
signal inventory_closed()

func _ready() -> void:
	_build_ui()
	_on_inventory_changed()
	GameManager.inventory_changed.connect(_on_inventory_changed)

# ============================================================
# UI 构建
# ============================================================

func _build_ui() -> void:
	# 面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(columns * slot_size.x + 40, 550)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# 标题栏
	_build_header(main_vbox)

	# 物品格子
	_build_grid(main_vbox)

	# 详情面板
	_build_detail_panel(main_vbox)

	# 操作按钮
	_build_actions(main_vbox)

	# 关闭按钮
	_build_close_button(main_vbox)

func _build_header(parent: Control) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	parent.add_child(hbox)

	title_label = Label.new()
	title_label.text = "🎒 背包 (0/10)"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title_label)

func _build_grid(parent: Control) -> void:
	grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	parent.add_child(grid)

	# 创建槽位
	for i in range(GameManager.max_inventory_size):
		var slot = _create_slot(i)
		grid.add_child(slot)
		slots.append(slot)

func _create_slot(index: int) -> PanelContainer:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = slot_size

	var style = StyleBoxFlat.new()
	style.bg_color = SLOT_EMPTY
	style.border_color = SLOT_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	slot.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)

	# 图标
	var icon_label = Label.new()
	icon_label.name = "Icon"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(icon_label)

	# 名称
	var name_label = Label.new()
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", TEXT_BODY)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	vbox.add_child(name_label)

	# 数量
	var amount_label = Label.new()
	amount_label.name = "Amount"
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.add_theme_font_size_override("font_size", 11)
	amount_label.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(amount_label)

	# 点击事件
	slot.gui_input.connect(_on_slot_input.bind(index))

	return slot

func _build_detail_panel(parent: Control) -> void:
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(0, 80)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.15, 0.9)
	style.border_color = PANEL_BORDER.darkened(0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	detail_panel.add_theme_stylebox_override("panel", style)

	detail_label = RichTextLabel.new()
	detail_label.bbcode_enabled = true
	detail_label.fit_content = true
	detail_label.scroll_active = false
	detail_label.add_theme_font_size_override("normal_font_size", 12)
	detail_panel.add_child(detail_label)

	parent.add_child(detail_panel)
	_update_detail()

func _build_actions(parent: Control) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	# 使用按钮
	use_btn = Button.new()
	use_btn.text = "使用"
	use_btn.custom_minimum_size = Vector2(100, 35)
	use_btn.add_theme_font_size_override("font_size", 14)
	_style_action_button(use_btn, Color(0.3, 0.7, 0.3))
	use_btn.pressed.connect(_on_use_pressed)
	use_btn.disabled = true
	hbox.add_child(use_btn)

	# 丢弃按钮
	discard_btn = Button.new()
	discard_btn.text = "丢弃"
	discard_btn.custom_minimum_size = Vector2(100, 35)
	discard_btn.add_theme_font_size_override("font_size", 14)
	_style_action_button(discard_btn, Color(0.7, 0.3, 0.3))
	discard_btn.pressed.connect(_on_discard_pressed)
	discard_btn.disabled = true
	hbox.add_child(discard_btn)

func _build_close_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(150, 35)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", TEXT_DIM)
	close_btn.add_theme_color_override("font_hover_color", TEXT_BODY)
	close_btn.pressed.connect(_on_close_pressed)
	container.add_child(close_btn)

func _style_action_button(btn: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.6)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = color.darkened(0.4)
	hover.border_color = color.lightened(0.2)
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover)

	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.15, 0.15, 0.15)
	disabled.border_color = Color(0.25, 0.25, 0.25)
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_color_override("font_color", color.lightened(0.3))
	btn.add_theme_color_override("font_hover_color", color.lightened(0.6))
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)

# ============================================================
# 数据更新
# ============================================================

func _on_inventory_changed() -> void:
	var items = GameManager.inventory
	title_label.text = "🎒 背包 (%d/%d)" % [items.size(), GameManager.max_inventory_size]

	for i in range(slots.size()):
		var slot = slots[i]
		var icon_label = slot.get_node("Icon") as Label
		var name_label = slot.get_node("Name") as Label
		var amount_label = slot.get_node("Amount") as Label

		if i < items.size():
			var item = items[i]
			var item_id = item.get("id", "")
			var item_name = item.get("name", "???")
			var amount = item.get("amount", 1)
			var rarity = item.get("rarity", "common")

			# 图标
			icon_label.text = ITEM_ICONS.get(item_id, "📦")

			# 名称
			name_label.text = item_name
			name_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, TEXT_BODY))

			# 数量
			if amount > 1:
				amount_label.text = "x%d" % amount
				amount_label.visible = true
			else:
				amount_label.visible = false

			# 槽位边框颜色
			var style = slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			style.border_color = RARITY_COLORS.get(rarity, SLOT_BORDER)
			if i == selected_slot:
				style.border_color = PANEL_BORDER
				style.bg_color = Color(0.2, 0.18, 0.10)
			slot.add_theme_stylebox_override("panel", style)
		else:
			icon_label.text = ""
			name_label.text = ""
			amount_label.text = ""
			amount_label.visible = false

			var style = slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			style.bg_color = SLOT_EMPTY
			style.border_color = SLOT_BORDER
			slot.add_theme_stylebox_override("panel", style)

	_update_detail()

func _update_detail() -> void:
	if not detail_label:
		return

	var items = GameManager.inventory
	if selected_slot < 0 or selected_slot >= items.size():
		detail_label.text = "[color=#888888]点击物品查看详情[/color]"
		use_btn.disabled = true
		discard_btn.disabled = true
		return

	var item = items[selected_slot]
	var item_id = item.get("id", "")
	var item_name = item.get("name", "???")
	var amount = item.get("amount", 1)
	var rarity = item.get("rarity", "common")
	var desc = item.get("description", "")

	var rarity_color = RARITY_COLORS.get(rarity, TEXT_BODY)
	var text = "[color=%s]%s[/color]" % [_color_to_hex(rarity_color), item_name]
	if amount > 1:
		text += "  [color=#888888]x%d[/color]" % amount
	text += "\n"
	if desc != "":
		text += "[color=#CCCCCC]%s[/color]\n" % desc

	# 显示物品类型
	var type_text = _get_item_type_text(item_id)
	if type_text != "":
		text += "[color=#B39966]%s[/color]" % type_text

	detail_label.text = text

	# 启用按钮
	use_btn.disabled = not _can_use_item(item_id)
	discard_btn.disabled = false

func _color_to_hex(color: Color) -> String:
	return "#%02X%02X%02X" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]

func _get_item_type_text(item_id: String) -> String:
	if item_id.ends_with("_seed"):
		return "种子 — 在灵田种植"
	if item_id.ends_with("_pill"):
		return "丹药 — 点击使用"
	if item_id in ["spirit_stone", "herb", "ore", "fire_crystal", "gear"]:
		return "材料 — 用于炼制/建造"
	if item_id == "technique_fragment":
		return "材料 — 用于学习功法"
	if item_id == "equipment":
		return "装备 — 在装备界面穿戴"
	return ""

func _can_use_item(item_id: String) -> bool:
	# 丹药可以使用
	if item_id.ends_with("_pill"):
		return true
	# 种子可以在灵田使用（但这里不处理）
	return false

# ============================================================
# 交互
# ============================================================

func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var items = GameManager.inventory
		if index < items.size():
			selected_slot = index
			_on_inventory_changed()

func _on_use_pressed() -> void:
	if selected_slot < 0:
		return

	var items = GameManager.inventory
	if selected_slot >= items.size():
		return

	var item = items[selected_slot]
	var item_id = item.get("id", "")

	# 使用丹药
	if item_id.ends_with("_pill"):
		_use_pill(item_id, selected_slot)

func _use_pill(item_id: String, slot_index: int) -> void:
	# 根据丹药类型应用效果
	match item_id:
		"restore_pill":
			var heal_amount = int(GameManager.player_data.max_health * 0.3)
			GameManager.player_heal(heal_amount)
			_show_status("使用回复丹，恢复 %d 生命" % heal_amount)
		"shield_pill":
			# TODO: 实现护盾效果
			_show_status("使用护盾丹")
		"attack_pill":
			# TODO: 实现攻击加成
			_show_status("使用攻击丹")
		"defense_pill":
			# TODO: 实现防御加成
			_show_status("使用防御丹")
		"crit_pill":
			# TODO: 实现暴击加成
			_show_status("使用暴击丹")
		"dodge_pill":
			# TODO: 实现闪避加成
			_show_status("使用闪避丹")
		_:
			_show_status("无法使用该物品")
			return

	# 消耗物品
	GameManager.remove_from_inventory(slot_index)
	selected_slot = -1
	_on_inventory_changed()

func _on_discard_pressed() -> void:
	if selected_slot < 0:
		return

	var items = GameManager.inventory
	if selected_slot >= items.size():
		return

	var item = items[selected_slot]
	var item_name = item.get("name", "???")
	GameManager.remove_from_inventory(selected_slot)
	selected_slot = -1
	_show_status("丢弃了 %s" % item_name)
	_on_inventory_changed()

func _on_close_pressed() -> void:
	inventory_closed.emit()
	visible = false

func _show_status(text: String) -> void:
	# 更新详情面板显示状态
	if detail_label:
		detail_label.text = "[color=#66CC66]%s[/color]" % text
