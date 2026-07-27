## 战斗反馈系统 - 自动加载单例
## 管理屏幕震动、受击闪红、暴击特效等战斗反馈
extends Node

# 屏幕震动配置
const SHAKE_DECAY: float = 5.0
const SHAKE_DEFAULT_INTENSITY: float = 5.0
const SHAKE_CRIT_INTENSITY: float = 10.0
const SHAKE_BOSS_INTENSITY: float = 15.0

# 受击闪红配置
const HIT_FLASH_DURATION: float = 0.15
const HIT_FLASH_COLOR: Color = Color(1, 0.3, 0.3, 0.5)

# 当前震动状态
var shake_intensity: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

# 引用
var _camera: Camera2D = null
var _canvas_layer: CanvasLayer = null

signal screen_shake_started(intensity: float)
signal screen_shake_ended()
signal hit_flash_started()
signal hit_flash_ended()
signal crit_effect_triggered(position: Vector2, damage: int)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# 处理屏幕震动
	if shake_intensity > 0:
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = max(0, shake_intensity - SHAKE_DECAY * delta)
		if _camera:
			_camera.offset = shake_offset
		if shake_intensity <= 0:
			shake_offset = Vector2.ZERO
			if _camera:
				_camera.offset = Vector2.ZERO
			screen_shake_ended.emit()

## 设置摄像机引用
func set_camera(camera: Camera2D) -> void:
	_camera = camera

## 触发屏幕震动
func shake_screen(intensity: float = SHAKE_DEFAULT_INTENSITY) -> void:
	shake_intensity = intensity
	screen_shake_started.emit(intensity)

## 触发普通攻击震动
func shake_on_hit() -> void:
	shake_screen(SHAKE_DEFAULT_INTENSITY)

## 触发暴击震动
func shake_on_crit() -> void:
	shake_screen(SHAKE_CRIT_INTENSITY)

## 触发Boss攻击震动
func shake_on_boss_hit() -> void:
	shake_screen(SHAKE_BOSS_INTENSITY)

## 显示伤害数字
func show_damage_number(parent: Node, world_pos: Vector2, damage: int, is_crit: bool = false, is_heal: bool = false) -> void:
	var type = "normal"
	if is_crit:
		type = "crit"
		shake_on_crit()
		crit_effect_triggered.emit(world_pos, damage)
	elif is_heal:
		type = "heal"
	DamageNumber.spawn(parent, world_pos, damage, type)

## 显示护盾吸收数字
func show_shield_number(parent: Node, world_pos: Vector2, absorbed: int) -> void:
	DamageNumber.spawn(parent, world_pos, absorbed, "shield")

## 触发受击闪红效果
func flash_hit_effect(player: Node) -> void:
	if not player or not player is CanvasItem:
		return
	hit_flash_started.emit()
	# 保存原始颜色
	var original_color = player.modulate
	# 闪红
	player.modulate = HIT_FLASH_COLOR
	# 等待后恢复
	await get_tree().create_timer(HIT_FLASH_DURATION).timeout
	if player and is_instance_valid(player):
		player.modulate = original_color
	hit_flash_ended.emit()

## 触发全屏变暗效果（技能释放时）
func flash_screen_dark(duration: float = 0.2) -> void:
	if not _canvas_layer:
		_canvas_layer = CanvasLayer.new()
		_canvas_layer.layer = 50
		add_child(_canvas_layer)
	
	var color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0.3)
	color_rect.size = get_viewport().get_visible_rect().size
	_canvas_layer.add_child(color_rect)
	
	# 淡入淡出
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(color_rect.queue_free)

## 触发Boss破绽提示
func show_vulnerability_prompt(parent: Node, position: Vector2) -> void:
	var label = Label.new()
	label.text = "破绽！"
	label.add_theme_font_size_override("font_size", 48)
	label.modulate = Color.GOLD
	label.position = position - Vector2(50, 30)
	label.z_index = 200
	parent.add_child(label)
	
	# 动画效果
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

## 触发阶段转换提示
func show_phase_transition(parent: Node, text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 36)
	label.modulate = Color.WHITE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 居中显示
	var viewport_size = get_viewport().get_visible_rect().size
	label.position = Vector2(viewport_size.x / 2 - 150, viewport_size.y / 2 - 20)
	label.z_index = 200
	parent.add_child(label)
	
	# 动画效果
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

## 序列化
func serialize() -> Dictionary:
	return {}

## 反序列化
func deserialize(_data: Dictionary) -> void:
	pass
