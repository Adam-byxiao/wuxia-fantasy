class_name ItemSelect
extends Control

signal item_selected(item_id: String, target_index: int)
signal closed()

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var item_list: VBoxContainer = $Panel/VBox/ItemList
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var battle_manager: BattleManager
var available_items: Array[Dictionary] = []  # {item_id, item, count}

func _ready():
	close_btn.pressed.connect(_on_close)

func initialize(bm: BattleManager):
	battle_manager = bm
	_refresh_item_list()

func _refresh_item_list():
	# 清空现有列表
	for child in item_list.get_children():
		child.queue_free()

	# 获取背包中的战斗可用物品
	available_items.clear()
	var inv = GameState.player_inventory
	if inv:
		for item_id in inv.items.keys():
			var entry = inv.items[item_id]
			var item = entry["item"] as ItemData
			var count = entry["count"] as int

			if item and item.can_use() and (item.type == ItemData.ItemType.PILl or item.type == ItemData.ItemType.CONSUMABLE):
				available_items.append({"item_id": item_id, "item": item, "count": count})

	# 显示物品列表
	if available_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "背包中没有可用物品"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		item_list.add_child(empty_label)
	else:
		for entry in available_items:
			var item = entry["item"]
			var item_btn = Button.new()
			item_btn.custom_minimum_size = Vector2(300, 45)

			var effect_text = ""
			if item.heal_amount > 0:
				effect_text = "恢复 %d HP" % item.heal_amount
			elif item.qi恢复_amount > 0:
				effect_text = "恢复 %d 气" % item.qi恢复_amount
			elif item.damage_amount > 0:
				effect_text = "造成 %d 伤害" % item.damage_amount

			item_btn.text = "%s x%d | %s" % [item.name, entry["count"], effect_text]
			item_btn.pressed.connect(_on_item_clicked.bind(entry["item_id"]))
			item_list.add_child(item_btn)

func _on_item_clicked(item_id: String):
	# 查找物品
	var entry = available_items.find(func(e): return e["item_id"] == item_id)
	if entry < 0:
		return

	var item = available_items[entry]["item"] as ItemData

	# 根据物品类型决定是否需要选择目标
	if item.type == ItemData.ItemType.CONSUMABLE and item.damage_amount > 0:
		# 暗器需要选择目标
		_show_target_selection(item_id)
	else:
		# 丹药直接使用
		item_selected.emit(item_id, -1)  # -1 表示不需要目标
		queue_free()

func _show_target_selection(item_id: String):
	# 清空物品列表，显示敌人选择
	for child in item_list.get_children():
		child.queue_free()

	title_label.text = "选择目标"

	var enemies = battle_manager.get_enemies()
	for i in enemies.size():
		var enemy = enemies[i]
		var target_btn = Button.new()
		target_btn.custom_minimum_size = Vector2(300, 40)

		var text = "%s | HP: %d/%d" % [
			enemy.name, enemy.current_health, enemy.get_max_health_with_realm()]

		if not enemy.is_alive:
			text += " [已死亡]"
			target_btn.disabled = true
			target_btn.add_theme_color_override("font_color", Color.GRAY)

		target_btn.text = text
		target_btn.pressed.connect(_on_target_selected.bind(item_id, i))
		item_list.add_child(target_btn)

	# 添加返回按钮
	var back_btn = Button.new()
	back_btn.text = "返回"
	back_btn.pressed.connect(_on_back_to_items)
	item_list.add_child(back_btn)

func _on_target_selected(item_id: String, target_index: int):
	item_selected.emit(item_id, target_index)
	queue_free()

func _on_back_to_items():
	title_label.text = "选择物品"
	_refresh_item_list()

func _on_close():
	closed.emit()
	queue_free()
