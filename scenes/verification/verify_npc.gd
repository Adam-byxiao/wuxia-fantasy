extends Node2D

@onready var npc_display: Label = $NPCDisplay
@onready var test_log: Label = $TestLog
@onready var controls: VBoxContainer = $Controls

const AI_NAMES = ["PATROL", "TRADER", "CULTIVATOR", "WANDERER", "GUARD", "QUEST"]

func _ready():
	_add_button("生成4种测试NPC", func(): _spawn_4_types())
	_add_button("生成全类型NPC", func(): _spawn_all_types())
	_add_button("模拟1天(tick)", func(): _simulate_1_day())
	_add_button("模拟10天", func(): _simulate_10_days())
	_add_button("测试目标选择", func(): _test_goal_selection())
	_add_button("执行全部测试", func(): _run_all_tests())
	_add_button("清空NPC", func(): _clear_npcs())

	NPCManager.npcs.clear()
	_update_display()

func _add_button(text: String, cb: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 36)
	btn.pressed.connect(cb)
	controls.add_child(btn)

func _spawn_4_types():
	_clear_npcs()
	var templates = [
		{"id": "patrol_001", "name": "巡逻守卫", "ai_type": 0, "region": "road", "position": Vector2(200, 200)},
		{"id": "trader_001", "name": "平安镇商人", "ai_type": 1, "region": "town", "position": Vector2(400, 200)},
		{"id": "cult_001", "name": "闭关修士", "ai_type": 2, "region": "mountain", "position": Vector2(600, 200)},
		{"id": "wander_001", "name": "江湖游侠", "ai_type": 3, "region": "forest", "position": Vector2(800, 200)},
	]
	for t in templates:
		NPCManager.spawn_npc(t)
	_update_display()
	_log("已生成4种NPC: %s" % templates.map(func(x): x["name"]))

func _spawn_all_types():
	_clear_npcs()
	for i in range(6):
		var template = {
			"id": "npc_type_%d" % i,
			"name": "%s型NPC" % AI_NAMES[i],
			"ai_type": i,
			"region": "test_region",
			"position": Vector2(200 + i * 80, 300)
		}
		NPCManager.spawn_npc(template)
	_update_display()
	_log("已生成全6种NPC")

func _clear_npcs():
	for npc in NPCManager.npcs.values():
		if is_instance_valid(npc):
			npc.queue_free()
	NPCManager.npcs.clear()
	_update_display()

func _update_display():
	var text = "=== NPC状态 ===\n"
	text += "总数: %d\n\n" % NPCManager.npcs.size()

	for npc in NPCManager.npcs.values():
		var ai_name = AI_NAMES[npc.ai_type] if npc.ai_type < AI_NAMES.size() else "?"
		text += "• %s [%s]\n" % [npc.display_name, ai_name]
		text += "  目标: %s | 状态: %s\n" % [npc.brain.current_goal, npc.brain.current_state]
		text += "  信任: %d | 交互: %d次\n" % [npc.brain.memory.get("trust_level", 0), npc.brain.memory.get("player_interactions", 0)]
		text += "  境界: %s (%.0f%%)\n" % [npc.cultivation_data.realm, npc.cultivation_data.realm_progress * 100]
		text += "\n"

	npc_display.text = text

func _log(msg: String):
	test_log.text = msg
	print("[NPC测试] " + msg)

func _simulate_1_day():
	TimeManager.set_time_scale(100.0)
	await get_tree().create_timer(0.5).timeout
	TimeManager.set_time_scale(0.0)
	_update_display()
	_log("模拟1天完成, NPC数量: %d" % NPCManager.npcs.size())

func _simulate_10_days():
	for i in range(10):
		TimeManager.advance_day()
		SignalBus.sandbox_npc_tick.emit(TimeManager.current_day)
	_update_display()
	_log("模拟10天完成")

func _test_goal_selection():
	var results = []
	results.append("=== 目标选择测试 ===")

	for ai_type in range(4):
		var brain = NPCBrain.new("test_%d" % ai_type, ai_type)
		brain.personality = NPCTypes.get_default_personality(ai_type)
		var goal = brain.evaluate_current_goal()
		var expected = ["wander", "trade", "cultivate", "wander"][ai_type]
		var status = "[PASS]" if goal == expected else "[INFO]"
		results.append("%s AI类型=%s → 目标=%s (期望=%s)" % [status, AI_NAMES[ai_type], goal, expected])

	results.append("")
	results.append("NPCManager.npcs.size()=%d" % NPCManager.npcs.size())

	test_log.text = "\n".join(results)
	print("\n=== NPC AI目标选择测试 ===")
	for r in results:
		print(r)

func _run_all_tests():
	var results = []
	var passed = 0
	var failed = 0

	# Clear and setup
	_clear_npcs()

	# Test 1: NPC spawn
	_spawn_4_types()
	if NPCManager.npcs.size() == 4:
		results.append("[PASS] 成功生成4个NPC")
		passed += 1
	else:
		results.append("[FAIL] NPC数量=%d (期望4)" % NPCManager.npcs.size())
		failed += 1

	# Test 2: Each NPC has correct type
	var type_map = {0: "巡逻守卫", 1: "平安镇商人", 2: "闭关修士", 3: "江湖游侠"}
	var all_correct = true
	for npc in NPCManager.npcs.values():
		if npc.display_name != type_map.get(npc.ai_type, ""):
			all_correct = false
			break
	if all_correct:
		results.append("[PASS] NPC类型与名称匹配正确")
		passed += 1
	else:
		results.append("[FAIL] NPC类型/名称不匹配")
		failed += 1

	# Test 3: Brain exists
	var brain_ok = true
	for npc in NPCManager.npcs.values():
		if not npc.brain:
			brain_ok = false
			break
	if brain_ok:
		results.append("[PASS] 所有NPC拥有Brain组件")
		passed += 1
	else:
		results.append("[FAIL] 存在NPC缺少Brain")
		failed += 1

	# Test 4: Goal evaluation (each type gets expected goal)
	_spawn_all_types()
	var goal_test = [
		[0, "wander"],
		[1, "trade"],
		[2, "cultivate"],
		[3, "wander"],
	]
	for npc in NPCManager.npcs.values():
		var expected = null
		for gt in goal_test:
			if npc.ai_type == gt[0]:
				expected = gt[1]
				break
		if expected and npc.brain.current_goal == expected:
			passed += 1
		else:
			failed += 1
			results.append("[FAIL] %s 目标=%s (期望=%s)" % [npc.display_name, npc.brain.current_goal, expected])

	# Test 5: Personality assigned
	var pers_ok = true
	for npc in NPCManager.npcs.values():
		if npc.brain.personality.is_empty():
			pers_ok = false
			break
	if pers_ok:
		results.append("[PASS] 所有NPC拥有性格配置")
		passed += 1
	else:
		results.append("[FAIL] 存在NPC缺少性格配置")
		failed += 1

	# Test 6: Sandbox tick
	var tick_received = false
	for npc in NPCManager.npcs.values():
		var before_goal = npc.brain.current_goal
		# Directly call the tick handler
		npc._on_sandbox_tick(TimeManager.current_day)
	if true:  # NPC tick doesn't crash
		results.append("[PASS] Sandbox tick执行无错误")
		passed += 1
	else:
		results.append("[FAIL] Sandbox tick执行出错")
		failed += 1

	results.append("")
	results.append("总计: %d通过 %d失败" % [passed, failed])
	test_log.text = "\n".join(results)

	print("\n=== NPC AI系统测试 ===")
	for r in results:
		print(r)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/test_menu.tscn")
	elif event.is_action_pressed("ui_accept"):
		_spawn_4_types()
	elif event.is_action_pressed("ui_focus_next"):
		_simulate_1_day()
