## 炼丹界面
## 显示丹方列表，选择材料炼制丹药
extends Control

@onready var level_label: Label = $Level
@onready var recipe_list: ItemList = $RecipeList
@onready var craft_btn: Button = $CraftButton
@onready var back_btn: Button = $BackButton

var selected_recipe: String = ""

func _ready() -> void:
	craft_btn.pressed.connect(_on_craft_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	recipe_list.item_selected.connect(_on_recipe_selected)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = BuildingSystem.get_building_level("alchemy_furnace")
	level_label.text = "等级: %d" % level
	
	# 更新丹方列表
	recipe_list.clear()
	var recipes = AlchemySystem.get_unlocked_recipes()
	for recipe_id in recipes:
		var recipe = AlchemySystem.get_technique_data(recipe_id)
		recipe_list.add_item(recipe.get("name", recipe_id))

func _on_recipe_selected(index: int) -> void:
	var recipes = AlchemySystem.get_unlocked_recipes()
	if index < recipes.size():
		selected_recipe = recipes[index]

func _on_craft_pressed() -> void:
	if selected_recipe == "":
		return
	
	if AlchemySystem.craft_potion(selected_recipe):
		print("[AlchemyPanel] 开始炼制: %s" % selected_recipe)
		_update_ui()
	else:
		print("[AlchemyPanel] 炼制失败")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
