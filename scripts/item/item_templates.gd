class_name ItemTemplates
extends Node

# 静态方法，创建预设物品
static func create_healing_pill(amount: int = 50) -> ItemData:
	var item = ItemData.new("healing_pill", "疗伤丹", ItemData.ItemType.PILl, ItemData.Quality.COMMON, "服用后恢复生命")
	item.heal_amount = amount
	item.value = 20
	item.stack_size = 10
	item.effect_description = "恢复 %d 生命" % amount
	return item

static func create_qi_pill(amount: int = 30) -> ItemData:
	var item = ItemData.new("qi_pill", "补气丹", ItemData.ItemType.PILl, ItemData.Quality.COMMON, "服用后恢复内力")
	item.qi恢复_amount = amount
	item.value = 25
	item.stack_size = 10
	item.effect_description = "恢复 %d 内力" % amount
	return item

static func create_exp_pill(amount: int = 100) -> ItemData:
	var item = ItemData.new("exp_pill", "修为丹", ItemData.ItemType.PILl, ItemData.Quality.RARE, "服用后获得经验")
	item.exp_amount = amount
	item.value = 100
	item.stack_size = 5
	item.effect_description = "获得 %d 经验" % amount
	return item

static func create_sword(name: String = "铁剑", attack: int = 10) -> ItemData:
	var item = ItemData.new("sword_" + name, name, ItemData.ItemType.EQUIP, ItemData.Quality.COMMON, "一把普通的剑")
	item.is_equippable = true
	item.equip_slot = "weapon"
	item.value = attack * 5
	return item

static func create_armor(name: String = "布衣", defense: int = 5) -> ItemData:
	var item = ItemData.new("armor_" + name, name, ItemData.ItemType.EQUIP, ItemData.Quality.COMMON, "一件普通的护甲")
	item.is_equippable = true
	item.equip_slot = "armor"
	item.value = defense * 5
	return item

static func create_accessory(name: String = "玉佩", bonus: int = 5) -> ItemData:
	var item = ItemData.new("accessory_" + name, name, ItemData.ItemType.EQUIP, ItemData.Quality.COMMON, "一件普通的饰品")
	item.is_equippable = true
	item.equip_slot = "accessory"
	item.value = bonus * 10
	item.effect_description = "魅力 +%d" % bonus
	return item

# 暗器（可消耗装备）
static func create_throwing_knife(damage: int = 30) -> ItemData:
	var item = ItemData.new("throwing_knife", "飞刀", ItemData.ItemType.CONSUMABLE, ItemData.Quality.COMMON, "淬毒的飞刀，可造成伤害")
	item.damage_amount = damage
	item.value = 15
	item.stack_size = 20
	item.effect_description = "投掷造成 %d 伤害" % damage
	return item

static func create_fire_bomb(damage: int = 50) -> ItemData:
	var item = ItemData.new("fire_bomb", "火雷弹", ItemData.ItemType.CONSUMABLE, ItemData.Quality.RARE, "点燃后爆炸的火器")
	item.damage_amount = damage
	item.value = 50
	item.stack_size = 10
	item.effect_description = "爆炸造成 %d 伤害" % damage
	return item

static func create_smoke_bomb() -> ItemData:
	var item = ItemData.new("smoke_bomb", "烟雾弹", ItemData.ItemType.CONSUMABLE, ItemData.Quality.COMMON, "产生烟雾便于逃跑")
	item.value = 20
	item.stack_size = 10
	item.effect_description = "使用后可尝试逃跑"
	return item

# 书籍（阅读后获得经验）
static func create_book(title: String, exp: int = 50, quality: ItemData.Quality = ItemData.Quality.COMMON) -> ItemData:
	var item = ItemData.new("book_" + title, title, ItemData.ItemType.BOOK, quality, "一本有趣的书籍")
	item.book_exp = exp
	item.value = exp
	item.stack_size = 1
	item.effect_description = "阅读后获得 %d 经验" % exp
	return item

# 武学秘籍（可学习技能）
static func create_manual(skill_id: String, skill_name: String, quality: ItemData.Quality = ItemData.Quality.RARE) -> ItemData:
	var quality_names = {
		ItemData.Quality.COMMON: "初级",
		ItemData.Quality.RARE: "中级",
		ItemData.Quality.EPIC: "高级",
		ItemData.Quality.LEGENDARY: "绝世"
	}
	var item_name = "%s武学笔记" % quality_names.get(quality, "初级")
	var item = ItemData.new("manual_" + skill_id, item_name, ItemData.ItemType.MANUAL, quality, "记载着武学技法的秘籍")
	item.learnable_skill_id = skill_id
	item.value = 200 if quality == ItemData.Quality.LEGENDARY else 100
	item.stack_size = 1
	item.effect_description = "修炼后可学会 %s" % skill_name
	return item

# 获取所有初始物品
static func get_starting_items() -> Array[ItemData]:
	return [
		create_healing_pill(50),
		create_healing_pill(50),
		create_qi_pill(30),
	]
