extends Control

@onready var close_btn: Button = $Margin/VBox/TitleBar/CloseBtn
@onready var quest_list_vbox: VBoxContainer = $Margin/VBox/ContentArea/QuestList/QuestListVBox
@onready var quest_desc: RichTextLabel = $Margin/VBox/ContentArea/QuestDetail/QuestDesc

func _ready():
	close_btn.pressed.connect(_on_close)
	_show_placeholder_quests()

func _show_placeholder_quests():
	# Clear existing
	for child in quest_list_vbox.get_children():
		child.free()

	var placeholder_quests = [
		{"title": "初入江湖", "desc": "前往平安镇客栈打听消息", "status": "进行中"},
		{"title": "修炼之路", "desc": "在演武场击败3个敌人", "status": "未开始"},
	]
	for q in placeholder_quests:
		var btn = Button.new()
		btn.text = "[%s] %s" % [q["status"], q["title"]]
		btn.pressed.connect(_on_quest_selected.bind(q))
		quest_list_vbox.add_child(btn)

	quest_desc.text = "选择一个任务查看详情"

func _on_quest_selected(quest: Dictionary):
	quest_desc.text = "=== %s ===\n\n%s\n\n状态: %s" % [quest["title"], quest["desc"], quest["status"]]

func _on_close():
	queue_free()
