extends Control

@onready var leave_btn: Button = $VBox/Actions/LeaveBtn
@onready var rest_btn: Button = $VBox/Actions/RestBtn
@onready var gossip_btn: Button = $VBox/Actions/GossipBtn
@onready var info_text: Label = $VBox/Desc

func _ready():
	leave_btn.pressed.connect(_on_back)
	rest_btn.pressed.connect(_on_rest)
	gossip_btn.pressed.connect(_on_rumor)
	_update_display()

func _update_display():
	$VBox/Desc.text = "疲劳的旅人可以在此处休息"

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/town_scene.tscn")

func _on_rest():
	print("[客栈] 休息")
	$VBox/Desc.text = "[已休息] 生命和内力已恢复"

func _on_rumor():
	print("[客栈] 打听消息")
	# TODO: 触发随机事件
	$VBox/Desc.text = "[消息] 最近江湖不太平，有人说在北方山脉发现了遗迹..."
