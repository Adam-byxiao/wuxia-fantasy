extends Control

@onready var title_label: Label = $RootMargin/CenterPanel/VBox/Title
@onready var sect_name_label: Label = $RootMargin/CenterPanel/VBox/SectInfo/SectName
@onready var sect_level_label: Label = $RootMargin/CenterPanel/VBox/SectInfo/SectLevel
@onready var member_count_label: Label = $RootMargin/CenterPanel/VBox/SectInfo/MemberCount
@onready var sect_funds_label: Label = $RootMargin/CenterPanel/VBox/SectInfo/SectFunds
@onready var leave_btn: Button = $RootMargin/CenterPanel/VBox/Actions/LeaveBtn
@onready var manage_btn: Button = $RootMargin/CenterPanel/VBox/Actions/ManageBtn
@onready var donate_btn: Button = $RootMargin/CenterPanel/VBox/Actions/DonateBtn

func _ready() -> void:
	_apply_texts()
	leave_btn.pressed.connect(_on_back)
	manage_btn.pressed.connect(_on_manage)
	donate_btn.pressed.connect(_on_donate)

func _apply_texts() -> void:
	title_label.text = "\u95e8\u6d3e"
	sect_name_label.text = "\u95e8\u6d3e\u540d\u79f0\uff1a\u672a\u77e5"
	sect_level_label.text = "\u95e8\u6d3e\u7b49\u7ea7\uff1a1"
	member_count_label.text = "\u6210\u5458\u6570\u91cf\uff1a0"
	sect_funds_label.text = "\u95e8\u6d3e\u8d44\u91d1\uff1a0"
	manage_btn.text = "\u95e8\u6d3e\u7ba1\u7406"
	donate_btn.text = "\u6350\u732e\u8d44\u91d1"
	leave_btn.text = "\u79bb\u5f00"

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_manage() -> void:
	sect_name_label.text = "[\u63d0\u793a] \u95e8\u6d3e\u7ba1\u7406\u529f\u80fd\u6682\u672a\u5b9e\u73b0"

func _on_donate() -> void:
	sect_name_label.text = "[\u63d0\u793a] \u6350\u732e\u529f\u80fd\u6682\u672a\u5b9e\u73b0"
