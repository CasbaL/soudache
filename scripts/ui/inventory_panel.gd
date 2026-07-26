## 背包面板
## 网格显示物品槽位，物品名称带稀有度颜色
extends PanelContainer

# 配置
@export var columns: int = 5
@export var slot_size: Vector2 = Vector2(80, 80)

# 子节点引用
@onready var grid: GridContainer = $VBox/Grid
@onready var title_label: Label = $VBox/Title

# 物品槽位列表
var slots: Array[PanelContainer] = []

# 稀有度颜色
const RARITY_COLORS = {
	"common": Color(0.8, 0.8, 0.8),    # 白
	"uncommon": Color(0.2, 0.8, 0.2),  # 绿
	"rare": Color(0.3, 0.5, 1.0),      # 蓝
	"epic": Color(0.7, 0.3, 1.0),      # 紫
	"legendary": Color(1.0, 0.8, 0.0), # 金
	"blue": Color(0.3, 0.5, 1.0),      # 宝品
	"purple": Color(0.7, 0.3, 1.0),    # 仙品
	"gold": Color(1.0, 0.8, 0.0),      # 神品
}

func _ready() -> void:
	# 设置面板样式
	custom_minimum_size = Vector2(columns * slot_size.x + 20, 400)
	
	# 设置标题
	title_label.text = "背包 (0 / %d)" % GameManager.max_inventory_size
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 设置网格
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	
	# 创建初始槽位
	_create_slots()
	
	# 连接信号
	GameManager.inventory_changed.connect(_on_inventory_changed)

## 创建槽位
func _create_slots() -> void:
	for i in range(GameManager.max_inventory_size):
		var slot = PanelContainer.new()
		slot.custom_minimum_size = slot_size
		
		# 槽位样式
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style.border_color = Color(0.4, 0.4, 0.4)
		style.set_border_width_all(2)
		slot.add_theme_stylebox_override("panel", style)
		
		# 物品名称标签
		var label = Label.new()
		label.name = "ItemLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(label)
		
		grid.add_child(slot)
		slots.append(slot)

## 更新显示
func _on_inventory_changed() -> void:
	var items = GameManager.inventory
	title_label.text = "背包 (%d / %d)" % [items.size(), GameManager.max_inventory_size]
	
	for i in range(slots.size()):
		var label = slots[i].get_node("ItemLabel") as Label
		if i < items.size():
			var item = items[i]
			var item_name = item.get("name", "???")
			var amount = item.get("amount", 1)
			var rarity = item.get("rarity", "common")
			
			label.text = "%s x%d" % [item_name, amount]
			label.modulate = RARITY_COLORS.get(rarity, Color.WHITE)
			
			# 槽位有物品时边框变亮
			var style = slots[i].get_theme_stylebox("panel") as StyleBoxFlat
			style.border_color = RARITY_COLORS.get(rarity, Color.WHITE)
		else:
			label.text = ""
			label.modulate = Color.WHITE
			var style = slots[i].get_theme_stylebox("panel") as StyleBoxFlat
			style.border_color = Color(0.4, 0.4, 0.4)
