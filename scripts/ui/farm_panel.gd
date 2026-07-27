## 灵田界面
## 显示种子列表，种植和收获
extends Control

@onready var level_label: Label = $Level
@onready var seed_list: ItemList = $SeedList
@onready var plant_btn: Button = $PlantButton
@onready var harvest_btn: Button = $HarvestButton
@onready var back_btn: Button = $BackButton

var selected_seed: String = ""

func _ready() -> void:
	plant_btn.pressed.connect(_on_plant_pressed)
	harvest_btn.pressed.connect(_on_harvest_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	seed_list.item_selected.connect(_on_seed_selected)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = BuildingSystem.get_building_level("farm")
	level_label.text = "等级: %d" % level
	
	# 更新种子列表
	seed_list.clear()
	var seeds = ["herb_seed", "ore_seed", "quality_herb_seed", "quality_ore_seed", "rare_herb_seed", "rare_ore_seed"]
	for seed_id in seeds:
		var amount = GameManager.storage.get(seed_id, 0)
		if amount > 0:
			var crop_data = FarmSystem.get_crop_data(seed_id)
			seed_list.add_item("%s x%d" % [crop_data.get("name", seed_id), amount])

func _on_seed_selected(index: int) -> void:
	var seeds = ["herb_seed", "ore_seed", "quality_herb_seed", "quality_ore_seed", "rare_herb_seed", "rare_ore_seed"]
	var available_seeds = []
	for seed_id in seeds:
		if GameManager.storage.get(seed_id, 0) > 0:
			available_seeds.append(seed_id)
	
	if index < available_seeds.size():
		selected_seed = available_seeds[index]

func _on_plant_pressed() -> void:
	if selected_seed == "":
		return
	
	if FarmSystem.plant_crop(selected_seed):
		print("[FarmPanel] 种植成功: %s" % selected_seed)
		_update_ui()
	else:
		print("[FarmPanel] 种植失败")

func _on_harvest_pressed() -> void:
	var harvested = FarmSystem.harvest_all()
	print("[FarmPanel] 收获 %d 个作物" % harvested.size())
	_update_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
