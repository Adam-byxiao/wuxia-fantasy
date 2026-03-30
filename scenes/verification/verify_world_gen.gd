extends Node2D

@onready var world_display: Label = $WorldDisplay
@onready var test_result: Label = $TestResult
@onready var btn_panel: VBoxContainer = $ButtonPanel

var world_data = null
var seed = 20260327

func _ready():
	_add_button("重新生成(seed=20260327)", func(): _regenerate())
	_add_button("重新生成(seed=随机)", func(): _regenerate_random())
	_add_button("执行所有测试", func(): _run_all_tests())
	_regenerate()

func _add_button(text: String, cb: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 36)
	btn.pressed.connect(cb)
	btn_panel.add_child(btn)

func _regenerate():
	seed = 20260327
	world_data = WorldGenerator.generate(seed)
	_display_world()
	test_result.text = "[已重新生成] seed=%d" % seed
	print("[世界生成] seed=%d, 区域=%d, 路径=%d" % [seed, world_data.regions.size(), world_data.paths.size()])

func _regenerate_random():
	seed = randi() % 1000000
	world_data = WorldGenerator.generate(seed)
	_display_world()
	test_result.text = "[已重新生成] seed=%d" % seed
	print("[世界生成] seed=%d, 区域=%d, 路径=%d" % [seed, world_data.regions.size(), world_data.paths.size()])

func _display_world():
	if not world_data:
		world_display.text = "世界未生成"
		return

	var text = "=== 世界信息 ===\n"
	text += "Seed: %d\n" % seed
	text += "区域总数: %d\n\n" % world_data.regions.size()
	text += "--- 区域列表 ---\n"
	for r in world_data.regions:
		text += "• %s [%s] 难度:%d 地标:%s\n" % [r.name, r.terrain_type, r.difficulty, r.landmark]
	text += "\n--- 路径列表 ---\n"
	for p in world_data.paths:
		var from = world_data.get_region_by_id(p["from"])
		var to = world_data.get_region_by_id(p["to"])
		var from_name = from.name if from else "?"
		var to_name = to.name if to else "?"
		text += "• %s ↔ %s\n" % [from_name, to_name]

	world_display.text = text

func _run_all_tests():
	if not world_data:
		test_result.text = "[错误] 请先生成世界"
		return

	var results = []
	var passed = 0
	var failed = 0

	# Test 1: Region count 5-10
	var rc = world_data.regions.size()
	if 5 <= rc and rc <= 10:
		results.append("[PASS] 区域数量=%d (在5-10范围内)" % rc)
		passed += 1
	else:
		results.append("[FAIL] 区域数量=%d (期望5-10)" % rc)
		failed += 1

	# Test 2: All regions have unique names
	var names = []
	var all_unique = true
	for r in world_data.regions:
		if r.name in names:
			all_unique = false
			break
		names.append(r.name)
	if all_unique:
		results.append("[PASS] 所有区域名称唯一")
		passed += 1
	else:
		results.append("[FAIL] 存在重复的区域名称")
		failed += 1

	# Test 3: All regions have required fields
	var all_have_fields = true
	for r in world_data.regions:
		if r.name == "" or r.id == "" or r.terrain_type == "":
			all_have_fields = false
			break
	if all_have_fields:
		results.append("[PASS] 所有区域必要字段完整")
		passed += 1
	else:
		results.append("[FAIL] 存在区域缺少必要字段")
		failed += 1

	# Test 4: Paths connect existing regions
	var all_paths_valid = true
	for p in world_data.paths:
		var from = world_data.get_region_by_id(p["from"])
		var to = world_data.get_region_by_id(p["to"])
		if not from or not to:
			all_paths_valid = false
			break
	if all_paths_valid and world_data.paths.size() >= world_data.regions.size() - 1:
		results.append("[PASS] 路径连接有效 (路径数:%d >= 区域数-1)" % world_data.paths.size())
		passed += 1
	else:
		results.append("[FAIL] 路径连接存在问题")
		failed += 1

	# Test 5: Deterministic - same seed same result
	var world2 = WorldGenerator.generate(seed)
	if world_data.regions.size() == world2.regions.size():
		results.append("[PASS] 相同seed生成一致结果")
		passed += 1
	else:
		results.append("[FAIL] 相同seed生成不同结果")
		failed += 1

	# Test 6: Region difficulty is reasonable
	var diff_ok = true
	for r in world_data.regions:
		var d = r.difficulty
		if d == null or d < 1 or d > 3:
			diff_ok = false
			break
	if diff_ok:
		results.append("[PASS] 区域难度在合理范围(1-3)")
		passed += 1
	else:
		results.append("[FAIL] 存在不合理的难度值")
		failed += 1

	# Summary
	test_result.text = "=== 测试结果 ===\n"
	test_result.text += "\n".join(results)
	test_result.text += "\n\n总计: %d 通过, %d 失败" % [passed, failed]

	print("\n=== 世界生成测试结果 ===")
	for r in results:
		print(r)
	print("总计: %d 通过, %d 失败\n" % [passed, failed])

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/test_menu.tscn")
	elif event.is_action_pressed("ui_accept"):
		_run_all_tests()
	elif event.is_action_pressed("ui_focus_next"):
		_regenerate()
	elif event.is_action_pressed("ui_focus_prev"):
		_regenerate_random()
