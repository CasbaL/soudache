## 装备界面（优化版）
## 显示装备槽位、属性、套装效果、强化预览
extends Control

# 颜色常量
const COLOR_TITLE: Color = Color(0.9, 0.8, 0.5)
const COLOR_STAT: Color = Color(0.7, 0.85, 1.0)
const COLOR_SET_BONUS: Color = Color(0.3, 0.9, 0.5)
const COLOR_ENHANCE: Color = Color(0.9, 0.7, 0.3)
const COLOR_EMPTY: Color = Color(0.5, 0.5, 0.5)

# 装备品质颜色
const RARITY_COLORS: Dictionary = {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
	"legendary": Color(1.0, 0.7, 0.2),
}

@onready var weapon_slot: Button = $EquipmentSlots/WeaponSlot
@onready var armor_slot: Button = $EquipmentSlots/ArmorSlot
@onready var helmet_slot: Button = $EquipmentSlots/HelmetSlot
@onready var accessory1_slot: Button = $EquipmentSlots/Accessory1Slot
@onready var accessory2_slot: Button = $EquipmentSlots/Accessory2Slot
@onready var stats_label: Label = $StatsLabel
@onready var back_btn: Button = $BackButton

# 新增 UI 元素
var title_label: Label = null
var combat_power_label: Label = null
var set_bonus_label: Label = null
var enhance_preview_label: Label = null
var slot_buttons: Dictionary = {}

func _ready() -> void:
	weapon_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.WEAPON))
	armor_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.ARMOR))
	helmet_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.HELMET))
	accessory1_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.ACCESSORY_1))
	accessory2_slot.pressed.connect(_on_slot_pressed.bind(EquipmentSystem.Slot.ACCESSORY_2))
	back_btn.pressed.connect(_on_back_pressed)

	# 记录槽位按钮
	slot_buttons = {
		EquipmentSystem.Slot.WEAPON: weapon_slot,
		EquipmentSystem.Slot.ARMOR: armor_slot,
		EquipmentSystem.Slot.HELMET: helmet_slot,
		EquipmentSystem.Slot.ACCESSORY_1: accessory1_slot,
		EquipmentSystem.Slot.ACCESSORY_2: accessory2_slot,
	}

	# 创建增强 UI
	_create_enhanced_ui()

	# 更新 UI
	_update_ui()

## 创建增强 UI
func _create_enhanced_ui() -> void:
	# 标题
	title_label = Label.new()
	title_label.text = "装备"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", COLOR_TITLE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$MainContainer.add_child(title_label)

	# 战斗力
	combat_power_label = Label.new()
	combat_power_label.add_theme_font_size_override("font_size", 16)
	combat_power_label.add_theme_color_override("font_color", COLOR_STAT)
	combat_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$MainContainer.add_child(combat_power_label)

	# 套装效果
	set_bonus_label = Label.new()
	set_bonus_label.name = "SetBonus"
	set_bonus_label.add_theme_font_size_override("font_size", 12)
	set_bonus_label.add_theme_color_override("font_color", COLOR_SET_BONUS)
	set_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$MainContainer.add_child(set_bonus_label)

	# 强化预览
	enhance_preview_label = Label.new()
	enhance_preview_label.name = "EnhancePreview"
	enhance_preview_label.add_theme_font_size_override("font_size", 11)
	enhance_preview_label.add_theme_color_override("font_color", COLOR_ENHANCE)
	enhance_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enhance_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$MainContainer.add_child(enhance_preview_label)

## 更新 UI
func _update_ui() -> void:
	# 更新装备槽显示
	_update_slot_display(weapon_slot, EquipmentSystem.Slot.WEAPON, "武器")
	_update_slot_display(armor_slot, EquipmentSystem.Slot.ARMOR, "防具")
	_update_slot_display(helmet_slot, EquipmentSystem.Slot.HELMET, "头饰")
	_update_slot_display(accessory1_slot, EquipmentSystem.Slot.ACCESSORY_1, "饰品1")
	_update_slot_display(accessory2_slot, EquipmentSystem.Slot.ACCESSORY_2, "饰品2")

	# 更新属性显示
	_update_stats()

	# 更新战斗力
	_update_combat_power()

	# 更新套装效果
	_update_set_bonus()

	# 更新强化预览
	_update_enhance_preview()

## 更新装备槽显示
func _update_slot_display(slot_btn: Button, slot: int, slot_name: String) -> void:
	var equipped = EquipmentSystem.get_equipped(slot)
	if equipped:
		var rarity_color = RARITY_COLORS.get(equipped.get("rarity", "common"), COLOR_EMPTY)
		var enhance_text = ""
		if equipped.get("enhance_level", 0) > 0:
			enhance_text = " +%d" % equipped.enhance_level
		slot_btn.text = "%s: %s%s" % [slot_name, equipped.name, enhance_text]
		slot_btn.modulate = rarity_color
	else:
		slot_btn.text = "%s: 空" % slot_name
		slot_btn.modulate = COLOR_EMPTY

## 更新属性显示
func _update_stats() -> void:
	var stats = EquipmentSystem.get_total_stats()
	var base_attack = GameManager.player_data.attack
	var base_defense = GameManager.player_data.defense
	var base_health = GameManager.player_data.max_health
	var base_crit = GameManager.player_data.crit_rate

	stats_label.text = """属性:
攻击力: %d (+%d)
防御力: %d (+%d)
生命值: %d (+%d)
暴击率: %d%% (+%d%%)
闪避率: %d%%""" % [
		base_attack + stats.attack, stats.attack,
		base_defense + stats.defense, stats.defense,
		base_health + stats.health, stats.health,
		int((base_crit + stats.crit_rate) * 100), int(stats.crit_rate * 100),
		int(stats.dodge_rate * 100)
	]

## 更新战斗力
func _update_combat_power() -> void:
	if not combat_power_label:
		return
	var cp = GameManager.get_combat_power()
	combat_power_label.text = "战斗力: %d" % cp

## 更新套装效果
func _update_set_bonus() -> void:
	if not set_bonus_label:
		return
	set_bonus_label.text = "套装效果: 开发中"
	set_bonus_label.modulate = COLOR_EMPTY

## 更新强化预览
func _update_enhance_preview() -> void:
	if not enhance_preview_label:
		return
	enhance_preview_label.text = "强化系统: 开发中"

## 槽位点击
func _on_slot_pressed(slot: int) -> void:
	print("[EquipmentPanel] 点击槽位: %d" % slot)
	# 这里可以打开装备选择界面

## 返回
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
