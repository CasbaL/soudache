## 可复用血量条组件
## 支持平滑过渡和颜色变化
extends Control

# 子节点引用
@onready var bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

# 当前值（用于平滑过渡）
var _current_value: float = 0.0
var _max_value: float = 100.0

func _ready() -> void:
	# 初始化进度条
	bar.show_percentage = false
	bar.min_value = 0
	
	# 初始化标签
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)

## 设置血量（平滑过渡）
func set_health(current: int, max_val: int) -> void:
	_max_value = max_val
	bar.max_value = max_val
	
	# 平滑过渡
	var tween = create_tween()
	tween.tween_property(bar, "value", float(current), 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	_current_value = current
	label.text = "%d / %d" % [current, max_val]
	
	# 更新颜色
	_update_color(float(current) / float(max_val))

## 立即设置血量（无动画）
func set_health_instant(current: int, max_val: int) -> void:
	_max_value = max_val
	_current_value = current
	bar.max_value = max_val
	bar.value = current
	label.text = "%d / %d" % [current, max_val]
	_update_color(float(current) / float(max_val))

## 根据百分比更新颜色
func _update_color(percent: float) -> void:
	if percent > 0.6:
		bar.modulate = Color.GREEN
	elif percent > 0.3:
		bar.modulate = Color.YELLOW
	else:
		bar.modulate = Color.RED
