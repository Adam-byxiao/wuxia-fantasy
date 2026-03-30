extends Control

@onready var title_label: Label = $RootMargin/CenterPanel/VBox/Title
@onready var volume_label: Label = $RootMargin/CenterPanel/VBox/VolumeRow/VolumeLabel
@onready var speed_label: Label = $RootMargin/CenterPanel/VBox/SpeedRow/SpeedLabel
@onready var back_btn: Button = $RootMargin/CenterPanel/VBox/BackBtn

func _ready() -> void:
	title_label.text = "\u8bbe\u7f6e"
	volume_label.text = "\u97f3\u91cf"
	speed_label.text = "\u6587\u5b57\u901f\u5ea6"
	back_btn.text = "\u8fd4\u56de"
	back_btn.pressed.connect(_on_back)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
