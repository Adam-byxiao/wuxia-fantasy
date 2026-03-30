class_name ItemData
extends RefCounted

enum ItemType { EQUIP, PILl, QUEST, CONSUMABLE, BOOK, MANUAL, OTHER }
enum Quality { COMMON, RARE, EPIC, LEGENDARY }

var item_id: String
var name: String
var type: ItemType
var quality: Quality
var description: String
var icon_path: String

# 数值属性
var value: int = 0  # 价格
var stack_size: int = 1
var is_equippable: bool = false
var equip_slot: String = ""  # weapon, armor, accessory

# 使用效果
var heal_amount: int = 0
var qi恢复_amount: int = 0
var exp_amount: int = 0
var damage_amount: int = 0  # 暗器伤害
var learnable_skill_id: String = ""  # 秘籍可学习技能ID
var book_exp: int = 0  # 书籍提供经验
var effect_description: String = ""

func _init(
	p_id: String = "",
	p_name: String = "",
	p_type: ItemType = ItemType.OTHER,
	p_quality: Quality = Quality.COMMON,
	p_desc: String = ""
):
	item_id = p_id
	name = p_name
	type = p_type
	quality = p_quality
	description = p_desc

func get_type_string() -> String:
	match type:
		ItemType.EQUIP: return "装备"
		ItemType.PILl: return "丹药"
		ItemType.QUEST: return "任务"
		ItemType.CONSUMABLE: return "暗器"
		ItemType.BOOK: return "书籍"
		ItemType.MANUAL: return "秘籍"
		_ : return "其他"

func get_quality_color() -> Color:
	match quality:
		Quality.COMMON: return Color.WHITE
		Quality.RARE: return Color.BLUE
		Quality.EPIC: return Color.PURPLE
		Quality.LEGENDARY: return Color.ORANGE
		_ : return Color.WHITE

func can_use() -> bool:
	return type == ItemType.PILl or type == ItemType.QUEST or type == ItemType.CONSUMABLE or type == ItemType.BOOK or type == ItemType.MANUAL

func use() -> Dictionary:
	if not can_use():
		return {"success": false, "message": "无法使用此物品"}
	var result = {"success": true, "heal": heal_amount, "qi": qi恢复_amount, "exp": exp_amount, "damage": damage_amount}
	if type == ItemType.MANUAL and learnable_skill_id != "":
		result["skill_learned"] = learnable_skill_id
		result["message"] = "学会了新技能！"
	elif type == ItemType.BOOK:
		result["message"] = "阅读完毕，获得 %d 经验" % book_exp
	elif type == ItemType.CONSUMABLE:
		result["message"] = "使用了暗器，造成 %d 伤害" % damage_amount
	else:
		result["message"] = "使用了 %s" % name
	return result

func to_dict() -> Dictionary:
	return {
		"item_id": item_id,
		"name": name,
		"type": type,
		"quality": quality,
		"description": description,
		"value": value,
		"stack_size": stack_size,
		"is_equippable": is_equippable,
		"equip_slot": equip_slot,
		"heal_amount": heal_amount,
		"qi恢复_amount": qi恢复_amount,
		"exp_amount": exp_amount,
		"damage_amount": damage_amount,
		"learnable_skill_id": learnable_skill_id,
		"book_exp": book_exp,
		"effect_description": effect_description,
	}

static func from_dict(d: Dictionary) -> ItemData:
	var item = ItemData.new()
	item.item_id = d.get("item_id", "")
	item.name = d.get("name", "")
	item.type = d.get("type", ItemType.OTHER)
	item.quality = d.get("quality", Quality.COMMON)
	item.description = d.get("description", "")
	item.value = d.get("value", 0)
	item.stack_size = d.get("stack_size", 1)
	item.is_equippable = d.get("is_equippable", false)
	item.equip_slot = d.get("equip_slot", "")
	item.heal_amount = d.get("heal_amount", 0)
	item.qi恢复_amount = d.get("qi恢复_amount", 0)
	item.exp_amount = d.get("exp_amount", 0)
	item.damage_amount = d.get("damage_amount", 0)
	item.learnable_skill_id = d.get("learnable_skill_id", "")
	item.book_exp = d.get("book_exp", 0)
	item.effect_description = d.get("effect_description", "")
	return item
