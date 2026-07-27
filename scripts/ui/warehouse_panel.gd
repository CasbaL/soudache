## 仓库界面
## 显示仓库存储情况
extends Control

@onready var level_label: Label = $Level
@onready var capacity_label: Label = $Capacity
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = BuildingSystem.get_building_level("warehouse")
	level_label.text = "等级: %d" % level
	
	# 更新容量显示
	var capacity = GameManager.get_storage_capacity()
	capacity_label.text = """容量:
灵石: %d/%d
灵草: %d/%d
矿石: %d/%d""" % [
		GameManager.storage.get("spirit_stone", 0), capacity.get("spirit_stone", 5000),
		GameManager.storage.get("herb", 0), capacity.get("herb", 200),
		GameManager.storage.get("ore", 0), capacity.get("ore", 200)
	]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
