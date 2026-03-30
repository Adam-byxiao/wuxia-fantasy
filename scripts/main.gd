extends Node2D

@onready var world_layer: Node2D = $WorldLayer
@onready var ui_layer: CanvasLayer = $UILayer

var sandbox_mode: bool = false
var player: CharacterBody2D
var generated_world = null
var _last_time_scale: float = 1.0

func _ready() -> void:
	generated_world = WorldGenerator.generate(20260327)
	GameState.current_region = "starting_village"
	_spawn_player()
	_build_world_view()
	_setup_ui()
	_setup_button_panel()
	SignalBus.world_generated.connect(_on_world_generated)

func _spawn_player():
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(640, 360)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	player.add_child(col)

	var sprite = ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(32, 32)
	sprite.color = Color(0.2, 0.8, 0.2, 1)
	sprite.position = Vector2(-16, -16)
	player.add_child(sprite)

	world_layer.add_child(player)
	GameState.player_data = {"position": player.position}

func _build_world_view():
	if generated_world:
		for i in range(generated_world.regions.size()):
			var region = generated_world.regions[i]
			var label = Label.new()
			label.text = region.name
			label.position = Vector2(50 + (i % 4) * 200, 80 + (i / 4) * 60)
			label.add_to_group("region_labels")
			world_layer.add_child(label)

func _setup_ui():
	# Info panel (top-left)
	var info_panel = PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(10, 10)
	info_panel.size = Vector2(350, 180)
	ui_layer.add_child(info_panel)

	var vbox = VBoxContainer.new()
	info_panel.add_child(vbox)

	var title = Label.new()
	title.text = "=== 武侠沙盒 ==="
	vbox.add_child(title)

	var world_info = Label.new()
	world_info.name = "WorldInfo"
	if generated_world:
		world_info.text = "区域数: %d\n路径数: %d\n日期: 第 %d 天 (%s)" % [
			generated_world.regions.size(),
			generated_world.paths.size(),
			TimeManager.current_day,
			TimeManager.current_season
		]
	else:
		world_info.text = "世界未生成"
	vbox.add_child(world_info)

	var status = Label.new()
	status.name = "StatusLabel"
	status.text = "\n[模式] 玩家控制\n移动: WASD"
	vbox.add_child(status)

	# Debug console (bottom-left)
	var debug_console = Label.new()
	debug_console.name = "DebugConsole"
	debug_console.position = Vector2(10, 620)
	debug_console.size = Vector2(600, 20)
	debug_console.text = "武侠沙盒 - 武侠RPG原型"
	ui_layer.add_child(debug_console)

func _setup_button_panel():
	# Button panel (right side)
	var panel = PanelContainer.new()
	panel.name = "ButtonPanel"
	panel.position = Vector2(900, 10)
	panel.size = Vector2(200, 300)
	ui_layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.add_child(vbox)
	vbox.add_child(_make_label("=== 控制面板 ===", Color(1, 0.84, 0)))

	vbox.add_child(_make_spacer(8))

	# Sandbox toggle button
	var sandbox_btn = _make_button("切换沙盒模式", Color(0.2, 0.6, 0.9))
	sandbox_btn.pressed.connect(_on_sandbox_btn)
	vbox.add_child(sandbox_btn)

	vbox.add_child(_make_spacer(4))

	# Time controls
	vbox.add_child(_make_label("时间控制:", Color(0.9, 0.9, 0.9)))

	var time_hbox = HBoxContainer.new()
	time_hbox.add_child(_make_button("-", Color(0.8, 0.3, 0.3), _on_time_slower))
	time_hbox.add_child(_make_label("  时间  ", Color(1, 1, 0.5)))
	time_hbox.add_child(_make_button("+", Color(0.3, 0.8, 0.3), _on_time_faster))
	vbox.add_child(time_hbox)

	vbox.add_child(_make_button("暂停/恢复", Color(0.7, 0.7, 0.3), _on_pause_time))

	vbox.add_child(_make_spacer(4))

	# Debug
	vbox.add_child(_make_button("显示NPC状态", Color(0.8, 0.5, 0.2), _on_show_npcs))
	vbox.add_child(_make_button("生成测试NPC", Color(0.5, 0.3, 0.8), _on_spawn_test_npcs))

	vbox.add_child(_make_spacer(8))

	# Time display
	var time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = "速度: x1.0"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_label)

func _make_label(text: String, color: Color = Color.WHITE) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l

func _make_spacer(height: int) -> Control:
	var c = Control.new()
	c.custom_minimum_size.y = height
	return c

func _make_button(label_text: String, color: Color, callback: Callable = Callable()) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(180, 32)
	btn.add_theme_color_override("font_color", color)
	if callback.is_valid():
		btn.pressed.connect(callback)
	return btn

func _on_sandbox_btn():
	sandbox_mode = not sandbox_mode
	var status = ui_layer.find_child("StatusLabel", true, false)
	if status:
		if sandbox_mode:
			$AutoRunner.process_mode = Node.PROCESS_MODE_ALWAYS
			status.text = "\n[模式] 沙盒自动运行"
			_update_debug("沙盒模式 ON")
		else:
			$AutoRunner.process_mode = Node.PROCESS_MODE_DISABLED
			status.text = "\n[模式] 玩家控制"
			_update_debug("沙盒模式 OFF")

func _on_time_slower():
	var current = TimeManager.time_scale
	if current >= 1.0:
		TimeManager.set_time_scale(max(0, current - 1))
	else:
		TimeManager.set_time_scale(0)
	_update_time_display()

func _on_time_faster():
	var current = TimeManager.time_scale
	if current == 0:
		TimeManager.set_time_scale(_last_time_scale if _last_time_scale > 0 else 1.0)
	else:
		TimeManager.set_time_scale(current + 1)
	_update_time_display()

func _on_pause_time():
	if TimeManager.time_scale > 0:
		_last_time_scale = TimeManager.time_scale
		TimeManager.set_time_scale(0)
		_update_debug("时间暂停")
	else:
		TimeManager.set_time_scale(_last_time_scale if _last_time_scale > 0 else 1.0)
		_update_debug("时间恢复: x%.0f" % TimeManager.time_scale)
	_update_time_display()

func _update_time_display():
	var label = ui_layer.find_child("TimeLabel", true, false)
	if label:
		var ts = TimeManager.time_scale
		if ts == 0:
			label.text = "已暂停"
		else:
			label.text = "速度: x%.0f" % ts
	_update_debug("时间: %s" % label.text)

func _on_show_npcs():
	var states = "=== NPC状态 ===\n"
	states += "日期: 第 %d 天 (%s)\n" % [TimeManager.current_day, TimeManager.current_season]
	states += "NPC总数: %d" % NPCManager.npcs.size()
	_update_debug(states)

func _on_spawn_test_npcs():
	# Spawn 4 test NPCs via NPCManager
	var templates = [
		{"id": "patrol_001", "name": "守卫张三", "ai_type": 0, "region": "road", "position": Vector2(200, 200)},
		{"id": "trader_001", "name": "李掌柜", "ai_type": 1, "region": "town", "position": Vector2(400, 300)},
		{"id": "cult_001", "name": "闭关道人", "ai_type": 2, "region": "mountain", "position": Vector2(600, 150)},
		{"id": "wander_001", "name": "江湖散人", "ai_type": 3, "region": "forest", "position": Vector2(300, 400)},
	]
	for t in templates:
		var npc = NPCManager.spawn_npc(t)
		if npc:
			var label = Label.new()
			label.text = npc.display_name
			label.position = npc.position + Vector2(-20, -40)
			label.add_to_group("npc_labels")
			world_layer.add_child(label)
	_update_debug("已生成 %d 个测试NPC" % templates.size())

func _update_debug(msg: String):
	var console = ui_layer.find_child("DebugConsole", true, false)
	if console:
		console.text = str(msg)

func _physics_process(delta):
	# Player movement
	if player and not sandbox_mode:
		var move_dir = Vector2.ZERO
		if Input.is_action_pressed("move_right"): move_dir.x += 1
		if Input.is_action_pressed("move_left"): move_dir.x -= 1
		if Input.is_action_pressed("move_down"): move_dir.y += 1
		if Input.is_action_pressed("move_up"): move_dir.y -= 1

		if move_dir != Vector2.ZERO:
			player.position += move_dir.normalized() * 200.0 * delta
			GameState.player_data = {"position": player.position}

		player.position.x = clamp(player.position.x, 16, 1264)
		player.position.y = clamp(player.position.y, 16, 704)

	# Update world info
	var world_info = ui_layer.find_child("WorldInfo", true, false)
	if world_info and generated_world:
		world_info.text = "区域数: %d\n路径数: %d\n日期: 第 %d 天 (%s)" % [
			generated_world.regions.size(),
			generated_world.paths.size(),
			TimeManager.current_day,
			TimeManager.current_season
		]

func _on_world_generated(world) -> void:
	print("[Main] World generated: %d regions" % world.regions.size())
	generated_world = world
	_build_world_view()
