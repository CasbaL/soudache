## 暂停菜单
## 半透明遮罩 + 恢复/退出按钮
extends CanvasLayer

# 子节点引用
@onready var overlay: ColorRect = $Overlay
@onready var panel: VBoxContainer = $Overlay/Panel
@onready var title: Label = $Overlay/Panel/Title
@onready var resume_btn: Button = $Overlay/Panel/ResumeButton
@onready var quit_btn: Button = $Overlay/Panel/QuitButton

func _ready() -> void:
	# 默认隐藏
	visible = false
	
	# 设置遮罩
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 标题
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	
	# 恢复按钮
	resume_btn.text = "恢复游戏"
	resume_btn.pressed.connect(_on_resume_pressed)
	
	# 退出按钮
	quit_btn.text = "退出游戏"
	quit_btn.pressed.connect(_on_quit_pressed)
	
	# 连接游戏状态信号
	GameManager.game_state_changed.connect(_on_game_state_changed)

## 游戏状态变化
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			show_menu()
		GameManager.GameState.PLAYING:
			hide_menu()

## 显示菜单
func show_menu() -> void:
	visible = true

## 隐藏菜单
func hide_menu() -> void:
	visible = false

## 恢复按钮按下
func _on_resume_pressed() -> void:
	GameManager.resume_game()

## 退出按钮按下
func _on_quit_pressed() -> void:
	get_tree().quit()

## 输入处理
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			GameManager.resume_game()
		elif GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
