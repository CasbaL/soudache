## Boss血量条
## 全屏宽度显示在顶部，仅Boss战可见
extends CanvasLayer

# 子节点引用
@onready var bg: ColorRect = $BG
@onready var bar: ProgressBar = $BG/Bar
@onready var boss_name_label: Label = $BG/BossName
@onready var phase_label: Label = $BG/PhaseName

# Boss数据
var boss_max_health: float = 1.0

func _ready() -> void:
	# 默认隐藏
	visible = false
	
	# 设置样式
	bg.color = Color(0, 0, 0, 0.7)
	bar.show_percentage = false
	bar.modulate = Color.RED
	
	boss_name_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_font_size_override("font_size", 14)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

## 显示Boss血条
func show_boss(boss_name: String, max_health: int, phase_name: String = "阶段 1") -> void:
	boss_max_health = max_health
	bar.max_value = max_health
	bar.value = max_health
	boss_name_label.text = boss_name
	phase_label.text = phase_name
	visible = true

## 更新Boss血量
func update_health(current_health: int) -> void:
	var tween = create_tween()
	tween.tween_property(bar, "value", float(current_health), 0.2)\
		.set_ease(Tween.EASE_OUT)
	
	# 血量低时变色
	var percent = current_health / boss_max_health
	if percent < 0.3:
		bar.modulate = Color(1, 0.3, 0.3)  # 深红

## 更新阶段名称
func update_phase(phase_name: String) -> void:
	phase_label.text = phase_name
	
	# 阶段切换闪烁效果
	var tween = create_tween()
	tween.tween_property(phase_label, "modulate:a", 0.3, 0.1)
	tween.tween_property(phase_label, "modulate:a", 1.0, 0.1)
	tween.tween_property(phase_label, "modulate:a", 0.3, 0.1)
	tween.tween_property(phase_label, "modulate:a", 1.0, 0.1)

## 隐藏Boss血条
func hide_boss() -> void:
	visible = false
