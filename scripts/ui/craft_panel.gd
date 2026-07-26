## 打造/炼制面板 UI
## 左侧配方列表，右侧详情（材料/打造按钮/队列）
extends Control

# 左侧
@onready var tab_container: TabContainer = $HBox/Left/TabContainer
@onready var alchemy_list: ItemList = $HBox/Left/TabContainer/炼丹/RecipeList
@onready var forge_list: ItemList = $HBox/Left/TabContainer/炼器/RecipeList

# 右侧
@onready var recipe_name: Label = $HBox/Right/RecipeName
@onready var recipe_desc: Label = $HBox/Right/RecipeDesc
@onready var materials_label: Label = $HBox/Right/Materials
@onready var craft_btn: Button = $HBox/Right/CraftBtn
@onready var queue_label: Label = $HBox/Right/Queue

var selected_recipe: String = ""
var selected_tab: String = "alchemy"

func _ready() -> void:
	alchemy_list.item_selected.connect(_on_alchemy_selected)
	forge_list.item_selected.connect(_on_forge_selected)
	craft_btn.pressed.connect(_on_craft_pressed)
	AlchemySystem.craft_queue_changed.connect(_refresh_queue)
	CraftingSystem.craft_queue_changed.connect(_refresh_queue)
	_refresh_lists()
	_refresh_queue()

func _refresh_lists() -> void:
	alchemy_list.clear()
	for recipe_id in AlchemySystem.get_unlocked_recipes():
		var recipe: Dictionary = AlchemySystem.RECIPES[recipe_id]
		alchemy_list.add_item(recipe.get("name", recipe_id))
		alchemy_list.set_item_metadata(alchemy_list.item_count - 1, recipe_id)

	forge_list.clear()
	for recipe_id in CraftingSystem.get_unlocked_recipes():
		var recipe: Dictionary = CraftingSystem.RECIPES[recipe_id]
		forge_list.add_item(recipe.get("name", recipe_id))
		forge_list.set_item_metadata(forge_list.item_count - 1, recipe_id)

func _on_alchemy_selected(index: int) -> void:
	selected_tab = "alchemy"
	selected_recipe = alchemy_list.get_item_metadata(index)
	_show_recipe_detail()

func _on_forge_selected(index: int) -> void:
	selected_tab = "forge"
	selected_recipe = forge_list.get_item_metadata(index)
	_show_recipe_detail()

func _show_recipe_detail() -> void:
	if selected_recipe.is_empty():
		return
	var recipe: Dictionary
	var system
	if selected_tab == "alchemy":
		recipe = AlchemySystem.RECIPES.get(selected_recipe, {})
		system = AlchemySystem
	else:
		recipe = CraftingSystem.RECIPES.get(selected_recipe, {})
		system = CraftingSystem

	recipe_name.text = recipe.get("name", "")
	recipe_desc.text = recipe.get("description", "")
	# 材料
	var materials: Dictionary = recipe.get("materials", {})
	var parts: Array = []
	for res_id in materials:
		var owned: int = GameManager.storage.get(res_id, 0)
		var need: int = materials[res_id]
		var ok = owned >= need
		parts.append("%s: %d/%d%s" % [_res_name(res_id), owned, need, " ✓" if ok else " ✗"])
	materials_label.text = "\n".join(parts) if parts.size() > 0 else "无材料需求"
	craft_btn.disabled = not system.has_materials(selected_recipe)
	craft_btn.text = "炼制" if selected_tab == "alchemy" else "打造"

func _on_craft_pressed() -> void:
	if selected_recipe.is_empty():
		return
	if selected_tab == "alchemy":
		AlchemySystem.craft_potion(selected_recipe)
	else:
		CraftingSystem.craft_equipment(selected_recipe)
	_show_recipe_detail()
	_refresh_queue()

func _refresh_queue() -> void:
	var lines: Array = []
	lines.append("=== 炼制队列 ===")
	for i in range(AlchemySystem.craft_queue.size()):
		var item: Dictionary = AlchemySystem.craft_queue[i]
		var recipe: Dictionary = AlchemySystem.RECIPES.get(item.get("recipe_id", ""), {})
		var status: String = item.get("status", "")
		if status == "crafting":
			var remaining: float = max(0, item.get("end_time", 0) - Time.get_unix_time_from_system())
			lines.append("[炼丹] %s - 剩余 %s" % [recipe.get("name", ""), _format_time(remaining)])
		else:
			lines.append("[炼丹] %s - 完成 ✓ [收取]" % recipe.get("name", ""))
			if Input.is_action_just_pressed("ui_accept"):
				AlchemySystem.collect_potion(i)

	lines.append("")
	lines.append("=== 打造队列 ===")
	for i in range(CraftingSystem.craft_queue.size()):
		var item: Dictionary = CraftingSystem.craft_queue[i]
		var recipe: Dictionary = CraftingSystem.RECIPES.get(item.get("recipe_id", ""), {})
		var status: String = item.get("status", "")
		if status == "crafting":
			var remaining: float = max(0, item.get("end_time", 0) - Time.get_unix_time_from_system())
			lines.append("[炼器] %s - 剩余 %s" % [recipe.get("name", ""), _format_time(remaining)])
		else:
			var success: bool = item.get("success", false)
			if success:
				lines.append("[炼器] %s - 完成 ✓ [收取]" % recipe.get("name", ""))
			else:
				lines.append("[炼器] %s - 失败 ✗" % recipe.get("name", ""))

	queue_label.text = "\n".join(lines)

static func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

static func _res_name(res_id: String) -> String:
	match res_id:
		"spirit_stone": return "灵石"
		"herb": return "灵草"
		"ore": return "矿石"
		"artifact_spirit": return "器灵"
		_: return res_id
