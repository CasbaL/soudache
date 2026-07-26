## 装备界面
## 显示装备槽位、属性总览、强化操作
extends Control

var EquipmentDataScript = preload("res://scripts/systems/equipment_data.gd")

# 节点路径（需要在场景中创建对应节点或用代码生成）
@onready var slot_container: HFlowContainer = $SlotContainer
@onready var stats_label: Label = $StatsLabel
@onready var equip_button: Button = $ButtonBar/EquipButton
@onready var unequip_button: Button = $ButtonBar/UnequipButton
@onready var enhance_button: Button = $ButtonBar/EnhanceButton
@onready var success_rate_label: Label = $ButtonBar/SuccessRateLabel

var selected_slot: int = -1
var slot_buttons: Array[Button] = []

const SLOT_DISPLAY_NAMES := ["武器", "防具", "头饰", "饰品1", "饰品2"]

func _ready() -> void:
	_create_slot_buttons()
	# 连接信号
	EquipmentSystem.equipment_changed.connect(_on_equipment_changed)
	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	enhance_button.pressed.connect(_on_enhance_pressed)
	refresh()

## 生成 5 个槽位按钮
func _create_slot_buttons() -> void:
	for i in range(5):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.text = SLOT_DISPLAY_NAMES[i]
		btn.pressed.connect(_on_slot_clicked.bind(i))
		slot_container.add_child(btn)
		slot_buttons.append(btn)

## 刷新所有显示
func refresh() -> void:
	_update_slot_display()
	_update_stats_display()
	_update_action_buttons()

## 更新槽位按钮外观
func _update_slot_display() -> void:
	for i in range(5):
		var btn = slot_buttons[i]
		var item: EquipmentData = EquipmentSystem.get_equipped(i)
		if item:
			btn.text = "%s\n+%d" % [item.name, item.enhance_level]
			# 稀有度颜色边框
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.15, 0.15)
			style.border_color = item.get_rarity_color()
			style.set_border_width_all(2)
			style.corner_radius_top_left = 4
			style.corner_radius_top_right = 4
			style.corner_radius_bottom_left = 4
			style.corner_radius_bottom_right = 4
			btn.add_theme_stylebox_override("normal", style)
		else:
			btn.text = SLOT_DISPLAY_NAMES[i] + "\n[空]"
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.1, 0.1)
			style.border_color = Color(0.3, 0.3, 0.3)
			style.set_border_width_all(1)
			btn.add_theme_stylebox_override("normal", style)

		# 高亮选中
		if i == selected_slot:
			btn.modulate = Color(1.2, 1.2, 0.8)
		else:
			btn.modulate = Color.WHITE

## 更新属性总览
func _update_stats_display() -> void:
	var stats = EquipmentSystem.get_total_stats()
	stats_label.text = (
		"装备属性加成:\n"
		+ "  攻击: +%d\n" % int(stats.attack)
		+ "  防御: +%d\n" % int(stats.defense)
		+ "  生命: +%d\n" % int(stats.health)
		+ "  暴击率: +%.1f%%\n" % (stats.crit_rate * 100)
		+ "  暴击伤害: +%.1f%%\n" % (stats.crit_damage * 100)
		+ "  闪避率: +%.1f%%" % (stats.dodge_rate * 100)
	)

## 更新按钮状态和成功率显示
func _update_action_buttons() -> void:
	var has_selection := selected_slot >= 0
	var item: EquipmentData = null
	if has_selection:
		item = EquipmentSystem.get_equipped(selected_slot)

	equip_button.disabled = not has_selection
	unequip_button.disabled = (item == null)
	enhance_button.disabled = (item == null)

	if item and item.enhance_level < EnhanceSystem.SUCCESS_RATES.size():
		var rate = EnhanceSystem.get_success_rate(item.enhance_level)
		var cost = EnhanceSystem.get_material_cost(item.enhance_level)
		success_rate_label.text = "成功率: %.0f%%\n消耗: 灵石%d 器灵%d" % [
			rate * 100, cost.ling_shi, cost.qi_ling
		]
	else:
		success_rate_label.text = ""

## 槽位点击
func _on_slot_clicked(slot: int) -> void:
	selected_slot = slot
	refresh()

## 装备按钮（从背包装备到选中槽位）
func _on_equip_pressed() -> void:
	if selected_slot < 0:
		return
	# 从背包中找一个匹配类型的装备
	var expected_type = EquipmentSystem.SLOT_NAMES[selected_slot]
	for i in range(GameManager.inventory.size()):
		var item_dict: Dictionary = GameManager.inventory[i]
		if item_dict.get("type", "") == expected_type:
			var equip = EquipmentDataScript.new(item_dict)
			var old = EquipmentSystem.equip_item(equip, selected_slot)
			GameManager.remove_from_inventory(i)
			if old:
				GameManager.add_to_inventory(old.to_dict())
			refresh()
			return
	print("背包中没有匹配的 %s 装备" % expected_type)

## 卸下按钮
func _on_unequip_pressed() -> void:
	if selected_slot < 0:
		return
	var item = EquipmentSystem.unequip_item(selected_slot)
	if item:
		GameManager.add_to_inventory(item.to_dict())
	refresh()

## 强化按钮
func _on_enhance_pressed() -> void:
	if selected_slot < 0:
		return
	var item: EquipmentData = EquipmentSystem.get_equipped(selected_slot)
	if item == null:
		return
	var result = EnhanceSystem.enhance_equipment(item)
	if result.success:
		print("强化成功！+%d → +%d" % [result.old_level, result.new_level])
	else:
		print("强化失败！+%d → +%d" % [result.old_level, result.new_level])
	refresh()

## 装备变化回调
func _on_equipment_changed(_slot: int) -> void:
	refresh()
