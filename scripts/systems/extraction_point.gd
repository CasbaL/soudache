## 撤离点
## 玩家可以在此撤离，保留当前物资
class_name ExtractionPoint
extends Area2D

# 撤离参数
@export var extract_time: float = 3.0
@export var can_extract: bool = true

# 状态
var is_extracting: bool = false
var extract_progress: float = 0.0
var player_in_range: bool = false

# 信号
signal extract_started()
signal extract_progress_changed(progress: float)
signal extract_completed()
signal extract_cancelled()

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var extract_timer: Timer = $ExtractTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# 初始化
	progress_bar.visible = false
	progress_bar.max_value = 100
	progress_bar.value = 0
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	extract_timer.timeout.connect(_on_extract_timer_timeout)
	
	# 设置计时器
	extract_timer.wait_time = extract_time
	extract_timer.one_shot = true
	
	# 设置碰撞层
	collision_layer = 0  # 无碰撞
	collision_mask = 1   # 检测玩家
	
	# 播放待机动画（如果存在）
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

func _process(_delta: float) -> void:
	if is_extracting:
		# 更新进度
		extract_progress = (1.0 - extract_timer.time_left / extract_time) * 100
		progress_bar.value = extract_progress
		extract_progress_changed.emit(extract_progress)

## 开始撤离
func start_extract() -> void:
	if not can_extract or is_extracting:
		return
	
	is_extracting = true
	extract_progress = 0.0
	progress_bar.visible = true
	progress_bar.value = 0
	
	extract_timer.start()
	extract_started.emit()
	
	# 播放撤离动画（如果存在）
	if animation_player.has_animation("extracting"):
		animation_player.play("extracting")
	
	print("开始撤离...")

## 取消撤离
func cancel_extract() -> void:
	if not is_extracting:
		return
	
	is_extracting = false
	extract_progress = 0.0
	progress_bar.visible = false
	
	extract_timer.stop()
	extract_cancelled.emit()
	
	# 播放待机动画（如果存在）
	if animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	print("撤离取消")

## 完成撤离
func complete_extract() -> void:
	is_extracting = false
	progress_bar.visible = false
	
	extract_completed.emit()
	
	# 通知游戏管理器
	GameManager.victory()
	
	print("撤离成功！")

## 玩家进入范围
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		
		if can_extract:
			# 显示提示
			show_extract_prompt()
			
			# 自动开始撤离
			start_extract()

## 玩家离开范围
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		
		if is_extracting:
			cancel_extract()

## 撤离计时器超时
func _on_extract_timer_timeout() -> void:
	complete_extract()

## 显示撤离提示
func show_extract_prompt() -> void:
	# TODO: 显示UI提示
	print("进入撤离点，开始撤离...")
