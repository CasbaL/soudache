## 宝库界面
## 显示宝库物品和保护率
extends Control

@onready var level_label: Label = $Level
@onready var protection_rate_label: Label = $ProtectionRate
@onready var item_list: ItemList = $ItemList
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = TreasureVaultSystem.get_vault_level()
	level_label.text = "等级: %d" % level
	
	# 更新保护率显示
	var protection_rate = TreasureVaultSystem.get_protection_rate()
	protection_rate_label.text = "保护率: %d%%" % int(protection_rate * 100)
	
	# 更新物品列表
	item_list.clear()
	var items = TreasureVaultSystem.get_vault_items()
	for slot in items:
		var item = items[slot]
		item_list.add_item(item.get("name", "未知物品"))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
