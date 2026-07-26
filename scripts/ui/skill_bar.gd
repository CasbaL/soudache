## 技能栏
## 3个技能按钮 + 闪避按钮，显示冷却倒计时
extends HBoxContainer

# 技能按钮引用
@onready var skill_buttons: Array[Button] = [
	$Skill1,
	$Skill2,
	$Skill3,
]

# 冷却覆盖层 {slot: ColorRect}
var cooldown_overlays: Dictionary = {}
# 冷却标签 {slot: Label}
var cooldown_labels: Dictionary = {}

# 玩家引用
var player: Node = null

func _ready() -> void:
	# 为每个技能按钮创建冷却覆盖
	for i in range(3):
		var slot = i + 1
		var btn = skill_buttons[i]
		
		# 设置按钮文本为技能名
		var skill = SkillSystem.get_skill_by_slot(slot)
		if not skill.is_empty():
			btn.text = skill.get("name", "技能%d" % slot)
		
		# 连接按钮信号
		btn.pressed.connect(_on_skill_pressed.bind(slot))
	
	# 连接技能释放信号
	SkillSystem.skill_cast.connect(_on_skill_cast)

## 初始化（传入玩家引用）
func init(player_ref: Node) -> void:
	player = player_ref

func _process(_delta: float) -> void:
	# 更新冷却显示
	for i in range(3):
		var slot = i + 1
		var btn = skill_buttons[i]
		var skill = SkillSystem.get_skill_by_slot(slot)
		if skill.is_empty():
			continue
		var skill_id = skill.get("id", "")
		var remaining = SkillSystem.get_cooldown_remaining(skill_id)
		
		if remaining > 0:
			btn.disabled = true
			var cd_text = "%.1f" % remaining
			btn.text = skill.get("name", "技能%d" % slot) + "\n" + cd_text
			# 暗化按钮
			btn.modulate = Color(0.5, 0.5, 0.5, 0.8)
		else:
			btn.disabled = false
			btn.text = skill.get("name", "技能%d" % slot)
			btn.modulate = Color.WHITE

## 技能按钮按下
func _on_skill_pressed(slot: int) -> void:
	if player == null:
		return
	match slot:
		1: player.use_skill_1()
		2: player.use_skill_2()
		3: player.use_skill_3()

## 技能释放时的反馈
func _on_skill_cast(_skill_id: String, _slot: int) -> void:
	# 可以在这里添加释放特效
	pass
