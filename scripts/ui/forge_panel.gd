## 炼器界面
## 显示装备配方，打造装备
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
	var level = BuildingSystem.get_building_level("forge")
	level_label.text = "等级: %d" % level
	
	# 更新配方列表
	recipe_list.clear()
	var recipes = CraftingSystem.get_unlocked_recipes()
	for recipe_id in recipes:
		var recipe = CraftingSystem.get_technique_data(recipe_id)
		recipe_list.add_item(recipe.get("name", recipe_id))

func _on_recipe_selected(index: int) -> void:
	var recipes = CraftingSystem.get_unlocked_recipes()
	if index < recipes.size():
		selected_recipe = recipes[index]

func _on_craft_pressed() -> void:
	if selected_recipe == "":
		return
	
	if CraftingSystem.craft_equipment(selected_recipe):
		print("[ForgePanel] 开始打造: %s" % selected_recipe)
		_update_ui()
	else:
		print("[ForgePanel] 打造失败")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
