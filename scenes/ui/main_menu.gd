extends Control

const MENU_MARKER := "\u25b6 "
const MAIN_WORLD_SCENE := "res://scenes/main.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings.tscn"

@onready var title_label: Label = $CenterVBox/Title
@onready var subtitle_label: Label = $CenterVBox/Subtitle
@onready var new_game_btn: Button = $CenterVBox/NewGameBtn
@onready var continue_btn: Button = $CenterVBox/ContinueBtn
@onready var settings_btn: Button = $CenterVBox/SettingsBtn
@onready var about_btn: Button = $CenterVBox/AboutBtn

var _selection := 0
var _buttons: Array[Button] = []

func _ready() -> void:
	_apply_texts()
	_buttons = [new_game_btn, continue_btn, settings_btn, about_btn]
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	about_btn.pressed.connect(_on_about)
	_update_selection()

func _apply_texts() -> void:
	title_label.text = "\u6b66\u4fa0\u6c5f\u6e56"
	subtitle_label.text = "Wuxia Sandbox RPG"
	new_game_btn.text = "\u65b0\u5f00\u6e38\u620f"
	continue_btn.text = "\u7ee7\u7eed\u6e38\u620f"
	settings_btn.text = "\u8bbe\u7f6e"
	about_btn.text = "\u5173\u4e8e"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_change_selection(-1)
	elif event.is_action_pressed("ui_down"):
		_change_selection(1)
	elif event.is_action_pressed("ui_accept"):
		_activate_selection()

func _change_selection(delta: int) -> void:
	if _buttons.is_empty():
		return
	_selection = (_selection + delta + _buttons.size()) % _buttons.size()
	_update_selection()

func _update_selection() -> void:
	for button in _buttons:
		button.text = button.text.trim_prefix(MENU_MARKER)
	if _selection < _buttons.size():
		_buttons[_selection].text = MENU_MARKER + _buttons[_selection].text

func _activate_selection() -> void:
	if _selection < _buttons.size():
		_buttons[_selection].pressed.emit()

func _on_new_game() -> void:
	GameState.reset()
	WorldGenerator.generate(20260327)
	get_tree().change_scene_to_file(MAIN_WORLD_SCENE)

func _on_continue() -> void:
	if SaveSystem.has_save():
		SaveSystem.load_game()
	get_tree().change_scene_to_file(MAIN_WORLD_SCENE)

func _on_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)

func _on_about() -> void:
	about_btn.text = "\u5173\u4e8e\uff1a\u6b66\u4fa0\u6c99\u76d2\u539f\u578b"
