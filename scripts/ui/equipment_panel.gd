## 装备界面
## 显示装备槽位和属性
extends Control

@onready var weapon_slot: Button = $EquipmentSlots/WeaponSlot
@onready var armor_slot: Button = $EquipmentSlots/ArmorSlot
@onready var helmet_slot: Button = $EquipmentSlots/HelmetSlot
@onready var accessory1_slot: Button = $EquipmentSlots/Accessory1Slot
@onready var accessory2_slot: Button = $EquipmentSlots/Accessory2Slot
@onready var stats_label: Label = $StatsLabel
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	weapon_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.WEAPON))
	armor_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.ARMOR))
	helmet_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.HELMET))
	accessory1_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.ACCESSORY_1))
	accessory2_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.ACCESSORY_2))
	back_btn.pressed.connect(_on_back_pressed)
	
	_update_ui()

func _update_ui() -> void:
	# 更新装备槽显示
	_update_slot_display(weapon_slot, EquipmentSystem.Slot.WEAPON, "武器")
	_update_slot_display(armor_slot, EquipmentSystem.Slot.ARMOR, "防具")
	_update_slot_display(helmet_slot, EquipmentSystem.Slot.HELMET, "头饰")
	_update_slot_display(accessory1_slot, EquipmentSystem.Slot.ACCESSORY_1, "饰品1")
	_update_slot_display(accessory2_slot, EquipmentSystem.Slot.ACCESSORY_2, "饰品2")
	
	# 更新属性显示
	var stats = EquipmentSystem.get_total_stats()
	stats_label.text = """属性:
攻击力: %d
防御力: %d
生命值: %d
暴击率: %d%%
闪避率: %d%%""" % [
		GameManager.player_data.attack + stats.attack,
		GameManager.player_data.defense + stats.defense,
		GameManager.player_data.max_health + stats.health,
		int((GameManager.player_data.crit_rate + stats.crit_rate) * 100),
		int(stats.dodge_rate * 100)
	]

func _update_slot_display(slot_btn: Button, slot: int, slot_name: String) -> void:
	var equipped = EquipmentSystem.get_equipped(slot)
	if equipped:
		slot_btn.text = "%s: %s +%d" % [slot_name, equipped.name, equipped.enhance_level]
	else:
		slot_btn.text = "%s: 空" % slot_name

func _on_slot_pressed(slot: int) -> void:
	print("[EquipmentPanel] 点击槽位: %d" % slot)
	# 这里可以打开装备选择界面

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
