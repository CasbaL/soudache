## 新手教程系统
## 引导玩家了解游戏操作和机制
class_name TutorialSystem
extends CanvasLayer

# 教程步骤
enum TutorialStep {
	NONE,
	SELECT_FACTION,     # 选择门派
	VISIT_HAVEN,        # 了解洞府
	CLICK_EXPLORE,      # 点击出发
	USE_JOYSTICK,       # 使用摇杆移动
	Auto_ATTACK,        # 自动攻击
	USE_SKILL,          # 使用技能
	USE_DODGE,          # 使用闪避
	FIND_EXTRACT,       # 找到撤离点
	RETURN_HAVEN,       # 返回洞府
	BUILD_UPGRADE,      # 建造升级
	COMPLETE,           # 完成教程
}

# 当前步骤
var current_step: TutorialStep = TutorialStep.NONE
var is_active: bool = false

# 教程UI元素
var _overlay: ColorRect
var _highlight: ColorRect
var _label: Label
var _arrow: ColorRect
var _skip_button: Button

# 步骤数据
const STEP_DATA: Dictionary = {
	TutorialStep.SELECT_FACTION: {
		"text": "选择你喜欢的门派",
		"highlight": "CardSword",
		"position": "center",
	},
	TutorialStep.VISIT_HAVEN: {
		"text": "这是你的洞府，可以建造和升级",
		"highlight": "",
		"position": "top",
	},
	TutorialStep.CLICK_EXPLORE: {
		"text": "点击出发按钮开始探索",
		"highlight": "ExploreButton",
		"position": "bottom",
	},
	TutorialStep.USE_JOYSTICK: {
		"text": "拖动左侧摇杆移动角色",
		"highlight": "VirtualJoystick",
		"position": "bottom_left",
	},
	TutorialStep.Auto_ATTACK: {
		"text": "角色会自动攻击附近的敌人",
		"highlight": "",
		"position": "center",
	},
	TutorialStep.USE_SKILL: {
		"text": "点击技能按钮释放技能",
		"highlight": "SkillBar",
		"position": "bottom",
	},
	TutorialStep.USE_DODGE: {
		"text": "点击闪避按钮躲避攻击",
		"highlight": "DodgeButton",
		"position": "bottom_right",
	},
	TutorialStep.FIND_EXTRACT: {
		"text": "找到撤离点可以保存物资",
		"highlight": "",
		"position": "center",
	},
	TutorialStep.RETURN_HAVEN: {
		"text": "成功撤离！返回洞府继续成长",
		"highlight": "",
		"position": "center",
	},
	TutorialStep.BUILD_UPGRADE: {
		"text": "在洞府中建造和升级建筑",
		"highlight": "BuildingGrid",
		"position": "center",
	},
}

signal tutorial_started()
signal tutorial_step_changed(step: TutorialStep)
signal tutorial_completed()
signal tutorial_skipped()

func _ready() -> void:
	layer = 200  # 确保在最上层
	_create_ui()
	visible = false

## 创建教程UI
func _create_ui() -> void:
	# 半透明遮罩
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.5)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# 高亮区域
	_highlight = ColorRect.new()
	_highlight.color = Color(1, 1, 0, 0.3)
	_highlight.visible = false
	add_child(_highlight)

	# 文字说明
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.size = Vector2(500, 100)
	_label.position = Vector2(-250, -150)
	add_child(_label)

	# 跳过按钮
	_skip_button = Button.new()
	_skip_button.text = "跳过教程"
	_skip_button.position = Vector2(600, 20)
	_skip_button.size = Vector2(100, 40)
	_skip_button.pressed.connect(_on_skip_pressed)
	add_child(_skip_button)

## 开始教程
func start_tutorial() -> void:
	if _is_tutorial_completed():
		return
	is_active = true
	visible = true
	_set_step(TutorialStep.SELECT_FACTION)
	tutorial_started.emit()

## 设置当前步骤
func _set_step(step: TutorialStep) -> void:
	current_step = step
	var data = STEP_DATA.get(step, {})
	_label.text = data.get("text", "")
	_update_highlight(data.get("highlight", ""))
	tutorial_step_changed.emit(step)

## 更新高亮区域
func _update_highlight(target_name: String) -> void:
	if target_name == "":
		_highlight.visible = false
		return

	# 在当前场景中查找目标节点
	var target = get_tree().current_scene.get_node_or_null(target_name)
	if target == null:
		_highlight.visible = false
		return

	_highlight.visible = true
	_highlight.global_position = target.global_position
	_highlight.size = target.size

## 进入下一步
func next_step() -> void:
	var next = current_step + 1
	if next > TutorialStep.COMPLETE:
		_complete_tutorial()
	else:
		_set_step(next)

## 完成教程
func _complete_tutorial() -> void:
	is_active = false
	visible = false
	_save_tutorial_completion()
	tutorial_completed.emit()

## 跳过教程
func _on_skip_pressed() -> void:
	is_active = false
	visible = false
	_save_tutorial_completion()
	tutorial_skipped.emit()

## 保存教程完成状态
func _save_tutorial_completion() -> void:
	var config = ConfigFile.new()
	config.set_value("tutorial", "completed", true)
	config.save("user://tutorial.cfg")

## 检查教程是否已完成
func _is_tutorial_completed() -> bool:
	var config = ConfigFile.new()
	if config.load("user://tutorial.cfg") == OK:
		return config.get_value("tutorial", "completed", false)
	return false

## 重置教程（用于测试）
func reset_tutorial() -> void:
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("tutorial.cfg"):
		dir.remove("tutorial.cfg")
