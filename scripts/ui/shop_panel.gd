## 商店界面
## 显示商品列表，购买物品
extends Control

@onready var level_label: Label = $Level
@onready var spirit_stone_label: Label = $SpiritStone
@onready var item_list: ItemList = $ItemList
@onready var buy_btn: Button = $BuyButton
@onready var back_btn: Button = $BackButton

var selected_item: String = ""

func _ready() -> void:
	buy_btn.pressed.connect(_on_buy_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	item_list.item_selected.connect(_on_item_selected)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = ShopSystem.get_shop_level()
	level_label.text = "等级: %d" % level
	
	# 更新灵石显示
	spirit_stone_label.text = "灵石: %d" % GameManager.storage.get("spirit_stone", 0)
	
	# 更新商品列表
	item_list.clear()
	var items = ShopSystem.get_unlocked_items()
	for item_id in items:
		var item = ShopSystem.get_item_data(item_id)
		var price = item.get("price", 0)
		item_list.add_item("%s - %d灵石" % [item.get("name", item_id), price])

func _on_item_selected(index: int) -> void:
	var items = ShopSystem.get_unlocked_items()
	if index < items.size():
		selected_item = items[index]

func _on_buy_pressed() -> void:
	if selected_item == "":
		return
	
	if ShopSystem.purchase_item(selected_item):
		print("[ShopPanel] 购买成功: %s" % selected_item)
		_update_ui()
	else:
		print("[ShopPanel] 购买失败")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
