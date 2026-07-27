## 炼器界面（仙侠风格）
## 装备配方列表、材料显示、打造操作
extends Control

# 颜色常量
const PANEL_BG = Color(0.10, 0.12, 0.18, 0.90)
const PANEL_BORDER = Color(0.77, 0.64, 0.35)
const TEXT_TITLE = Color(0.95, 0.85, 0.55)
const TEXT_BODY = Color(0.85, 0.85, 0.80)
const TEXT_DIM = Color(0.55, 0.55, 0.50)
const BTN_NORMAL = Color(0.15, 0.18, 0.25, 0.90)
const BTN_HOVER = Color(0.20, 0.24, 0.35, 0.95)
const COLOR_FORGE = Color(0.9, 0.5, 0.2)   # 炼器橙色
const COLOR_MATERIAL = Color(0.7, 0.6, 0.4)

# 节点引用
var level_label: Label
var recipe_container: VBoxContainer
var detail_label: RichTextLabel
var craft_btn: Button
var status_label: Label

var selected_recipe: String = ""

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
	_build_recipe_list(main_vbox)
	_build_detail_panel(main_vbox)
	_build_craft_button(main_vbox)
	_build_status(main_vbox)
	_build_footer(main_vbox)

func _build_header(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 50))

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var title = Label.new()
	title.text = "🔨 炼 器 台"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT_TITLE)
	hbox.add_child(title)

	hbox.add_child(Control.new())

	level_label = Label.new()
	level_label.text = "等级: 1"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", TEXT_BODY)
	hbox.add_child(level_label)

func _build_recipe_list(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 300))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "配 方"
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

	recipe_container = VBoxContainer.new()
	recipe_container.add_theme_constant_override("separation", 4)
	vbox.add_child(recipe_container)

	_refresh_recipes()

func _refresh_recipes() -> void:
	if not recipe_container:
		return

	for child in recipe_container.get_children():
		child.queue_free()

	var recipes = CraftingSystem.get_unlocked_recipes()
	if recipes.is_empty():
		var empty = Label.new()
		empty.text = "暂无配方  —  在藏经阁学习可解锁"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recipe_container.add_child(empty)
		return

	for recipe_id in recipes:
		var recipe = CraftingSystem.get_technique_data(recipe_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(640, 40)

		var name = recipe.get("name", recipe_id)
		var desc = recipe.get("description", "")
		btn.text = "⚔ %s    %s" % [name, desc]
		btn.add_theme_font_size_override("font_size", 13)

		var style = StyleBoxFlat.new()
		style.bg_color = BTN_NORMAL if selected_recipe != recipe_id else Color(0.25, 0.15, 0.10)
		style.border_color = PANEL_BORDER.darkened(0.3) if selected_recipe != recipe_id else COLOR_FORGE
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
		btn.pressed.connect(_on_recipe_selected.bind(recipe_id))
		recipe_container.add_child(btn)

func _build_detail_panel(parent: Control) -> void:
	var panel = _create_panel(parent, Vector2(680, 120))

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

	if selected_recipe == "":
		detail_label.text = "[color=#888888]选择配方查看详情[/color]"
		return

	var recipe = CraftingSystem.get_technique_data(selected_recipe)
	var name = recipe.get("name", "")
	var desc = recipe.get("description", "")
	var materials = recipe.get("materials", {})
	var rarity = recipe.get("rarity", "common")

	var rarity_color = _get_rarity_color(rarity)
	var text = "[color=%s]%s[/color]  [color=#888888][%s][/color]\n" % [rarity_color, name, rarity]
	text += "[color=#CCCCCC]%s[/color]\n\n" % desc
	text += "[color=#B39966]材料:[/color] "

	for mat_id in materials:
		var need = materials[mat_id]
		var have = GameManager.storage.get(mat_id, 0)
		var color = "#66CC66" if have >= need else "#CC6666"
		text += "[color=%s]%s %d/%d[/color]  " % [color, _get_mat_name(mat_id), have, need]

	detail_label.text = text

func _get_rarity_color(rarity: String) -> String:
	match rarity:
		"common": return "#CCCCCC"
		"uncommon": return "#66CC66"
		"rare": return "#6699FF"
		"epic": return "#CC66FF"
		"legendary": return "#FFCC33"
	return "#CCCCCC"

func _build_craft_button(parent: Control) -> void:
	var container = CenterContainer.new()
	parent.add_child(container)

	craft_btn = Button.new()
	craft_btn.custom_minimum_size = Vector2(300, 50)
	craft_btn.text = "🔨 开 始 打 造"
	craft_btn.add_theme_font_size_override("font_size", 18)

	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_FORGE.darkened(0.6)
	style.border_color = COLOR_FORGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	craft_btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = COLOR_FORGE.darkened(0.4)
	hover.border_color = COLOR_FORGE.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	craft_btn.add_theme_stylebox_override("hover", hover)

	craft_btn.add_theme_color_override("font_color", COLOR_FORGE.lightened(0.3))
	craft_btn.add_theme_color_override("font_hover_color", COLOR_FORGE.lightened(0.6))
	craft_btn.pressed.connect(_on_craft_pressed)
	container.add_child(craft_btn)

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

# 工具函数
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

func _get_mat_name(mat_id: String) -> String:
	match mat_id:
		"herb": return "灵草"
		"ore": return "矿石"
		"fire_crystal": return "火晶石"
		"gear": return "齿轮"
		"spirit_stone": return "灵石"
		"technique_fragment": return "功法残页"
	return mat_id

# 数据更新
func _update_all() -> void:
	var level = BuildingSystem.get_building_level("forge")
	level_label.text = "等级: %d" % level
	_refresh_recipes()
	_update_detail()

# 回调
func _on_recipe_selected(recipe_id: String) -> void:
	selected_recipe = recipe_id
	_refresh_recipes()
	_update_detail()

func _on_craft_pressed() -> void:
	if selected_recipe == "":
		_set_status("请先选择配方", Color(0.9, 0.3, 0.3))
		return

	if CraftingSystem.craft_equipment(selected_recipe):
		var recipe = CraftingSystem.get_technique_data(selected_recipe)
		_set_status("开始打造: %s" % recipe.get("name", ""), COLOR_FORGE)
		_update_all()
	else:
		_set_status("打造失败（材料不足）", Color(0.9, 0.3, 0.3))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")

func _set_status(text: String, color: Color) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
