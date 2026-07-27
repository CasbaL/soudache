## 洞府主界面
## 显示所有建筑，点击进入对应建筑界面
extends Control

# 建筑按钮引用
@onready var explore_btn: Button = $ExploreButton
@onready var equipment_btn: Button = $EquipmentButton
@onready var alchemy_furnace_btn: Button = $BuildingGrid/AlchemyFurnace
@onready var forge_btn: Button = $BuildingGrid/Forge
@onready var training_room_btn: Button = $BuildingGrid/TrainingRoom
@onready var library_btn: Button = $BuildingGrid/Library
@onready var farm_btn: Button = $BuildingGrid/Farm
@onready var warehouse_btn: Button = $BuildingGrid/Warehouse
@onready var portal_btn: Button = $BuildingGrid/Portal
@onready var shop_btn: Button = $BuildingGrid/Shop
@onready var treasure_vault_btn: Button = $BuildingGrid/TreasureVault
@onready var inventory_btn: Button = $InventoryButton
@onready var back_btn: Button = $BackButton

# 资源显示
@onready var spirit_stone_label: Label = $Resources/SpiritStone
@onready var herb_label: Label = $Resources/Herb
@onready var ore_label: Label = $Resources/Ore

func _ready() -> void:
	# 连接按钮信号
	explore_btn.pressed.connect(_on_explore_pressed)
	equipment_btn.pressed.connect(_on_equipment_pressed)
	alchemy_furnace_btn.pressed.connect(_on_building_pressed.bind("alchemy_furnace"))
	forge_btn.pressed.connect(_on_building_pressed.bind("forge"))
	training_room_btn.pressed.connect(_on_building_pressed.bind("training_room"))
	library_btn.pressed.connect(_on_building_pressed.bind("library"))
	farm_btn.pressed.connect(_on_building_pressed.bind("farm"))
	warehouse_btn.pressed.connect(_on_building_pressed.bind("warehouse"))
	portal_btn.pressed.connect(_on_building_pressed.bind("portal"))
	shop_btn.pressed.connect(_on_building_pressed.bind("shop"))
	treasure_vault_btn.pressed.connect(_on_building_pressed.bind("treasure_vault"))
	inventory_btn.pressed.connect(_on_warehouse_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	# 更新资源显示
	_update_resources()

## 更新资源显示
func _update_resources() -> void:
	spirit_stone_label.text = "灵石: %d" % GameManager.storage.get("spirit_stone", 0)
	herb_label.text = "灵草: %d" % GameManager.storage.get("herb", 0)
	ore_label.text = "矿石: %d" % GameManager.storage.get("ore", 0)

## 世界探索按钮
func _on_explore_pressed() -> void:
	print("[HavenMain] 进入世界探索")
	SceneTransition.go_to_explore()

## 装备按钮
func _on_equipment_pressed() -> void:
	print("[HavenMain] 打开装备界面")
	SceneTransition.change_scene("res://scenes/ui/equipment_panel.tscn")

## 仓库按钮
func _on_warehouse_pressed() -> void:
	print("[HavenMain] 打开仓库界面")
	SceneTransition.change_scene("res://scenes/ui/warehouse_panel.tscn")

## 返回门派选择
func _on_back_pressed() -> void:
	print("[HavenMain] 返回门派选择")
	SceneTransition.change_scene("res://scenes/ui/faction_select.tscn")

## 建筑按钮点击
func _on_building_pressed(building_id: String) -> void:
	print("[HavenMain] 点击建筑: %s" % building_id)

	# 根据建筑ID跳转到对应界面
	var scene_path = ""
	match building_id:
		"alchemy_furnace":
			scene_path = "res://scenes/ui/alchemy_panel.tscn"
		"forge":
			scene_path = "res://scenes/ui/forge_panel.tscn"
		"training_room":
			scene_path = "res://scenes/ui/training_panel.tscn"
		"library":
			scene_path = "res://scenes/ui/library_panel.tscn"
		"farm":
			scene_path = "res://scenes/ui/farm_panel.tscn"
		"warehouse":
			scene_path = "res://scenes/ui/warehouse_panel.tscn"
		"portal":
			scene_path = "res://scenes/ui/portal_panel.tscn"
		"shop":
			scene_path = "res://scenes/ui/shop_panel.tscn"
		"treasure_vault":
			scene_path = "res://scenes/ui/vault_panel.tscn"

	if scene_path != "":
		SceneTransition.change_scene(scene_path)
