class_name BattleResult
extends Control

@onready var result_title: Label = $VBox/ResultTitle
@onready var exp_label: Label = $VBox/Rewards/ExpLabel
@onready var gold_label: Label = $VBox/Rewards/GoldLabel
@onready var items_label: Label = $VBox/Rewards/ItemsLabel
@onready var continue_btn: Button = $VBox/ContinueBtn

var victory: bool = false
var rewards: Dictionary = {}

func _ready():
	continue_btn.pressed.connect(_on_continue)

func show_result(vict: bool, rew: Dictionary):
	victory = vict
	rewards = rew

	if victory:
		result_title.text = "★ 战斗胜利！★"
		result_title.add_theme_color_override("font_color", Color.GOLD)
	else:
		result_title.text = "✗ 战斗失败..."
		result_title.add_theme_color_override("font_color", Color.GRAY)

	exp_label.text = "获得经验: %d" % rew.get("exp", 0)
	gold_label.text = "获得金币: %d" % rew.get("gold", 0)

	var loot = rew.get("loot", [])
	if loot.is_empty():
		items_label.text = "获得物品: 无"
	else:
		var item_names = loot.map(func(item): return item.get("name", "未知"))
		items_label.text = "获得物品: %s" % ", ".join(item_names)

func _on_continue():
	# 发送信号通知游戏继续
	SignalBus.battle_result_continued.emit(victory, rewards)
	queue_free()
