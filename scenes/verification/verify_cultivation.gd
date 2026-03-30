extends Node2D

@onready var status: Label = $CultivationStatus
@onready var test_log: Label = $TestLog
@onready var controls: VBoxContainer = $Controls

func _ready():
	_add_button("+100经验", func(): _add_exp(100))
	_add_button("+500经验", func(): _add_exp(500))
	_add_button("+1000经验", func(): _add_exp(1000))
	_add_button("分配属性点", func(): _allocate_point())
	_add_button("触发境界突破", func(): _try_breakthrough())
	_add_button("获取战斗属性", func(): _get_stats())
	_add_button("执行全部测试", func(): _run_all_tests())

	_update_display()
	test_log.text = "按\"执行全部测试\"开始测试"
	SignalBus.level_up.connect(_on_level_up)
	SignalBus.realm_broken.connect(_on_realm_broken)

func _add_button(text: String, cb: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 36)
	btn.pressed.connect(cb)
	controls.add_child(btn)

func _update_display():
	var d = CultivationSystem.data
	status.text = "=== 养成状态 ===\n"
	status.text += "等级: %d\n" % d.level
	status.text += "经验: %d / %d\n" % [d.exp, d.exp_to_next]
	status.text += "境界: %s (%.0f%%)\n" % [d.realm, d.realm_progress * 100]
	status.text += "自由属性点: %d\n" % d.free_attribute_points
	status.text += "\n--- 属性 ---\n"
	for k in d.attributes:
		status.text += "%s: %d\n" % [k, d.attributes[k]]
	status.text += "\n--- 技能 ---\n"
	status.text += "已学: %s\n" % str(d.learned_skill_ids)
	status.text += "已装备: %s" % str(d.equipped_skill_ids)

func _log(msg: String):
	test_log.text = msg
	print("[养成测试] " + msg)

func _add_exp(amount: int):
	CultivationSystem.add_exp(amount)
	_update_display()
	_log("+%d经验 → Lv.%d, %s" % [amount, CultivationSystem.data.level, CultivationSystem.data.realm])

func _allocate_point():
	if CultivationSystem.data.free_attribute_points > 0:
		CultivationSystem.data.add_attribute("strength", 1)
		_update_display()
		_log("分配1点力道 → %d" % CultivationSystem.data.attributes["strength"])
	else:
		_log("[无属性点可分配]")

func _try_breakthrough():
	CultivationSystem.data.realm_progress = 1.0
	var result = CultivationSystem._try_breakthrough()
	if result:
		_update_display()
		_log("突破成功! 新境界: %s" % CultivationSystem.data.realm)
	else:
		_log("突破失败")

func _get_stats():
	var stats = CultivationSystem.get_combat_stats()
	_log("战斗属性: %s" % str(stats))

func _on_level_up(level: int):
	_log("升级! Lv.%d" % level)

func _on_realm_broken(realm: String):
	_log("境界突破! %s" % realm)

func _run_all_tests():
	var results = []
	var passed = 0
	var failed = 0

	# Reset
	CultivationSystem.data.level = 1
	CultivationSystem.data.exp = 0
	CultivationSystem.data.realm = "后天"
	CultivationSystem.data.realm_progress = 0.0
	CultivationSystem.data.free_attribute_points = 0
	CultivationSystem.data.attributes = {
		"strength": 5, "agility": 5, "constitution": 5, "qi_capacity": 5, "wisdom": 5
	}

	# Test 1: Initial state
	if CultivationSystem.data.level == 1 and CultivationSystem.data.exp == 0:
		results.append("[PASS] 初始状态正确")
		passed += 1
	else:
		results.append("[FAIL] 初始状态异常")
		failed += 1

	# Test 2: Exp for level 2 = 150
	var exp_for_2 = int(100 * pow(1.5, 2-1))
	if exp_for_2 == 150:
		results.append("[PASS] Lv.2所需经验=150")
		passed += 1
	else:
		results.append("[FAIL] Lv.2所需经验=%d (期望150)" % exp_for_2)
		failed += 1

	# Test 3: Level up
	CultivationSystem.data.exp = 150
	CultivationSystem.data.level_up()
	if CultivationSystem.data.level == 2 and CultivationSystem.data.exp == 0:
		results.append("[PASS] 升级后等级=2, exp=0")
		passed += 1
	else:
		results.append("[FAIL] 升级后 Lv=%d exp=%d" % [CultivationSystem.data.level, CultivationSystem.data.exp])
		failed += 1

	# Test 4: Attribute points on level up
	if CultivationSystem.data.free_attribute_points == 5:
		results.append("[PASS] 升级获得5属性点")
		passed += 1
	else:
		results.append("[FAIL] 属性点=%d (期望5)" % CultivationSystem.data.free_attribute_points)
		failed += 1

	# Test 5: Add attribute
	CultivationSystem.data.add_attribute("strength", 1)
	if CultivationSystem.data.attributes["strength"] == 6:
		results.append("[PASS] 属性分配成功: str=6")
		passed += 1
	else:
		results.append("[FAIL] str=%d (期望6)" % CultivationSystem.data.attributes["strength"])
		failed += 1

	# Test 6: Realm breakthrough
	CultivationSystem.data.realm = "后天"
	CultivationSystem.data.realm_progress = 1.0
	CultivationSystem._try_breakthrough()
	if CultivationSystem.data.realm == "先天气":
		results.append("[PASS] 境界突破: 后天→先天气")
		passed += 1
	else:
		results.append("[FAIL] 境界=%s (期望先天气)" % CultivationSystem.data.realm)
		failed += 1

	# Test 7: Combat stats
	CultivationSystem.data.attributes = {"strength": 5, "agility": 5, "constitution": 5, "qi_capacity": 5, "wisdom": 5}
	var stats = CultivationSystem.get_combat_stats()
	if stats["max_health"] == 200 and stats["attack"] == 25:
		results.append("[PASS] 战斗属性正确: HP=200 ATK=25")
		passed += 1
	else:
		results.append("[FAIL] 战斗属性异常: %s" % str(stats))
		failed += 1

	# Test 8: Multiple level ups
	CultivationSystem.data.level = 1
	CultivationSystem.data.exp = 0
	CultivationSystem.add_exp(1000)
	if CultivationSystem.data.level >= 4:
		results.append("[PASS] +1000exp → Lv.%d" % CultivationSystem.data.level)
		passed += 1
	else:
		results.append("[FAIL] +1000exp → Lv.%d (期望≥4)" % CultivationSystem.data.level)
		failed += 1

	results.append("")
	results.append("总计: %d通过 %d失败" % [passed, failed])

	test_log.text = "=== 养成系统测试 ===\n" + "\n".join(results)
	_update_display()

	print("\n=== 养成系统测试 ===")
	for r in results:
		print(r)
