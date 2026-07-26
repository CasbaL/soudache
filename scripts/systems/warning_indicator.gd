## 攻击预警指示器
## 在Boss攻击前显示危险区域
class_name WarningIndicator
extends Node2D

# 预警类型枚举
enum WarningType {
	CIRCLE,    # 圆形（即时攻击）
	FAN,       # 扇形（扇形扫射）
	LINE,      # 直线（弹幕轨迹）
	RECTANGLE, # 矩形（直线AOE）
}

# 预警颜色配置
const WARNING_COLORS = {
	"instant": Color(1.0, 0.2, 0.2, 0.5),   # 红色 - 即时攻击
	"fan": Color(1.0, 0.2, 0.2, 0.4),       # 红色 - 扇形
	"line": Color(1.0, 0.2, 0.2, 0.4),      # 红色 - 直线
	"area": Color(0.7, 0.2, 1.0, 0.4),      # 紫色 - 持续区域
	"control": Color(1.0, 0.9, 0.2, 0.4),   # 黄色 - 控制技能
}

# 属性
var warning_type: WarningType = WarningType.CIRCLE
var warning_color_key: String = "instant"
var duration: float = 0.5
var damage: int = 100

# 圆形参数
var radius: float = 80.0

# 扇形参数
var fan_angle: float = 120.0  # 扇形角度
var fan_range: float = 200.0  # 扇形半径
var fan_direction: Vector2 = Vector2.RIGHT

# 直线参数
var line_width: float = 30.0
var line_length: float = 300.0
var line_direction: Vector2 = Vector2.RIGHT

# 矩形参数
var rect_size: Vector2 = Vector2(200, 100)

# 内部变量
var _time_elapsed: float = 0.0
var _alpha_multiplier: float = 0.0
var _triggered: bool = false
var _damage_applied: bool = false

# 回调
var on_warning_end: Callable = Callable()

func _ready() -> void:
	# 设置z索引确保在最上层显示
	z_index = 100

func _process(delta: float) -> void:
	_time_elapsed += delta
	
	# 计算透明度（逐渐显现）
	_alpha_multiplier = min(_time_elapsed / duration, 1.0)
	queue_redraw()
	
	# 预警时间结束
	if _time_elapsed >= duration and not _triggered:
		_triggered = true
		_on_warning_complete()

func _draw() -> void:
	var base_color = WARNING_COLORS.get(warning_color_key, WARNING_COLORS["instant"])
	var draw_color = Color(base_color.r, base_color.g, base_color.b, base_color.a * _alpha_multiplier)
	var border_color = Color(base_color.r, base_color.g, base_color.b, min(base_color.a * _alpha_multiplier * 2, 0.8))
	
	match warning_type:
		WarningType.CIRCLE:
			_draw_circle_warning(draw_color, border_color)
		WarningType.FAN:
			_draw_fan_warning(draw_color, border_color)
		WarningType.LINE:
			_draw_line_warning(draw_color, border_color)
		WarningType.RECTANGLE:
			_draw_rect_warning(draw_color, border_color)

## 绘制圆形预警
func _draw_circle_warning(fill_color: Color, border_color: Color) -> void:
	# 填充
	draw_circle(Vector2.ZERO, radius, fill_color)
	# 边框（32段近似圆）
	var points = PackedVector2Array()
	for i in 33:
		var angle = (TAU / 32) * i
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_polyline(points, border_color, 2.0)
	# 中心十字
	var cross_size = radius * 0.3
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), border_color, 1.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), border_color, 1.0)

## 绘制扇形预警
func _draw_fan_warning(fill_color: Color, border_color: Color) -> void:
	var half_angle_rad = deg_to_rad(fan_angle / 2.0)
	var start_angle = fan_direction.angle() - half_angle_rad
	var segments = 24
	var points = PackedVector2Array()
	
	# 中心点
	points.append(Vector2.ZERO)
	
	# 扇形弧线点
	for i in segments + 1:
		var angle = start_angle + (fan_angle / segments) * i
		points.append(Vector2(cos(angle), sin(angle)) * fan_range)
	
	# 绘制填充
	draw_colored_polygon(points, fill_color)
	# 绘制边框
	points.append(Vector2.ZERO)
	draw_polyline(points, border_color, 2.0)
	
	# 绘制方向指示线
	var dir_line_len = fan_range * 0.8
	draw_line(Vector2.ZERO, fan_direction * dir_line_len, border_color, 1.5)

## 绘制直线预警
func _draw_line_warning(fill_color: Color, border_color: Color) -> void:
	var half_width = line_width / 2.0
	var dir = line_direction.normalized()
	var perp = Vector2(-dir.y, dir.x)
	
	# 线条区域
	var rect = Rect2(
		dir * -10 - perp * half_width,
		Vector2(line_length + 10, line_width)
	)
	
	# 旋转绘制
	var transform = Transform2D(dir.angle(), Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, dir.angle(), Vector2.ONE)
	
	# 填充
	draw_rect(Rect2(Vector2(-10, -half_width), Vector2(line_length + 10, line_width)), fill_color)
	# 边框
	draw_rect(Rect2(Vector2(-10, -half_width), Vector2(line_length + 10, line_width)), border_color, false, 2.0)
	# 中心线
	draw_line(Vector2(0, 0), Vector2(line_length, 0), border_color, 1.0)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

## 绘制矩形预警
func _draw_rect_warning(fill_color: Color, border_color: Color) -> void:
	var half_size = rect_size / 2.0
	# 填充
	draw_rect(Rect2(-half_size, rect_size), fill_color)
	# 边框
	draw_rect(Rect2(-half_size, rect_size), border_color, false, 2.0)
	# 对角线
	draw_line(-half_size, half_size, border_color, 1.0)
	draw_line(Vector2(half_size.x, -half_size.y), Vector2(-half_size.x, half_size.y), border_color, 1.0)

## 预警完成回调
func _on_warning_complete() -> void:
	# 应用伤害
	if damage > 0 and not _damage_applied:
		_damage_applied = true
		_apply_warning_damage()
	
	# 调用外部回调
	if on_warning_end.is_valid():
		on_warning_end.call()
	
	# 短暂显示后消失
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

## 对区域内的玩家造成伤害
func _apply_warning_damage() -> void:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if not player.has_method("take_damage"):
			continue
		
		var player_pos = player.global_position
		var dist = global_position.distance_to(player_pos)
		
		match warning_type:
			WarningType.CIRCLE:
				if dist <= radius:
					player.take_damage(damage)
			WarningType.FAN:
				if dist <= fan_range:
					var to_player = (player_pos - global_position).normalized()
					var angle_diff = rad_to_deg(fan_direction.angle_to(to_player))
					if abs(angle_diff) <= fan_angle / 2.0:
						player.take_damage(damage)
			WarningType.LINE:
				var dir = line_direction.normalized()
				var to_player = player_pos - global_position
				var proj_length = to_player.dot(dir)
				if proj_length >= 0 and proj_length <= line_length:
					var perp_dist = abs(to_player.dot(Vector2(-dir.y, dir.x)))
					if perp_dist <= line_width / 2.0:
						player.take_damage(damage)
			WarningType.RECTANGLE:
				var half_size = rect_size / 2.0
				var local_pos = player_pos - global_position
				if abs(local_pos.x) <= half_size.x and abs(local_pos.y) <= half_size.y:
					player.take_damage(damage)

## 工厂方法：创建圆形预警
static func create_circle(parent: Node, pos: Vector2, r: float, warn_duration: float = 0.5, dmg: int = 100, color_key: String = "instant") -> WarningIndicator:
	var indicator = WarningIndicator.new()
	indicator.position = pos
	indicator.warning_type = WarningType.CIRCLE
	indicator.radius = r
	indicator.duration = warn_duration
	indicator.damage = dmg
	indicator.warning_color_key = color_key
	parent.add_child(indicator)
	return indicator

## 工厂方法：创建扇形预警
static func create_fan(parent: Node, pos: Vector2, dir: Vector2, angle: float, r: float, warn_duration: float = 0.8, dmg: int = 100, color_key: String = "fan") -> WarningIndicator:
	var indicator = WarningIndicator.new()
	indicator.position = pos
	indicator.warning_type = WarningType.FAN
	indicator.fan_direction = dir.normalized()
	indicator.fan_angle = angle
	indicator.fan_range = r
	indicator.duration = warn_duration
	indicator.damage = dmg
	indicator.warning_color_key = color_key
	parent.add_child(indicator)
	return indicator

## 工厂方法：创建直线预警
static func create_line(parent: Node, pos: Vector2, dir: Vector2, length: float, width: float = 30.0, warn_duration: float = 0.3, dmg: int = 100, color_key: String = "line") -> WarningIndicator:
	var indicator = WarningIndicator.new()
	indicator.position = pos
	indicator.warning_type = WarningType.LINE
	indicator.line_direction = dir.normalized()
	indicator.line_length = length
	indicator.line_width = width
	indicator.duration = warn_duration
	indicator.damage = dmg
	indicator.warning_color_key = color_key
	parent.add_child(indicator)
	return indicator

## 工厂方法：创建矩形预警
static func create_rectangle(parent: Node, pos: Vector2, size: Vector2, warn_duration: float = 0.5, dmg: int = 100, color_key: String = "instant") -> WarningIndicator:
	var indicator = WarningIndicator.new()
	indicator.position = pos
	indicator.warning_type = WarningType.RECTANGLE
	indicator.rect_size = size
	indicator.duration = warn_duration
	indicator.damage = dmg
	indicator.warning_color_key = color_key
	parent.add_child(indicator)
	return indicator
