extends Node2D

@onready var time_display: Label = $TimeDisplay
@onready var test_log: Label = $TestLog
@onready var controls: VBoxContainer = $Controls

var test_results = []
var day_count_before = 0

func _ready():
	_add_button("+1天", func(): _advance_1_day())
	_add_button("+10天", func(): _advance_10_days())
	_add_button("+30天(跨季)", func(): _advance_30_days())
	_add_button("设置x10速度", func(): _set_speed_10x())
	_add_button("设置x50速度", func(): _set_speed_50x())
	_add_button("暂停", func(): _pause_time())
	_add_button("恢复", func(): _resume_time())
	_add_button("执行测试", func(): _run_all_tests())

	TimeManager.day_passed.connect(_on_day_passed)
	TimeManager.season_changed.connect(_on_season_changed)
	_update_display()

func _add_button(text: String, cb: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 36)
	btn.pressed.connect(cb)
	controls.add_child(btn)

func _update_display():
	var ts = TimeManager.time_scale
	var ts_str = "已暂停" if ts == 0 else "x%.0f" % ts
	time_display.text = "=== 时间状态 ===\n"
	time_display.text += "当前日: 第 %d 天\n" % TimeManager.current_day
	time_display.text += "当前季节: %s\n" % TimeManager.current_season
	time_display.text += "时间速度: %s\n" % ts_str
	time_display.text += "\n季节循环: 春→夏→秋→冬→春 (30天/季)"

func _advance_1_day():
	day_count_before = TimeManager.current_day
	TimeManager.advance_day()
	_update_display()
	_update_log("+1天: 第%d天" % TimeManager.current_day)

func _advance_10_days():
	for i in range(10):
		TimeManager.advance_day()
	_update_display()
	_update_log("+10天: 第%d天, 季节=%s" % [TimeManager.current_day, TimeManager.current_season])

func _advance_30_days():
	for i in range(30):
		TimeManager.advance_day()
	_update_display()
	_update_log("+30天: 第%d天, 季节=%s" % [TimeManager.current_day, TimeManager.current_season])

func _set_speed_10x():
	TimeManager.set_time_scale(10.0)
	_update_display()
	_update_log("速度设置为 x10")

func _set_speed_50x():
	TimeManager.set_time_scale(50.0)
	_update_display()
	_update_log("速度设置为 x50")

func _pause_time():
	TimeManager.set_time_scale(0.0)
	_update_display()
	_update_log("时间已暂停")

func _resume_time():
	TimeManager.set_time_scale(1.0)
	_update_display()
	_update_log("时间已恢复 (x1)")

func _on_day_passed(day: int):
	test_results.append("day_passed信号: 第%d天" % day)
	_update_log("信号触发: day_passed(第%d天)" % day)

func _on_season_changed(season: String):
	test_results.append("season_changed信号: %s" % season)
	_update_log("信号触发: season_changed(%s)" % season)

func _update_log(msg: String):
	test_log.text = msg
	print("[时间测试] " + msg)

func _run_all_tests():
	test_results.clear()
	var passed = 0
	var failed = 0

	# 保存初始状态
	var initial_day = TimeManager.current_day
	var initial_season = TimeManager.current_season

	# 测试1: advance_day() 正确增加
	var test_day = initial_day + 1
	TimeManager.advance_day()
	if TimeManager.current_day == test_day:
		test_results.append("[PASS] advance_day() 正确增加1天")
		passed += 1
	else:
		test_results.append("[FAIL] advance_day() day=%d 期望=%d" % [TimeManager.current_day, test_day])
		failed += 1

	# 测试2: 30天后季节切换
	TimeManager.current_day = 1  # 重置
	TimeManager.current_season = "春"
	for i in range(30):
		TimeManager.advance_day()
	var expected_season = "夏"
	if TimeManager.current_season == expected_season:
		test_results.append("[PASS] 30天后正确切换到夏")
		passed += 1
	else:
		test_results.append("[FAIL] 30天后季节=%s 期望=%s" % [TimeManager.current_season, expected_season])
		failed += 1

	# 测试3: 季节循环
	TimeManager.current_day = 120
	TimeManager.current_season = "春"
	TimeManager.advance_day()
	# day=121, 121/30=4, 4%4=0 => 春 (循环正确)
	if TimeManager.current_season == "春":
		test_results.append("[PASS] 120天后季节循环正确")
		passed += 1
	else:
		test_results.append("[FAIL] 120天后季节=%s 期望=春" % TimeManager.current_season)
		failed += 1

	# 测试4: set_time_scale 有效
	TimeManager.set_time_scale(10.0)
	if TimeManager.time_scale == 10.0:
		test_results.append("[PASS] set_time_scale(10) 生效")
		passed += 1
	else:
		test_results.append("[FAIL] time_scale=%s 期望=10" % TimeManager.time_scale)
		failed += 1

	TimeManager.set_time_scale(0.0)
	if TimeManager.time_scale == 0.0:
		test_results.append("[PASS] set_time_scale(0) 暂停生效")
		passed += 1
	else:
		test_results.append("[FAIL] time_scale=%s 期望=0" % TimeManager.time_scale)
		failed += 1

	# 恢复默认
	TimeManager.set_time_scale(1.0)
	TimeManager.current_day = initial_day
	TimeManager.current_season = initial_season

	test_log.text = "=== 测试结果 ===\n" + "\n".join(test_results) + "\n\n总计: %d 通过, %d 失败" % [passed, failed]
	print("\n=== 时间系统测试 ===")
	for r in test_results:
		print(r)
	print("总计: %d 通过, %d 失败\n" % [passed, failed])

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/test_menu.tscn")
	elif event.is_action_pressed("ui_accept"):
		_run_all_tests()
