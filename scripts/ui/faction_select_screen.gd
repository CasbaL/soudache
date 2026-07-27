## 门派选择界面
## 展示3个门派卡片，显示属性对比和技能预览
extends Control

# 门派卡片引用
@onready var card_sword: VBoxContainer = $VBox/Cards/CardSword
@onready var card_talisman: VBoxContainer = $VBox/Cards/CardTalisman
@onready var card_pill: VBoxContainer = $VBox/Cards/CardPill

# 信息面板
@onready var info_panel: VBoxContainer = $VBox/InfoPanel
@onready var info_title: Label = $VBox/InfoPanel/Title
@onready var info_desc: RichTextLabel = $VBox/InfoPanel/Description
@onready var stats_grid: GridContainer = $VBox/InfoPanel/StatsGrid
@onready var skills_label: RichTextLabel = $VBox/InfoPanel/SkillsLabel
@onready var select_button: Button = $VBox/SelectButton

# 属性条引用
@onready var hp_bar: ProgressBar = $VBox/InfoPanel/StatsGrid/HPBar
@onready var atk_bar: ProgressBar = $VBox/InfoPanel/StatsGrid/ATKBar
@onready var def_bar: ProgressBar = $VBox/InfoPanel/StatsGrid/DEFBar
@onready var spd_bar: ProgressBar = $VBox/InfoPanel/StatsGrid/SPDBar

# 当前选中的门派
var selected_faction: String = ""

# 门派ID到卡片的映射
var faction_cards: Dictionary = {}

func _ready() -> void:
	print("[FactionSelect] _ready 开始")
	
	# 绑定卡片点击
	faction_cards = {
		FactionSystem.SWORD: card_sword,
		FactionSystem.TALISMAN: card_talisman,
		FactionSystem.PILL: card_pill,
	}
	
	for faction_id in faction_cards:
		var card = faction_cards[faction_id]
		_setup_card(card, faction_id)
	
	select_button.pressed.connect(_on_select_pressed)
	select_button.disabled = true
	
	# 默认隐藏信息面板
	info_panel.visible = false
	
	print("[FactionSelect] _ready 完成")

## 初始化单个卡片
func _setup_card(card: VBoxContainer, faction_id: String) -> void:
	var data = FactionSystem._faction_data_instance.get_faction(faction_id)
	if data.is_empty():
		print("[FactionSelect] 门派数据为空: %s" % faction_id)
		return
	
	# 设置名称
	var name_label = card.get_node("Panel/VBox/Name") as Label
	name_label.text = data.get("name", "")
	
	# 设置标题
	var title_label = card.get_node("Panel/VBox/Title") as Label
	title_label.text = data.get("title", "")
	
	# 设置颜色标识
	var color_rect = card.get_node("Panel/VBox/ColorBar") as ColorRect
	color_rect.color = FactionSystem._faction_data_instance.get_color(faction_id)
	
	# 设置标签
	var tags_label = card.get_node("Panel/VBox/Tags") as Label
	var tags: Array = data.get("tags", [])
	tags_label.text = " ".join(tags)
	
	# 连接点击事件
	var button = card.get_node("Button") as Button
	button.pressed.connect(_on_card_selected.bind(faction_id))
	print("[FactionSelect] 卡片 %s 设置完成，按钮已连接" % faction_id)

## 卡片被选中
func _on_card_selected(faction_id: String) -> void:
	print("[FactionSelect] 卡片被选中: %s" % faction_id)
	selected_faction = faction_id
	_update_info_panel(faction_id)
	_highlight_card(faction_id)
	select_button.disabled = false
	print("[FactionSelect] 确认按钮已启用")

## 高亮选中的卡片
func _highlight_card(faction_id: String) -> void:
	for fid in faction_cards:
		var card = faction_cards[fid]
		if fid == faction_id:
			card.modulate = Color(1.2, 1.2, 1.2, 1.0)
		else:
			card.modulate = Color(0.7, 0.7, 0.7, 0.8)

## 更新信息面板
func _update_info_panel(faction_id: String) -> void:
	info_panel.visible = true
	
	var data = FactionSystem._faction_data_instance.get_faction(faction_id)
	var stats = FactionSystem._faction_data_instance.get_stats(faction_id)
	var color = FactionSystem._faction_data_instance.get_color(faction_id)
	
	# 标题
	info_title.text = "%s - %s" % [data.get("name", ""), data.get("title", "")]
	info_title.add_theme_color_override("font_color", color)
	
	# 描述
	info_desc.text = data.get("description", "")
	
	# 属性条（最大值参考）
	hp_bar.value = stats.get("max_health", 0)
	atk_bar.value = stats.get("attack", 0)
	def_bar.value = stats.get("defense", 0)
	spd_bar.value = stats.get("speed", 0)
	
	# 技能预览
	var skill_text = "[b]技能列表：[/b]\n"
	var ult = FactionSystem._faction_data_instance.get_ultimate(faction_id)
	skill_text += "[color=%s]%s[/color] - %s\n" % [color.to_html(false), ult.get("name", ""), ult.get("description", "")]
	skills_label.bbcode_enabled = true
	skills_label.text = skill_text

## 确认选择
func _on_select_pressed() -> void:
	print("[FactionSelect] 确认选择按钮被点击")
	if selected_faction == "":
		print("[FactionSelect] 没有选择门派，返回")
		return
	
	print("[FactionSelect] 选择门派: %s" % selected_faction)
	FactionSystem.select_faction(selected_faction)
	
	# 跳转到洞府主界面
	print("[FactionSelect] 跳转到 haven_main.tscn")
	get_tree().change_scene_to_file("res://scenes/ui/haven_main.tscn")
