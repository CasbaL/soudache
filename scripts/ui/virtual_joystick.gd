## 虚拟摇杆
## 左半屏触控，输出方向向量供 Player 读取
extends Control

signal joystick_input(direction: Vector2)

# 摇杆外观
@onready var outer_ring: TextureRect = $OuterRing
@onready var inner_knob: TextureRect = $InnerKnob

# 摇杆参数
@export var max_distance: float = 80.0
@export var dead_zone: float = 0.15

# 输出值（-1 到 1 的方向向量）
var output: Vector2 = Vector2.ZERO

# 触控状态
var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _is_active: bool = false

func _ready() -> void:
	# 初始隐藏摇杆部件
	if outer_ring:
		outer_ring.visible = false
	if inner_knob:
		inner_knob.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# 只响应左半屏的触控
			var viewport_w = get_viewport_rect().size.x
			if event.position.x < viewport_w * 0.5:
				_touch_index = event.index
				_origin = event.position
				_is_active = true
				_show_joystick(event.position)
		elif event.index == _touch_index:
			_release()

	elif event is InputEventScreenDrag and event.index == _touch_index:
		var delta = event.position - _origin
		var clamped = delta.limit_length(max_distance)
		var raw_output = clamped / max_distance

		# 死区处理
		if raw_output.length() < dead_zone:
			output = Vector2.ZERO
		else:
			output = raw_output

		_update_visuals(_origin + clamped)
		joystick_input.emit(output)

func _release() -> void:
	_touch_index = -1
	_is_active = false
	output = Vector2.ZERO
	_hide_joystick()
	joystick_input.emit(Vector2.ZERO)

func _show_joystick(center: Vector2) -> void:
	if outer_ring:
		outer_ring.visible = true
		outer_ring.global_position = center - outer_ring.size / 2
	if inner_knob:
		inner_knob.visible = true
		inner_knob.global_position = center - inner_knob.size / 2

func _hide_joystick() -> void:
	if outer_ring:
		outer_ring.visible = false
	if inner_knob:
		inner_knob.visible = false

func _update_visuals(knob_pos: Vector2) -> void:
	if inner_knob:
		inner_knob.global_position = knob_pos - inner_knob.size / 2

## 是否正在使用摇杆
func is_active() -> bool:
	return _is_active
