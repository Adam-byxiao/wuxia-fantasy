extends Control

@onready var inn_btn: Button = $LocationGrid/InnBtn
@onready var trade_guild_btn: Button = $LocationGrid/TradeGuildBtn
@onready var sect_btn: Button = $LocationGrid/SectBtn
@onready var train_ground_btn: Button = $LocationGrid/TrainGroundBtn
@onready var inventory_btn: Button = $BottomBar/InventoryBtn
@onready var character_btn: Button = $BottomBar/CharacterBtn
@onready var quest_btn: Button = $BottomBar/QuestBtn
@onready var leave_btn: Button = $BottomBar/LeaveBtn
@onready var info_label: Label = $BottomBar/InfoLabel

func _ready():
	# 位置按钮
	inn_btn.pressed.connect(_on_inn)
	trade_guild_btn.pressed.connect(_on_trade_guild)
	sect_btn.pressed.connect(_on_sect)
	train_ground_btn.pressed.connect(_on_train_ground)

	# 底部按钮
	inventory_btn.pressed.connect(_on_inventory)
	character_btn.pressed.connect(_on_character)
	quest_btn.pressed.connect(_on_quest)
	leave_btn.pressed.connect(_on_leave)

	# 监听时间变化
	TimeManager.day_passed.connect(_on_day_passed)
	TimeManager.season_changed.connect(_on_season_changed)

	_update_info()

func _update_info():
	info_label.text = "日期: 第%d天 (%s)" % [TimeManager.current_day, TimeManager.current_season]

func _on_day_passed(day: int):
	_update_info()

func _on_season_changed(season: String):
	_update_info()

func _on_inn():
	print("[城镇] 进入客栈")
	get_tree().change_scene_to_file("res://scenes/ui/inn_scene.tscn")

func _on_trade_guild():
	print("[城镇] 进入商会")
	get_tree().change_scene_to_file("res://scenes/ui/trade_guild_scene.tscn")

func _on_sect():
	print("[城镇] 进入宗门")
	get_tree().change_scene_to_file("res://scenes/ui/sect_scene.tscn")

func _on_train_ground():
	print("[城镇] 进入演武场 - 暂未实现")

func _on_inventory():
	print("[城镇] 打开背包")
	_show_inventory_panel()

func _on_character():
	print("[城镇] 打开人物面板")
	_show_character_panel()

func _on_quest():
	print("[城镇] 打开任务")
	_show_quest_panel()

func _on_leave():
	print("[城镇] 离开城镇")
	get_tree().change_scene_to_file("res://scenes/menu/test_menu.tscn")

func _show_inventory_panel():
	var inv_scene = load("res://scenes/ui/inventory.tscn")
	var inv = inv_scene.instantiate()
	add_child(inv)

func _show_character_panel():
	var char_scene = load("res://scenes/ui/personal/personal_root.tscn")
	var char_panel = char_scene.instantiate()
	add_child(char_panel)

func _show_quest_panel():
	var quest_scene = load("res://scenes/ui/quest_log.tscn")
	var quest = quest_scene.instantiate()
	add_child(quest)
