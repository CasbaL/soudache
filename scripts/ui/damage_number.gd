## 浮动伤害数字
## 在世界坐标生成，上浮并淡出后自动释放
class_name DamageNumber
extends Label

# 飘字配置
var float_distance: float = 60.0
var float_duration: float = 0.8
var start_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 随机水平偏移，避免重叠
	start_offset.x = randf_range(-20, 20)
	position += start_offset
	
	# 创建上浮+淡出动画
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - float_distance, float_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, float_duration)\
		.set_delay(float_duration * 0.4)
	tween.chain().tween_callback(queue_free)

## 在世界坐标显示伤害数字（工厂方法）
## type: "normal" | "crit" | "heal" | "shield"
static func spawn(parent: Node, world_pos: Vector2, value: int, type: String = "normal") -> void:
	var dmg_label = Label.new()
	dmg_label.set_script(preload("res://scripts/ui/damage_number.gd"))
	
	match type:
		"normal":
			dmg_label.text = str(value)
			dmg_label.modulate = Color.WHITE
			dmg_label.add_theme_font_size_override("font_size", 22)
		"crit":
			dmg_label.text = str(value) + "!"
			dmg_label.modulate = Color.YELLOW
			dmg_label.add_theme_font_size_override("font_size", 33)  # 1.5x
		"heal":
			dmg_label.text = "+" + str(value)
			dmg_label.modulate = Color.GREEN
			dmg_label.add_theme_font_size_override("font_size", 22)
		"shield":
			dmg_label.text = str(value)
			dmg_label.modulate = Color(0.4, 0.7, 1.0)  # 蓝色
			dmg_label.add_theme_font_size_override("font_size", 22)
	
	dmg_label.global_position = world_pos
	dmg_label.z_index = 100
	
	# 添加到当前场景或指定父节点
	parent.add_child(dmg_label)
