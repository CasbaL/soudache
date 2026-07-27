## 修炼界面
## 显示境界信息，突破境界
extends Control

@onready var level_label: Label = $Level
@onready var current_realm_label: Label = $CurrentRealm
@onready var realm_bonus_label: Label = $RealmBonus
@onready var breakthrough_btn: Button = $BreakthroughButton
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	breakthrough_btn.pressed.connect(_on_breakthrough_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = BuildingSystem.get_building_level("training_room")
	level_label.text = "等级: %d" % level
	
	# 更新境界显示
	var realm_name = RealmSystem.get_realm_name()
	current_realm_label.text = "当前境界: %s" % realm_name
	
	# 更新境界加成显示
	var bonus = RealmSystem.get_realm_bonus()
	realm_bonus_label.text = """境界加成:
攻击: +%d
防御: +%d
生命: +%d""" % [bonus.attack, bonus.defense, bonus.health]
	
	# 更新突破按钮
	if RealmSystem.is_max_realm():
		breakthrough_btn.text = "已满级"
		breakthrough_btn.disabled = true
	else:
		var cost = RealmSystem.get_breakthrough_cost()
		var rate = RealmSystem.get_breakthrough_rate()
		breakthrough_btn.text = "突破 (%d%%成功率)" % int(rate * 100)
		breakthrough_btn.disabled = not RealmSystem.can_attempt_breakthrough()

func _on_breakthrough_pressed() -> void:
	if RealmSystem.attempt_breakthrough():
		print("[TrainingPanel] 突破成功!")
		_update_ui()
	else:
		print("[TrainingPanel] 突破失败")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
