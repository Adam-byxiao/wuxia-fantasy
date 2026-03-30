extends Control

@onready var leave_btn: Button = $VBox/Actions/LeaveBtn
@onready var manage_btn: Button = $VBox/Actions/ManageBtn
@onready var donate_btn: Button = $VBox/Actions/DonateBtn

func _ready():
	leave_btn.pressed.connect(_on_back)
	manage_btn.pressed.connect(_on_manage)
	donate_btn.pressed.connect(_on_donate)

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/town_scene.tscn")

func _on_manage():
	$VBox/SectInfo/SectName.text = "[提示] 宗门管理功能暂未实现"

func _on_donate():
	$VBox/SectInfo/SectName.text = "[提示] 捐献功能暂未实现"
