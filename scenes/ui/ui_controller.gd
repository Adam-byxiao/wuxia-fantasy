class_name UIController
extends CanvasLayer

# 界面栈管理
var _panel_stack: Array[String] = []
var _panel_map: Dictionary = {}

# 常用路径
const UI_PATH = "res://scenes/ui/"

func _ready():
	# 注册所有面板
	_register_panels()
	# 监听全局UI信号
	SignalBus.ui_open_request.connect(_on_open_request)
	SignalBus.ui_close_request.connect(_on_close_request)

func _register_panels():
	_panel_map = {
		"inventory": $InventoryPanel,
		"personal": $PersonalPanel,
		"quest": $QuestPanel,
		"battle_ui": $BattleUIPanel,
		"battle_result": $BattleResultPanel,
		"dialog": $DialogPanel,
	}

	# 初始全部隐藏
	for panel in _panel_map.values():
		if panel:
			panel.visible = false

func _on_open_request(panel_name: String):
	open_panel(panel_name)

func _on_close_request(panel_name: String):
	close_panel(panel_name)

func open_panel(name: String):
	if not _panel_map.has(name):
		push_error("UIController: unknown panel " + name)
		return

	var panel = _panel_map[name]
	if not panel:
		return

	# 如果已打开，不重复添加
	if name in _panel_stack:
		return

	# 显示面板
	panel.visible = true
	_panel_stack.append(name)

	# 发出信号
	SignalBus.panel_switched.emit(name)

func close_panel(name: String):
	if not _panel_map.has(name):
		return

	var panel = _panel_map[name]
	if not panel:
		return

	# 隐藏面板
	panel.visible = false
	_panel_stack.erase(name)

func close_all():
	for name in _panel_stack:
		if _panel_map.has(name) and _panel_map[name]:
			_panel_map[name].visible = false
	_panel_stack.clear()

func is_panel_open(name: String) -> bool:
	return name in _panel_stack

func get_top_panel() -> String:
	if _panel_stack.is_empty():
		return ""
	return _panel_stack.back()

# 快捷方法
func open_inventory():
	open_panel("inventory")

func close_inventory():
	close_panel("inventory")

func open_personal():
	open_panel("personal")

func close_personal():
	close_panel("personal")

func open_quest():
	open_panel("quest")

func close_quest():
	close_panel("quest")

func open_battle_ui():
	close_all()
	open_panel("battle_ui")

func show_battle_result(victory: bool, rewards: Dictionary):
	open_panel("battle_result")
	# 通知battle_result显示内容
	var result_panel = _panel_map.get("battle_result")
	if result_panel and result_panel.has_method("show_result"):
		result_panel.show_result(victory, rewards)

func _input(event: InputEvent):
	# ESC关闭顶层面板
	if event.is_action_pressed("ui_cancel") and not _panel_stack.is_empty():
		close_panel(get_top_panel())
