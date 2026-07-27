## 场景管理器 - 自动加载单例
## 管理场景切换，支持淡入淡出过渡
extends Node

signal scene_changed(scene_path: String)

var _overlay: ColorRect
var _tween: Tween
var _is_transitioning: bool = false

func _ready() -> void:
	# 创建全屏黑色遮罩，确保在最上层
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	canvas.add_child(_overlay)

## 是否正在过渡中
func is_transitioning() -> bool:
	return _is_transitioning

## 带淡入淡出的场景切换
func change_scene(path: String, fade_duration: float = 0.3) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	await _fade_out(fade_duration)
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("场景切换失败: %s (错误码: %d)" % [path, error])
		_is_transitioning = false
		return

	# 等一帧让新场景完成加载
	await get_tree().process_frame
	await _fade_in(fade_duration)

	_is_transitioning = false
	scene_changed.emit(path)

## 立即切换场景（无过渡）
func change_scene_immediate(path: String) -> void:
	get_tree().change_scene_to_file(path)
	scene_changed.emit(path)

## 淡出（变黑）
func _fade_out(duration: float) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止过渡中输入
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 1.0, duration)
	await _tween.finished

## 淡入（变透明）
func _fade_in(duration: float) -> void:
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 0.0, duration)
	await _tween.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 恢复输入穿透
