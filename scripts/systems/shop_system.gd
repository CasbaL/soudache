## 商店系统 - 自动加载单例
## 管理商品列表、购买功能
extends Node

# 商品类型
enum ItemType { SEED, RECIPE, Blueprint, MATERIAL, SPECIAL }

# 商品定义
const SHOP_ITEMS: Dictionary = {
	# Lv1 基础商品
	"herb_seed": {
		"name": "灵草种子",
		"type": ItemType.SEED,
		"description": "种植后产出灵草",
		"unlock_level": 1,
		"price": 50,
		"item_id": "herb_seed",
		"amount": 1,
	},
	"ore_seed": {
		"name": "矿石种子",
		"type": ItemType.SEED,
		"description": "种植后产出矿石",
		"unlock_level": 1,
		"price": 50,
		"item_id": "ore_seed",
		"amount": 1,
	},
	"basic_recipe": {
		"name": "普通丹方",
		"type": ItemType.RECIPE,
		"description": "学习后解锁普通丹药配方",
		"unlock_level": 1,
		"price": 200,
		"item_id": "basic_recipe",
		"amount": 1,
	},
	# Lv2 中级商品
	"quality_herb_seed": {
		"name": "优质灵草种子",
		"type": ItemType.SEED,
		"description": "种植后产出优质灵草",
		"unlock_level": 2,
		"price": 150,
		"item_id": "quality_herb_seed",
		"amount": 1,
	},
	"quality_ore_seed": {
		"name": "优质矿石种子",
		"type": ItemType.SEED,
		"description": "种植后产出优质矿石",
		"unlock_level": 2,
		"price": 150,
		"item_id": "quality_ore_seed",
		"amount": 1,
	},
	"advanced_recipe": {
		"name": "高级丹方",
		"type": ItemType.RECIPE,
		"description": "学习后解锁高级丹药配方",
		"unlock_level": 2,
		"price": 500,
		"item_id": "advanced_recipe",
		"amount": 1,
	},
	# Lv3 高级商品
	"rare_herb_seed": {
		"name": "稀有灵草种子",
		"type": ItemType.SEED,
		"description": "种植后产出稀有灵草",
		"unlock_level": 3,
		"price": 500,
		"item_id": "rare_herb_seed",
		"amount": 1,
	},
	"rare_ore_seed": {
		"name": "稀有矿石种子",
		"type": ItemType.SEED,
		"description": "种植后产出稀有矿石",
		"unlock_level": 3,
		"price": 500,
		"item_id": "rare_ore_seed",
		"amount": 1,
	},
	"blueprint_blue": {
		"name": "宝品装备图纸",
		"type": ItemType.Blueprint,
		"description": "学习后可打造宝品装备",
		"unlock_level": 3,
		"price": 1000,
		"item_id": "blueprint_blue",
		"amount": 1,
	},
	# Lv4 稀有商品
	"artifact_spirit": {
		"name": "器灵",
		"type": ItemType.MATERIAL,
		"description": "强化和打造高级装备的材料",
		"unlock_level": 4,
		"price": 2000,
		"item_id": "artifact_spirit",
		"amount": 1,
	},
	"blueprint_purple": {
		"name": "仙品装备图纸",
		"type": ItemType.Blueprint,
		"description": "学习后可打造仙品装备",
		"unlock_level": 4,
		"price": 3000,
		"item_id": "blueprint_purple",
		"amount": 1,
	},
	# Lv5 顶级商品
	"blueprint_gold": {
		"name": "神品装备图纸",
		"type": ItemType.Blueprint,
		"description": "学习后可打造神品装备",
		"unlock_level": 5,
		"price": 8000,
		"item_id": "blueprint_gold",
		"amount": 1,
	},
	"protection_charm_normal": {
		"name": "普通保护符",
		"type": ItemType.SPECIAL,
		"description": "+1到+5强化失败不降级",
		"unlock_level": 3,
		"price": 500,
		"item_id": "protection_charm_normal",
		"amount": 1,
	},
	"protection_charm_advanced": {
		"name": "高级保护符",
		"type": ItemType.SPECIAL,
		"description": "+1到+10强化失败不降级",
		"unlock_level": 4,
		"price": 2000,
		"item_id": "protection_charm_advanced",
		"amount": 1,
	},
	"protection_charm_divine": {
		"name": "神级保护符",
		"type": ItemType.SPECIAL,
		"description": "任何等级强化失败不降级",
		"unlock_level": 5,
		"price": 5000,
		"item_id": "protection_charm_divine",
		"amount": 1,
	},
}

signal item_purchased(item_id: String, amount: int)
signal purchase_failed(item_id: String, reason: String)

func _ready() -> void:
	pass

## 获取商店等级
func get_shop_level() -> int:
	return BuildingSystem.get_building_level("shop")

## 获取已解锁的商品列表
func get_unlocked_items() -> Array:
	var level = get_shop_level()
	var result: Array = []
	for item_id in SHOP_ITEMS:
		if SHOP_ITEMS[item_id].get("unlock_level", 1) <= level:
			result.append(item_id)
	return result

## 获取商品数据
func get_item_data(item_id: String) -> Dictionary:
	return SHOP_ITEMS.get(item_id, {})

## 检查是否可以购买
func can_purchase(item_id: String, amount: int = 1) -> bool:
	var item = SHOP_ITEMS.get(item_id, {})
	if item.is_empty():
		return false
	var level = get_shop_level()
	if item.get("unlock_level", 1) > level:
		return false
	var total_price = item.get("price", 0) * amount
	if GameManager.storage.get("spirit_stone", 0) < total_price:
		return false
	return true

## 购买商品
func purchase_item(item_id: String, amount: int = 1) -> bool:
	if not can_purchase(item_id, amount):
		var item = SHOP_ITEMS.get(item_id, {})
		if item.is_empty():
			purchase_failed.emit(item_id, "商品不存在")
		elif item.get("unlock_level", 1) > get_shop_level():
			purchase_failed.emit(item_id, "商店等级不足")
		else:
			purchase_failed.emit(item_id, "灵石不足")
		return false
	var item = SHOP_ITEMS[item_id]
	var total_price = item.get("price", 0) * amount
	# 扣除灵石
	GameManager.storage["spirit_stone"] = GameManager.storage.get("spirit_stone", 0) - total_price
	# 添加物品到背包
	var purchased_item = {
		"id": item.get("item_id", item_id),
		"name": item.get("name", ""),
		"type": _item_type_to_string(item.get("type", ItemType.SEED)),
		"amount": amount,
	}
	GameManager.add_to_inventory(purchased_item)
	item_purchased.emit(item_id, amount)
	return true

## 获取商品价格
func get_item_price(item_id: String) -> int:
	var item = SHOP_ITEMS.get(item_id, {})
	return item.get("price", 0)

## 获取商品类型字符串
func _item_type_to_string(type: ItemType) -> String:
	match type:
		ItemType.SEED:
			return "seed"
		ItemType.RECIPE:
			return "recipe"
		ItemType.Blueprint:
			return "blueprint"
		ItemType.MATERIAL:
			return "material"
		ItemType.SPECIAL:
			return "special"
		_:
			return "unknown"

## 序列化
func serialize() -> Dictionary:
	return {}  # 商店系统无需持久化状态

## 反序列化
func deserialize(_data: Dictionary) -> void:
	pass  # 商店系统无需持久化状态
