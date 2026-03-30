extends Control

@onready var new_game_btn: Button = $CenterVBox/NewGameBtn
@onready var continue_btn: Button = $CenterVBox/ContinueBtn
@onready var settings_btn: Button = $CenterVBox/SettingsBtn
@onready var about_btn: Button = $CenterVBox/AboutBtn

const TOWN_SCENE = "res://scenes/ui/town_scene.tscn"
const SETTINGS_SCENE = "res://scenes/ui/settings.tscn"

var _selection = 0
var _buttons: Array[Button] = []

func _ready():
	_buttons = [new_game_btn, continue_btn, settings_btn, about_btn]
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	about_btn.pressed.connect(_on_about)
	_update_selection()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_up"):
		_change_selection(-1)
	elif event.is_action_pressed("ui_down"):
		_change_selection(1)
	elif event.is_action_pressed("ui_accept"):
		_activate_selection()

func _change_selection(delta: int):
	if _buttons.is_empty():
		return
	_selection = (_selection + delta + _buttons.size()) % _buttons.size()
	_update_selection()

func _update_selection():
	for i in range(_buttons.size()):
		_buttons[i].text = _buttons[i].text.strip_edges().replace("► ", "")
	if _selection < _buttons.size():
		_buttons[_selection].text = "► " + _buttons[_selection].text

func _activate_selection():
	if _selection < _buttons.size():
		_buttons[_selection].pressed.emit()

func _on_new_game():
	GameState.reset()
	WorldGenerator.generate(20260327)
	get_tree().change_scene_to_file(TOWN_SCENE)

func _on_continue():
	if SaveSystem.has_save():
		SaveSystem.load_game()
	get_tree().change_scene_to_file(TOWN_SCENE)

func _on_settings():
	get_tree().change_scene_to_file(SETTINGS_SCENE)

func _on_about():
	pass
