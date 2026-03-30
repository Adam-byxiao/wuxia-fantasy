extends Control

@onready var item_grid: GridContainer = $VBox/ItemGrid
@onready var gold_label: Label = $VBox/GoldLabel
@onready var result_display: RichTextLabel = $VBox/ResultDisplay
@onready var item_detail: RichTextLabel = $VBox/ItemDetail

var selected_item_id: String = ""
var test_items: Array[ItemData] = []

func _ready():
	_setup_test_items()
	_refresh_inventory()
	$VBox/HBox/RefreshBtn.pressed.connect(_refresh_inventory)
	$VBox/HBox/UseBtn.pressed.connect(_on_use_selected)
	$VBox/HBox/BackBtn.pressed.connect(_on_back)

func _setup_test_items():
	test_items.clear()

	# 装备类
	test_items.append(ItemTemplates.create_sword("精钢剑", 15))
	test_items.append(ItemTemplates.create_armor("皮甲", 8))
	test_items.append(ItemTemplates.create_accessory("平安玉佩", 10))

	# 暗器类（可消耗装备）
	test_items.append(ItemTemplates.create_throwing_knife(30))
	test_items.append(ItemTemplates.create_fire_bomb(50))
	test_items.append(ItemTemplates.create_smoke_bomb())

	# 丹药类
	test_items.append(ItemTemplates.create_healing_pill(50))
	test_items.append(ItemTemplates.create_healing_pill(100))
	test_items.append(ItemTemplates.create_qi_pill(30))
	test_items.append(ItemTemplates.create_exp_pill(100))

	# 书籍类
	test_items.append(ItemTemplates.create_book("江湖见闻录", 50, ItemData.Quality.COMMON))
	test_items.append(ItemTemplates.create_book("内功心法", 100, ItemData.Quality.RARE))
	test_items.append(ItemTemplates.create_book("武林秘籍", 200, ItemData.Quality.EPIC))

	# 武学秘籍类
	test_items.append(ItemTemplates.create_manual("palm_strike", "掌心雷", ItemData.Quality.RARE))
	test_items.append(ItemTemplates.create_manual("sword_qi", "剑气术", ItemData.Quality.EPIC))
	test_items.append(ItemTemplates.create_manual("dragon_claw", "龙爪手", ItemData.Quality.LEGENDARY))

func _refresh_inventory():
	# 清空网格
	for child in item_grid.get_children():
		child.free()

	# 填入测试物品到 GameState 背包
	GameState.player_inventory.clear()
	for item in test_items:
		GameState.player_inventory.add_item(item, 1 if item.stack_size == 1 else randi() % 5 + 1)

	# 显示金币
	GameState.player_inventory.add_gold(500)
	gold_label.text = "金币: %d" % GameState.player_inventory.gold

	# 显示物品
	var items = GameState.player_inventory.get_all_items()
	for entry in items:
		var item = entry["item"]
		var qty = entry["quantity"]

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 60)
		btn.text = "%s x%d\n%s" % [item.name, qty, item.get_type_string()]
		btn.pressed.connect(_on_item_selected.bind(item.item_id))
		item_grid.add_child(btn)

	selected_item_id = ""
	item_detail.text = "选择一个物品查看详情"
	result_display.text = "[系统] 测试物品已加载，共 %d 种物品" % items.size()

func _on_item_selected(item_id: String):
	selected_item_id = item_id
	var entry = GameState.player_inventory.get_item(item_id)
	if entry["item"]:
		var item = entry["item"]
		var quality_names = ["普通", "稀有", "史诗", "传说"]
		item_detail.text = "=== %s ===\n" % item.name
		item_detail.text += "类型: %s\n" % item.get_type_string()
		item_detail.text += "品质: %s\n" % quality_names[item.quality]
		item_detail.text += "数量: %d\n" % entry["quantity"]
		item_detail.text += "价值: %d 金币\n" % item.value
		item_detail.text += "可使用: %s\n" % ("是" if item.can_use() else "否")
		if item.is_equippable:
			item_detail.text += "装备槽: %s\n" % item.equip_slot
		if item.heal_amount > 0:
			item_detail.text += "恢复生命: %d\n" % item.heal_amount
		if item.qi恢复_amount > 0:
			item_detail.text += "恢复内力: %d\n" % item.qi恢复_amount
		if item.damage_amount > 0:
			item_detail.text += "造成伤害: %d\n" % item.damage_amount
		if item.book_exp > 0:
			item_detail.text += "阅读经验: %d\n" % item.book_exp
		if item.learnable_skill_id != "":
			item_detail.text += "可学技能: %s\n" % item.learnable_skill_id
		item_detail.text += "\n%s" % item.description
	else:
		item_detail.text = "物品不存在"

func _on_use_selected():
	if selected_item_id:
		var result = GameState.player_inventory.use_item(selected_item_id)
		result_display.text = "[使用结果] %s" % result
		_refresh_inventory()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/menu/test_menu.tscn")
