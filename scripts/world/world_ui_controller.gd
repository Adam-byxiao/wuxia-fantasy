extends Node

const PANEL_WIDTH := 400.0
const PANEL_MARGIN := 20.0

var main_root: Node2D
var ui_layer: CanvasLayer
var ui_root: Control
var info_panel: PanelContainer
var button_panel: PanelContainer
var location_prompt: Label
var debug_console: Label
var _last_viewport_size: Vector2 = Vector2.ZERO
var _last_time_scale: float = 1.0
var _sandbox_mode: bool = false

func _ready() -> void:
	main_root = get_parent() as Node2D
	if main_root == null:
		return
	ui_layer = main_root.get_node("UILayer")

	SignalBus.world_generated.connect(_on_world_generated)
	TimeManager.day_passed.connect(_on_day_passed)
	TimeManager.season_changed.connect(_on_season_changed)
	_setup_ui()
	_setup_button_panel()
	_refresh_world_info()
	_refresh_time_display()

func _process(_delta: float) -> void:
	_update_layout()
	_refresh_world_info()

func _setup_ui() -> void:
	if ui_root != null and is_instance_valid(ui_root):
		ui_root.queue_free()

	ui_root = Control.new()
	ui_root.name = "WorldUIRoot"
	ui_layer.add_child(ui_root)

	info_panel = PanelContainer.new()
	info_panel.name = "InfoPanel"
	ui_root.add_child(info_panel)

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 12.0
	vbox.offset_top = 12.0
	vbox.offset_right = -12.0
	vbox.offset_bottom = -12.0
	info_panel.add_child(vbox)

	var title = Label.new()
	title.text = "=== \u4e16\u754c\u5730\u56fe ==="
	vbox.add_child(title)

	var world_info = Label.new()
	world_info.name = "WorldInfo"
	vbox.add_child(world_info)

	var status = Label.new()
	status.name = "StatusLabel"
	status.text = "\n[\u6a21\u5f0f] \u73a9\u5bb6\u63a7\u5236\n\u79fb\u52a8: WASD"
	vbox.add_child(status)

	location_prompt = Label.new()
	location_prompt.name = "LocationPrompt"
	location_prompt.text = ""
	ui_root.add_child(location_prompt)

	debug_console = Label.new()
	debug_console.name = "DebugConsole"
	debug_console.text = "\u4e16\u754c\u5730\u56fe\u5df2\u5c31\u7eea"
	ui_root.add_child(debug_console)

	_update_layout()

func _setup_button_panel() -> void:
	button_panel = PanelContainer.new()
	button_panel.name = "ButtonPanel"
	ui_root.add_child(button_panel)

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 12.0
	vbox.offset_top = 12.0
	vbox.offset_right = -12.0
	vbox.offset_bottom = -12.0
	button_panel.add_child(vbox)
	vbox.add_child(_make_label("=== \u8c03\u8bd5\u9762\u677f ===", Color(1, 0.84, 0)))
	vbox.add_child(_make_spacer(10))

	var sandbox_btn = _make_button("\u5207\u6362\u6c99\u76d2\u6a21\u5f0f", Color(0.2, 0.6, 0.9))
	sandbox_btn.pressed.connect(_on_sandbox_btn)
	vbox.add_child(sandbox_btn)
	vbox.add_child(_make_spacer(6))

	vbox.add_child(_make_label("\u65f6\u95f4\u63a7\u5236", Color(0.9, 0.9, 0.9)))
	var time_hbox = HBoxContainer.new()
	time_hbox.add_child(_make_button("-", Color(0.8, 0.3, 0.3), _on_time_slower))
	time_hbox.add_child(_make_label("  \u65f6\u95f4  ", Color(1, 1, 0.5)))
	time_hbox.add_child(_make_button("+", Color(0.3, 0.8, 0.3), _on_time_faster))
	vbox.add_child(time_hbox)
	vbox.add_child(_make_button("\u6682\u505c/\u6062\u590d", Color(0.7, 0.7, 0.3), _on_pause_time))
	vbox.add_child(_make_spacer(6))

	vbox.add_child(_make_button("\u663e\u793a NPC \u72b6\u6001", Color(0.8, 0.5, 0.2), _on_show_npcs))
	vbox.add_child(_make_button("\u751f\u6210\u6d4b\u8bd5 NPC", Color(0.5, 0.3, 0.8), _on_spawn_test_npcs))
	vbox.add_child(_make_spacer(10))

	var time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = "\u901f\u5ea6: x1"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_label)

	_update_layout()

func _update_layout() -> void:
	if ui_root == null or not is_instance_valid(ui_root):
		return

	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == _last_viewport_size:
		return
	_last_viewport_size = viewport_size

	ui_root.position = Vector2.ZERO
	ui_root.size = viewport_size

	if info_panel != null:
		info_panel.position = Vector2(viewport_size.x - PANEL_WIDTH - PANEL_MARGIN, PANEL_MARGIN)
		info_panel.size = Vector2(PANEL_WIDTH, 220.0)

	if button_panel != null:
		var available_height = max(240.0, viewport_size.y - 340.0)
		button_panel.position = Vector2(viewport_size.x - PANEL_WIDTH - PANEL_MARGIN, 260.0)
		button_panel.size = Vector2(PANEL_WIDTH, min(460.0, available_height))

	if location_prompt != null:
		location_prompt.position = Vector2(PANEL_MARGIN, viewport_size.y - 44.0)
		location_prompt.size = Vector2(max(260.0, viewport_size.x - PANEL_WIDTH - PANEL_MARGIN * 3.0), 24.0)

	if debug_console != null:
		debug_console.position = Vector2(viewport_size.x - PANEL_WIDTH - PANEL_MARGIN, viewport_size.y - 48.0)
		debug_console.size = Vector2(PANEL_WIDTH, 28.0)

func _make_label(text: String, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label

func _make_spacer(height: int) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size.y = height
	return spacer

func _make_button(label_text: String, color: Color, callback: Callable = Callable()) -> Button:
	var button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(320, 40)
	button.add_theme_color_override("font_color", color)
	if callback.is_valid():
		button.pressed.connect(callback)
	return button

func _on_world_generated(_world: WorldData) -> void:
	_refresh_world_info()

func _refresh_world_info() -> void:
	var world_info = ui_layer.find_child("WorldInfo", true, false)
	var world = GameState.world_data
	if world_info == null or world == null:
		return

	world_info.text = "\u533a\u57df\u6570: %d\n\u8def\u5f84\u6570: %d\n\u5730\u70b9\u6570: %d\n\u5f53\u524d\u65e5\u671f: \u7b2c %d \u5929\uff08%s\uff09" % [
		world.regions.size(),
		world.paths.size(),
		world.locations.size(),
		TimeManager.current_day,
		TimeManager.current_season
	]

func _refresh_time_display() -> void:
	var label = ui_layer.find_child("TimeLabel", true, false)
	if label == null:
		return
	if TimeManager.time_scale == 0:
		label.text = "\u5df2\u6682\u505c"
	else:
		label.text = "\u7b2c %d \u5929 | %s | \u901f\u5ea6 x%.0f" % [
			TimeManager.current_day,
			TimeManager.current_season,
			TimeManager.time_scale
		]

func _on_day_passed(_day: int) -> void:
	_refresh_world_info()
	_refresh_time_display()

func _on_season_changed(_season: String) -> void:
	_refresh_world_info()
	_refresh_time_display()

func _on_sandbox_btn() -> void:
	_sandbox_mode = not _sandbox_mode
	var status = ui_layer.find_child("StatusLabel", true, false)
	var auto_runner = main_root.get_node_or_null("AutoRunner")
	if status != null:
		if _sandbox_mode:
			if auto_runner != null:
				auto_runner.process_mode = Node.PROCESS_MODE_ALWAYS
			status.text = "\n[\u6a21\u5f0f] \u6c99\u76d2\u81ea\u52a8\u8fd0\u884c"
			_update_debug("\u6c99\u76d2\u6a21\u5f0f\u5df2\u5f00\u542f")
		else:
			if auto_runner != null:
				auto_runner.process_mode = Node.PROCESS_MODE_DISABLED
			status.text = "\n[\u6a21\u5f0f] \u73a9\u5bb6\u63a7\u5236\n\u79fb\u52a8: WASD"
			_update_debug("\u6c99\u76d2\u6a21\u5f0f\u5df2\u5173\u95ed")

func _on_time_slower() -> void:
	var current = TimeManager.time_scale
	if current >= 1.0:
		TimeManager.set_time_scale(max(0.0, current - 1.0))
	else:
		TimeManager.set_time_scale(0.0)
	_refresh_time_display()

func _on_time_faster() -> void:
	var current = TimeManager.time_scale
	if current == 0:
		TimeManager.set_time_scale(_last_time_scale if _last_time_scale > 0 else 1.0)
	else:
		TimeManager.set_time_scale(current + 1.0)
	_refresh_time_display()

func _on_pause_time() -> void:
	if TimeManager.time_scale > 0:
		_last_time_scale = TimeManager.time_scale
		TimeManager.set_time_scale(0.0)
		_update_debug("\u65f6\u95f4\u5df2\u6682\u505c")
	else:
		TimeManager.set_time_scale(_last_time_scale if _last_time_scale > 0 else 1.0)
		_update_debug("\u65f6\u95f4\u5df2\u6062\u590d")
	_refresh_time_display()

func _on_show_npcs() -> void:
	var lines = [
		"=== NPC \u72b6\u6001 ===",
		"\u65e5\u671f: \u7b2c %d \u5929\uff08%s\uff09" % [TimeManager.current_day, TimeManager.current_season],
		"NPC \u6570\u91cf: %d" % NPCManager.npcs.size(),
		"\u5f53\u524d\u533a\u57df: %s" % GameState.current_region_id,
		"\u5f53\u524d\u5730\u70b9: %s" % GameState.current_location_id
	]
	_update_debug("\n".join(lines))

func _on_spawn_test_npcs() -> void:
	var templates = [
		{"id": "patrol_001", "name": "\u5b88\u536b\u5f20\u4e09", "ai_type": 0, "region": "region_starting_village", "position": Vector2(200, 200)},
		{"id": "trader_001", "name": "\u5546\u4eba\u674e\u56db", "ai_type": 1, "region": "region_market_town", "position": Vector2(320, 220)},
		{"id": "cult_001", "name": "\u9690\u4fee\u9053\u4eba", "ai_type": 2, "region": "region_north_sect", "position": Vector2(420, 180)},
		{"id": "wander_001", "name": "\u6c5f\u6e56\u6563\u4eba", "ai_type": 3, "region": "region_bamboo_forest", "position": Vector2(280, 320)}
	]

	for template in templates:
		NPCManager.spawn_npc(template)
	_update_debug("\u5df2\u751f\u6210 %d \u4e2a\u6d4b\u8bd5 NPC" % templates.size())

func _update_debug(message: String) -> void:
	var console = ui_layer.find_child("DebugConsole", true, false)
	if console != null:
		console.text = message
