extends Control

@onready var gold_label: Label = $Margin/VBox/TitleBar/GoldLabel
@onready var leave_btn: Button = $Margin/VBox/BottomBar/LeaveBtn

func _ready():
	leave_btn.pressed.connect(_on_back)
	_update_gold()

func _update_gold():
	gold_label.text = "金币: %d" % GameState.player_inventory.gold

func _on_back():
	get_tree().change_scene_to_file("res://scenes/ui/town_scene.tscn")
