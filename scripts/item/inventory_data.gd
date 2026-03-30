class_name InventoryData
extends RefCounted

const MAX_CAPACITY: int = 50

var capacity: int = MAX_CAPACITY
var gold: int = 0
var _items: Array[Dictionary] = []  # {item: ItemData, quantity: int}

func _init():
	pass

func add_item(item: ItemData, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false

	# 查找是否可以堆叠
	if item.stack_size > 1:
		for i in range(_items.size()):
			var entry = _items[i]
			if entry["item"].item_id == item.item_id:
				entry["quantity"] += quantity
				SignalBus.item_acquired.emit(item.item_id, quantity)
				return true

	# 检查容量
	if get_item_count() >= capacity:
		return false

	# 新增物品
	_items.append({"item": item, "quantity": quantity})
	SignalBus.item_acquired.emit(item.item_id, quantity)
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(_items.size()):
		var entry = _items[i]
		if entry["item"].item_id == item_id:
			if entry["quantity"] >= quantity:
				entry["quantity"] -= quantity
				if entry["quantity"] <= 0:
					_items.remove_at(i)
				SignalBus.item_discarded.emit(item_id)
				return true
			else:
				return false
	return false

func get_item(item_id: String) -> Dictionary:
	for entry in _items:
		if entry["item"].item_id == item_id:
			return entry
	return {"item": null, "quantity": 0}

func has_item(item_id: String) -> bool:
	return get_item(item_id)["item"] != null

func get_item_count() -> int:
	return _items.size()

func get_all_items() -> Array[Dictionary]:
	return _items.duplicate()

func get_items_by_type(item_type: ItemData.ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _items:
		if entry["item"].type == item_type:
			result.append(entry)
	return result

func get_equipped_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _items:
		if entry["item"].is_equippable:
			result.append(entry)
	return result

func use_item(item_id: String) -> Dictionary:
	var entry = get_item(item_id)
	if not entry["item"]:
		return {"success": false, "message": "物品不存在"}
	if not entry["item"].can_use():
		return {"success": false, "message": "无法使用此物品"}

	var result = entry["item"].use()
	if result["success"]:
		remove_item(item_id, 1)
		SignalBus.item_used.emit(item_id)
	return result

func add_gold(amount: int) -> void:
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

func get_total_value() -> int:
	var total = gold
	for entry in _items:
		total += entry["item"].value * entry["quantity"]
	return total

func clear():
	_items.clear()
	gold = 0

func to_dict() -> Dictionary:
	var items_list: Array = []
	for entry in _items:
		items_list.append({
			"item": entry["item"].to_dict(),
			"quantity": entry["quantity"]
		})
	return {
		"capacity": capacity,
		"gold": gold,
		"items": items_list
	}

func from_dict(d: Dictionary):
	capacity = d.get("capacity", MAX_CAPACITY)
	gold = d.get("gold", 0)
	_items.clear()
	for item_dict in d.get("items", []):
		var item = ItemData.from_dict(item_dict.get("item", {}))
		var quantity = item_dict.get("quantity", 1)
		_items.append({"item": item, "quantity": quantity})
