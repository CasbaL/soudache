## 传送阵界面
## 显示传送点列表，传送到指定位置
extends Control

@onready var level_label: Label = $Level
@onready var teleport_list: ItemList = $TeleportList
@onready var teleport_btn: Button = $TeleportButton
@onready var back_btn: Button = $BackButton

var selected_point: String = ""

func _ready() -> void:
	teleport_btn.pressed.connect(_on_teleport_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	teleport_list.item_selected.connect(_on_point_selected)
	
	_update_ui()

func _update_ui() -> void:
	# 更新等级显示
	var level = PortalSystem.get_portal_level()
	level_label.text = "等级: %d" % level
	
	# 更新传送点列表
	teleport_list.clear()
	var points = PortalSystem.get_all_points()
	for point_id in points:
		var point = PortalSystem.get_point_data(point_id)
		var status = ""
		if PortalSystem.is_unlocked(point_id):
			status = " [已解锁]"
			if PortalSystem.can_teleport(point_id):
				status += " [可传送]"
		else:
			status = " [未解锁]"
		teleport_list.add_item("%s%s" % [point.get("name", point_id), status])

func _on_point_selected(index: int) -> void:
	var points = PortalSystem.get_all_points()
	var point_ids = points.keys()
	if index < point_ids.size():
		selected_point = point_ids[index]

func _on_teleport_pressed() -> void:
	if selected_point == "":
		return
	
	if PortalSystem.teleport(selected_point):
		print("[PortalPanel] 传送成功: %s" % selected_point)
		get_tree().change_scene_to_file("res://scenes/levels/open_world.tscn")
	else:
		print("[PortalPanel] 传送失败")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
