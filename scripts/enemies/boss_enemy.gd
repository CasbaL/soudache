## Boss敌人基类
## 3阶段HP阈值机制，多攻击模式，召唤小怪
class_name BossEnemy
extends Enemy

# Boss阶段数据
@export var phases: Array[Dictionary] = [
	{"name": "阶段1", "healthRange": [100, 70], "attacks": []},
	{"name": "阶段2", "healthRange": [70, 40], "attacks": []},
	{"name": "阶段3", "healthRange": [40, 0], "attacks": []}
]

# Boss参数
@export var vulnerability_duration: float = 3.0
@export var phase_transition_pause: float = 2.0
@export var minion_scene_path: String = ""

# 状态
var current_phase: int = 0
var is_vulnerable: bool = false
var is_transitioning: bool = false
var current_attack_index: int = 0
var _base_defense: int = 0
var attack_pattern_timer: Timer
var vulnerability_timer: Timer
var phase_cooldown_timer: Timer

# 信号
signal phase_changed(new_phase: int, phase_name: String)
signal boss_announcement(text: String)
signal vulnerability_started()
signal vulnerability_ended()

func _ready() -> void:
	super._ready()
	_base_defense = defense
	
	# 创建计时器
	attack_pattern_timer = Timer.new()
	attack_pattern_timer.one_shot = true
	add_child(attack_pattern_timer)
	
	vulnerability_timer = Timer.new()
	vulnerability_timer.one_shot = true
	vulnerability_timer.wait_time = vulnerability_duration
	add_child(vulnerability_timer)
	vulnerability_timer.timeout.connect(_on_vulnerability_ended)
	
	phase_cooldown_timer = Timer.new()
	phase_cooldown_timer.one_shot = true
	add_child(phase_cooldown_timer)
	
	# Boss加入单独的组
	add_to_group("bosses")

## 获取当前阶段的攻击列表
func _get_current_phase_attacks() -> Array:
	if current_phase < phases.size():
		return phases[current_phase].get("attacks", [])
	return []

## 获取当前HP百分比
func _get_health_percent() -> float:
	return (float(current_health) / float(max_health)) * 100.0

## 检查是否需要阶段转换
func _check_phase_transition() -> void:
	var hp_percent = _get_health_percent()
	
	for i in range(phases.size()):
		var phase = phases[i]
		var range_data = phase.get("healthRange", [100, 0])
		if hp_percent <= range_data[0] and hp_percent > range_data[1]:
			if i != current_phase:
				_transition_to_phase(i)

## 转换到新阶段
func _transition_to_phase(new_phase: int) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	current_phase = new_phase
	current_attack_index = 0
	
	var phase_data = phases[new_phase]
	var phase_name = phase_data.get("name", "阶段%d" % (new_phase + 1))
	
	# 广播阶段转换
	phase_changed.emit(new_phase, phase_name)
	boss_announcement.emit(phase_name)
	
	print("=== %s 进入: %s ===" % [enemy_name, phase_name])
	
	# 阶段转换暂停
	await get_tree().create_timer(phase_transition_pause).timeout
	
	is_transitioning = false
	
	# 阶段转换后的特殊行为
	_on_phase_enter(new_phase)

## 阶段进入时的特殊行为（子类重写）
func _on_phase_enter(_phase: int) -> void:
	pass

## 选择下一个攻击
func _select_next_attack() -> String:
	var attacks = _get_current_phase_attacks()
	if attacks.is_empty():
		return ""
	
	current_attack_index = (current_attack_index + 1) % attacks.size()
	return attacks[current_attack_index]

## 开始易伤窗口
func _start_vulnerability_window() -> void:
	is_vulnerable = true
	defense = 0
	vulnerability_started.emit()
	print("%s 进入易伤状态！" % enemy_name)
	vulnerability_timer.start()

## 结束易伤窗口
func _on_vulnerability_ended() -> void:
	is_vulnerable = false
	defense = _get_base_defense()
	vulnerability_ended.emit()
	print("%s 易伤状态结束" % enemy_name)

## 获取基础防御（子类可重写）
func _get_base_defense() -> int:
	return _base_defense

## 受伤（覆盖基类，加入阶段检查）
func take_damage(damage: int, is_crit: bool = false) -> void:
	if is_dead:
		return
	
	# 易伤状态下伤害翻倍
	var actual_damage = damage
	if is_vulnerable:
		actual_damage = int(damage * 2.0)
	
	super.take_damage(actual_damage, is_crit)
	
	# 检查阶段转换
	if not is_dead:
		_check_phase_transition()

## 攻击模式（子类重写具体攻击逻辑）
func execute_attack(attack_name: String) -> void:
	# 默认空实现，子类重写
	print("%s 执行攻击: %s" % [enemy_name, attack_name])

## 召唤小怪
func summon_minions(count: int, offset_range: float = 100.0) -> void:
	for i in count:
		var offset = Vector2(randf_range(-offset_range, offset_range), randf_range(-offset_range, offset_range))
		var spawn_pos = global_position + offset
		
		# 使用敌人生成器创建小怪
		var spawner = get_node_or_null("/root/EnemySpawner")
		if spawner and spawner.has_method("spawn_enemy"):
			spawner.spawn_enemy("bamboo_spirit", spawn_pos)
		else:
			print("警告: 无法找到EnemySpawner来召唤小怪")

## Boss的AI行为
func _physics_process(_delta: float) -> void:
	if is_dead or is_transitioning:
		return
	
	if target:
		var distance = global_position.distance_to(target.global_position)
		
		if distance <= attack_range:
			_try_boss_attack()
		else:
			move_toward_target()
	else:
		patrol()

## 尝试执行Boss攻击
func _try_boss_attack() -> void:
	if not can_attack or is_dead:
		return
	
	can_attack = false
	attack_timer.start()
	
	var attack_name = _select_next_attack()
	if attack_name != "":
		execute_attack(attack_name)
	else:
		# 默认近战攻击
		for body in attack_area.get_overlapping_bodies():
			if body is Player:
				body.take_damage(attack_damage)
