extends Control

@onready var inn_btn: Button = $RootMargin/MainVBox/ContentCard/LocationGrid/InnBtn
@onready var trade_guild_btn: Button = $RootMargin/MainVBox/ContentCard/LocationGrid/TradeGuildBtn
@onready var sect_btn: Button = $RootMargin/MainVBox/ContentCard/LocationGrid/SectBtn
@onready var train_ground_btn: Button = $RootMargin/MainVBox/ContentCard/LocationGrid/TrainGroundBtn
@onready var inventory_btn: Button = $RootMargin/MainVBox/BottomBar/InventoryBtn
@onready var character_btn: Button = $RootMargin/MainVBox/BottomBar/CharacterBtn
@onready var quest_btn: Button = $RootMargin/MainVBox/BottomBar/QuestBtn
@onready var leave_btn: Button = $RootMargin/MainVBox/BottomBar/LeaveBtn
@onready var info_label: Label = $RootMargin/MainVBox/BottomBar/InfoLabel
@onready var title_label: Label = $RootMargin/MainVBox/HeaderCard/HeaderBox/Title
@onready var subtitle_label: Label = $RootMargin/MainVBox/HeaderCard/HeaderBox/Subtitle

func _ready() -> void:
	_apply_texts()
	inn_btn.pressed.connect(_on_inn)
	trade_guild_btn.pressed.connect(_on_trade_guild)
	sect_btn.pressed.connect(_on_sect)
	train_ground_btn.pressed.connect(_on_train_ground)
	inventory_btn.pressed.connect(_on_inventory)
	character_btn.pressed.connect(_on_character)
	quest_btn.pressed.connect(_on_quest)
	leave_btn.pressed.connect(_on_leave)

	TimeManager.day_passed.connect(_on_day_passed)
	TimeManager.season_changed.connect(_on_season_changed)

	_update_title()
	_update_info()

func _apply_texts() -> void:
	title_label.text = "\u57ce\u9547"
	subtitle_label.text = "\u57ce\u9547\u6d3b\u52a8\u4e0e\u4eba\u9645\u4ea4\u4e92"
	inn_btn.text = "\u5ba2\u6808"
	trade_guild_btn.text = "\u5546\u4f1a"
	sect_btn.text = "\u95e8\u6d3e"
	train_ground_btn.text = "\u6f14\u6b66\u573a"
	inventory_btn.text = "\u80cc\u5305 (I)"
	character_btn.text = "\u4eba\u7269 (C)"
	quest_btn.text = "\u4efb\u52a1 (Q)"
	leave_btn.text = "\u79bb\u5f00\u57ce\u9547"

func _update_title() -> void:
	var world = GameState.world_data
	if world == null:
		return
	var location = world.get_location_by_id(GameState.current_location_id)
	if location != null:
		title_label.text = location.name

func _update_info() -> void:
	info_label.text = "\u65e5\u671f\uff1a\u7b2c %d \u5929\uff08%s\uff09" % [TimeManager.current_day, TimeManager.current_season]

func _on_day_passed(_day: int) -> void:
	_update_info()

func _on_season_changed(_season: String) -> void:
	_update_info()

func _on_inn() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/inn_scene.tscn")

func _on_trade_guild() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/trade_guild_scene.tscn")

func _on_sect() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/sect_scene.tscn")

func _on_train_ground() -> void:
	info_label.text = "\u6f14\u6b66\u573a\u529f\u80fd\u6682\u672a\u5b9e\u73b0"

func _on_inventory() -> void:
	_show_inventory_panel()

func _on_character() -> void:
	_show_character_panel()

func _on_quest() -> void:
	_show_quest_panel()

func _on_leave() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _show_inventory_panel() -> void:
	var inv_scene = load("res://scenes/ui/inventory.tscn")
	var inv = inv_scene.instantiate()
	add_child(inv)

func _show_character_panel() -> void:
	var char_scene = load("res://scenes/ui/personal/personal_root.tscn")
	var char_panel = char_scene.instantiate()
	add_child(char_panel)

func _show_quest_panel() -> void:
	var quest_scene = load("res://scenes/ui/quest_log.tscn")
	var quest = quest_scene.instantiate()
	add_child(quest)
