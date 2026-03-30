extends Control

@onready var item_grid: GridContainer = $Margin/HBox/LeftPanel/ItemGrid
@onready var gold_label: Label = $Margin/HBox/LeftPanel/GoldLabel
@onready var item_detail_text: RichTextLabel = $Margin/HBox/RightPanel/ItemDetailText
@onready var use_btn: Button = $Margin/HBox/RightPanel/UseBtn
@onready var discard_btn: Button = $Margin/HBox/RightPanel/DiscardBtn
@onready var close_btn: Button = $Margin/HBox/RightPanel/CloseBtn

var selected_item_id: String = ""

func _ready():
	close_btn.pressed.connect(_on_close)
	use_btn.pressed.connect(_on_use)
	discard_btn.pressed.connect(_on_discard)

	# Tab buttons
	$Margin/HBox/LeftPanel/CategoryTabs/TabAll.pressed.connect(_on_tab_all)
	$Margin/HBox/LeftPanel/CategoryTabs/TabEquip.pressed.connect(_on_tab_equip)
	$Margin/HBox/LeftPanel/CategoryTabs/TabPill.pressed.connect(_on_tab_pill)
	$Margin/HBox/LeftPanel/CategoryTabs/TabConsumable.pressed.connect(_on_tab_consumable)
	$Margin/HBox/LeftPanel/CategoryTabs/TabBook.pressed.connect(_on_tab_book)
	$Margin/HBox/LeftPanel/CategoryTabs/TabManual.pressed.connect(_on_tab_manual)
	$Margin/HBox/LeftPanel/CategoryTabs/TabQuest.pressed.connect(_on_tab_quest)
	$Margin/HBox/LeftPanel/CategoryTabs/TabOther.pressed.connect(_on_tab_other)

	_refresh_inventory()

func _refresh_inventory():
	# 清空网格
	for child in item_grid.get_children():
		child.free()

	# 显示物品
	var inventory = GameState.player_inventory
	gold_label.text = "金币: %d" % inventory.gold

	var items = inventory.get_all_items()
	for entry in items:
		var item = entry["item"]
		var qty = entry["quantity"]

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		btn.text = "%s x%d\n%s" % [item.name, qty, item.get_type_string()]
		btn.pressed.connect(_on_item_selected.bind(item.item_id))
		item_grid.add_child(btn)

	selected_item_id = ""
	item_detail_text.text = "选择一个物品查看详情"
	use_btn.disabled = true
	discard_btn.disabled = true

func _on_item_selected(item_id: String):
	selected_item_id = item_id
	var entry = GameState.player_inventory.get_item(item_id)
	if entry["item"]:
		var item = entry["item"]
		var quality_names = ["普通", "稀有", "史诗", "传说"]
		item_detail_text.text = "=== %s ===\n" % item.name
		item_detail_text.text += "类型: %s\n" % item.get_type_string()
		item_detail_text.text += "品质: %s\n" % quality_names[item.quality]
		item_detail_text.text += "数量: %d\n" % entry["quantity"]
		item_detail_text.text += "价值: %d 金币\n" % item.value
		if item.is_equippable:
			item_detail_text.text += "装备槽: %s\n" % item.equip_slot
		if item.heal_amount > 0:
			item_detail_text.text += "恢复生命: %d\n" % item.heal_amount
		if item.qi恢复_amount > 0:
			item_detail_text.text += "恢复内力: %d\n" % item.qi恢复_amount
		if item.damage_amount > 0:
			item_detail_text.text += "造成伤害: %d\n" % item.damage_amount
		if item.book_exp > 0:
			item_detail_text.text += "阅读经验: %d\n" % item.book_exp
		if item.learnable_skill_id != "":
			item_detail_text.text += "可学技能: %s\n" % item.learnable_skill_id
		item_detail_text.text += "\n%s" % item.description
		use_btn.disabled = not item.can_use()
		discard_btn.disabled = false
	else:
		item_detail_text.text = "物品不存在"
		use_btn.disabled = true
		discard_btn.disabled = true

func _on_use():
	if selected_item_id:
		var result = GameState.player_inventory.use_item(selected_item_id)
		print("[背包] 使用物品: ", result)
		_refresh_inventory()

func _on_discard():
	if selected_item_id:
		GameState.player_inventory.remove_item(selected_item_id, 1)
		print("[背包] 丢弃物品: ", selected_item_id)
		_refresh_inventory()

func _on_close():
	queue_free()

func _on_tab_all():
	_refresh_inventory()

func _on_tab_equip():
	_filter_by_type(ItemData.ItemType.EQUIP)

func _on_tab_pill():
	_filter_by_type(ItemData.ItemType.PILl)

func _on_tab_consumable():
	_filter_by_type(ItemData.ItemType.CONSUMABLE)

func _on_tab_book():
	_filter_by_type(ItemData.ItemType.BOOK)

func _on_tab_manual():
	_filter_by_type(ItemData.ItemType.MANUAL)

func _on_tab_quest():
	_filter_by_type(ItemData.ItemType.QUEST)

func _on_tab_other():
	_filter_by_type(ItemData.ItemType.OTHER)

func _filter_by_type(item_type: ItemData.ItemType):
	# 清空网格
	for child in item_grid.get_children():
		child.free()

	var inventory = GameState.player_inventory
	var items = inventory.get_items_by_type(item_type)
	for entry in items:
		var item = entry["item"]
		var qty = entry["quantity"]

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		btn.text = "%s x%d" % [item.name, qty]
		btn.pressed.connect(_on_item_selected.bind(item.item_id))
		item_grid.add_child(btn)
