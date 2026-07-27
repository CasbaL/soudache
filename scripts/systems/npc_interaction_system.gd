## NPC交互系统 - 自动加载单例
## 处理事件房间中的NPC对话和交互
extends Node

# NPC类型
enum NPCType { MERCHANT, MYSTIC, TRAPPED_CULTIVATOR, TELEPORT }

# NPC定义
const NPC_DATA: Dictionary = {
	"merchant_1": {
		"name": "老道商人",
		"type": NPCType.MERCHANT,
		"dialogue": "小子，要买点什么？老道这里货真价实。",
		"layer": 1,
		"items": [
			{"id": "herb", "name": "灵草", "price": 20, "amount": 5},
			{"id": "ore", "name": "矿石", "price": 25, "amount": 5},
			{"id": "restore_pill", "name": "回复丹", "price": 50, "amount": 1},
		],
	},
	"merchant_2": {
		"name": "火焰商人",
		"type": NPCType.MERCHANT,
		"dialogue": "道友，在这火焰山能活下来，你有点本事。",
		"layer": 2,
		"items": [
			{"id": "herb", "name": "灵草", "price": 20, "amount": 10},
			{"id": "ore", "name": "矿石", "price": 25, "amount": 10},
			{"id": "shield_pill", "name": "护盾丹", "price": 80, "amount": 1},
			{"id": "attack_pill", "name": "攻击丹", "price": 100, "amount": 1},
		],
	},
	"merchant_3": {
		"name": "机关商人",
		"type": NPCType.MERCHANT,
		"dialogue": "道友，这天机阁的机关可不好对付。",
		"layer": 3,
		"items": [
			{"id": "herb", "name": "灵草", "price": 20, "amount": 20},
			{"id": "ore", "name": "矿石", "price": 25, "amount": 20},
			{"id": "artifact_spirit", "name": "器灵", "price": 500, "amount": 1},
			{"id": "rare_attack_pill", "name": "稀有攻击丹", "price": 300, "amount": 1},
		],
	},
	"mystic_1": {
		"name": "神秘老道",
		"type": NPCType.MYSTIC,
		"dialogue": "小子，想试试运气吗？",
		"layer": 1,
		"events": [
			{"type": "reward", "chance": 0.6, "item": {"id": "spirit_stone", "amount": 100}},
			{"type": "reward", "chance": 0.3, "item": {"id": "technique_fragment", "amount": 5}},
			{"type": "damage", "chance": 0.1, "amount": 50},
		],
	},
	"mystic_2": {
		"name": "火焰精灵",
		"type": NPCType.MYSTIC,
		"dialogue": "想感受火焰的力量吗？",
		"layer": 2,
		"events": [
			{"type": "reward", "chance": 0.5, "item": {"id": "spirit_stone", "amount": 200}},
			{"type": "buff", "chance": 0.3, "effect": "attack_boost", "value": 0.2, "duration": 300},
			{"type": "damage", "chance": 0.2, "amount": 100},
		],
	},
	"mystic_3": {
		"name": "机关精灵",
		"type": NPCType.MYSTIC,
		"dialogue": "想试试机关的力量吗？",
		"layer": 3,
		"events": [
			{"type": "reward", "chance": 0.4, "item": {"id": "spirit_stone", "amount": 500}},
			{"type": "reward", "chance": 0.3, "item": {"id": "artifact_spirit", "amount": 2}},
			{"type": "damage", "chance": 0.3, "amount": 200},
		],
	},
	"trapped_1": {
		"name": "被困修士",
		"type": NPCType.TRAPPED_CULTIVATOR,
		"dialogue": "道友救我！我被竹妖困在这里三天了！",
		"layer": 1,
		"reward": {"id": "spirit_stone", "amount": 150},
	},
	"trapped_2": {
		"name": "被困火焰修士",
		"type": NPCType.TRAPPED_CULTIVATOR,
		"dialogue": "道友救我！我被困在这火焰阵里了！",
		"layer": 2,
		"reward": {"id": "spirit_stone", "amount": 300},
	},
	"trapped_3": {
		"name": "被困机关修士",
		"type": NPCType.TRAPPED_CULTIVATOR,
		"dialogue": "道友救我！我被困在这机关阵里了！",
		"layer": 3,
		"reward": {"id": "spirit_stone", "amount": 500},
	},
	"teleport_1": {
		"name": "古传送阵",
		"type": NPCType.TELEPORT,
		"dialogue": "发现一个古传送阵，是否使用？",
		"layer": 1,
	},
	"teleport_2": {
		"name": "火焰传送阵",
		"type": NPCType.TELEPORT,
		"dialogue": "发现一个火焰传送阵，是否使用？",
		"layer": 2,
	},
	"teleport_3": {
		"name": "机关传送阵",
		"type": NPCType.TELEPORT,
		"dialogue": "发现一个机关传送阵，是否使用？",
		"layer": 3,
	},
}

# 交互状态
var current_npc: String = ""
var interaction_active: bool = false

signal npc_interacted(npc_id: String, result: Dictionary)
signal dialogue_started(npc_id: String, dialogue: String)
signal dialogue_ended(npc_id: String)
signal merchant_purchase(npc_id: String, item_id: String, amount: int)
signal mystic_event(npc_id: String, event_type: String, result: Dictionary)
signal rescue_completed(npc_id: String, reward: Dictionary)

func _ready() -> void:
	pass

## 获取NPC数据
func get_npc_data(npc_id: String) -> Dictionary:
	return NPC_DATA.get(npc_id, {})

## 获取指定层级的NPC列表
func get_layer_npcs(layer: int) -> Array:
	var result: Array = []
	for npc_id in NPC_DATA:
		if NPC_DATA[npc_id].get("layer", 1) == layer:
			result.append(npc_id)
	return result

## 获取NPC类型
func get_npc_type(npc_id: String) -> int:
	var data = NPC_DATA.get(npc_id, {})
	return data.get("type", NPCType.MERCHANT)

## 开始与NPC对话
func start_dialogue(npc_id: String) -> bool:
	if interaction_active:
		return false
	var data = NPC_DATA.get(npc_id, {})
	if data.is_empty():
		return false
	current_npc = npc_id
	interaction_active = true
	dialogue_started.emit(npc_id, data.get("dialogue", ""))
	return true

## 结束对话
func end_dialogue() -> void:
	if current_npc != "":
		dialogue_ended.emit(current_npc)
		current_npc = ""
		interaction_active = false

## 与商人NPC交易
func merchant_buy(npc_id: String, item_index: int) -> bool:
	var data = NPC_DATA.get(npc_id, {})
	if data.get("type") != NPCType.MERCHANT:
		return false
	var items = data.get("items", [])
	if item_index < 0 or item_index >= items.size():
		return false
	var item = items[item_index]
	var price = item.get("price", 0)
	var amount = item.get("amount", 1)
	# 检查灵石是否足够
	if GameManager.storage.get("spirit_stone", 0) < price:
		return false
	# 扣除灵石
	GameManager.storage["spirit_stone"] = GameManager.storage.get("spirit_stone", 0) - price
	# 添加物品
	GameManager.add_to_storage(item.get("id", ""), amount)
	merchant_purchase.emit(npc_id, item.get("id", ""), amount)
	npc_interacted.emit(npc_id, {"type": "purchase", "item": item})
	return true

## 与神秘NPC交互（随机事件）
func mystic_interact(npc_id: String) -> Dictionary:
	var data = NPC_DATA.get(npc_id, {})
	if data.get("type") != NPCType.MYSTIC:
		return {}
	var events = data.get("events", [])
	if events.is_empty():
		return {}
	# 随机选择事件
	var roll = randf()
	var cumulative = 0.0
	for event in events:
		cumulative += event.get("chance", 0.0)
		if roll <= cumulative:
			var result = _execute_mystic_event(event)
			mystic_event.emit(npc_id, event.get("type", ""), result)
			npc_interacted.emit(npc_id, {"type": "mystic", "event": event, "result": result})
			return result
	# 默认返回第一个事件
	var result = _execute_mystic_event(events[0])
	mystic_event.emit(npc_id, events[0].get("type", ""), result)
	npc_interacted.emit(npc_id, {"type": "mystic", "event": events[0], "result": result})
	return result

## 执行神秘事件
func _execute_mystic_event(event: Dictionary) -> Dictionary:
	var event_type = event.get("type", "")
	match event_type:
		"reward":
			var item = event.get("item", {})
			GameManager.add_to_storage(item.get("id", ""), item.get("amount", 1))
			return {"type": "reward", "item": item}
		"damage":
			var amount = event.get("amount", 0)
			GameManager.player_take_damage(amount)
			return {"type": "damage", "amount": amount}
		"buff":
			# 这里可以添加buff系统集成
			return {"type": "buff", "effect": event.get("effect", ""), "value": event.get("value", 0)}
		_:
			return {}

## 救助被困修士
func rescue_cultivator(npc_id: String) -> Dictionary:
	var data = NPC_DATA.get(npc_id, {})
	if data.get("type") != NPCType.TRAPPED_CULTIVATOR:
		return {}
	var reward = data.get("reward", {})
	GameManager.add_to_storage(reward.get("id", ""), reward.get("amount", 1))
	rescue_completed.emit(npc_id, reward)
	npc_interacted.emit(npc_id, {"type": "rescue", "reward": reward})
	return reward

## 使用传送阵
func use_teleport(npc_id: String) -> bool:
	var data = NPC_DATA.get(npc_id, {})
	if data.get("type") != NPCType.TELEPORT:
		return false
	# 这里可以集成传送系统
	# 随机传送到其他房间
	npc_interacted.emit(npc_id, {"type": "teleport"})
	return true

## 获取商人商品列表
func get_merchant_items(npc_id: String) -> Array:
	var data = NPC_DATA.get(npc_id, {})
	if data.get("type") != NPCType.MERCHANT:
		return []
	return data.get("items", [])

## 检查是否可以购买
func can_merchant_buy(npc_id: String, item_index: int) -> bool:
	var data = NPC_DATA.get(npc_id, {})
	if data.get("type") != NPCType.MERCHANT:
		return false
	var items = data.get("items", [])
	if item_index < 0 or item_index >= items.size():
		return false
	var item = items[item_index]
	var price = item.get("price", 0)
	return GameManager.storage.get("spirit_stone", 0) >= price

## 序列化
func serialize() -> Dictionary:
	return {}  # NPC交互系统无需持久化状态

## 反序列化
func deserialize(_data: Dictionary) -> void:
	pass  # NPC交互系统无需持久化状态
