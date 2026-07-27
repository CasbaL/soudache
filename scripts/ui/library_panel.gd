## 藏经界面
## 显示功法列表，学习功法
extends Control

@onready var level_label: Label = $Level
@onready var technique_list: ItemList = $TechniqueList
@onready var learn_btn: Button = $LearnButton
@onready var back_btn: Button = $BackButton

var selected_technique: String = ""

func _ready() -> void:
	learn_btn.pressed.connect(_on_learn_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	technique_list.item_selected.connect(_on_technique_selected)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = BuildingSystem.get_building_level("library")
	level_label.text = "等级: %d" % level
	
	# 更新功法列表
	technique_list.clear()
	var techniques = TechniqueSystem.get_unlocked_techniques()
	for tech_id in techniques:
		var tech = TechniqueSystem.get_technique_data(tech_id)
		var status = ""
		if TechniqueSystem.is_learned(tech_id):
			status = " [已学]"
		elif TechniqueSystem.is_learning(tech_id):
			status = " [学习中]"
		technique_list.add_item("%s%s" % [tech.get("name", tech_id), status])

func _on_technique_selected(index: int) -> void:
	var techniques = TechniqueSystem.get_unlocked_techniques()
	if index < techniques.size():
		selected_technique = techniques[index]

func _on_learn_pressed() -> void:
	if selected_technique == "":
		return
	
	if TechniqueSystem.start_learning(selected_technique):
		print("[LibraryPanel] 开始学习: %s" % selected_technique)
		_update_ui()
	else:
		print("[LibraryPanel] 学习失败")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
