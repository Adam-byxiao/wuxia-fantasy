extends Node2D

@onready var battle_log: Label = $BattleLog
@onready var test_result: Label = $TestResult
@onready var controls: VBoxContainer = $Controls

var battle_manager: BattleManager
var player: CombatUnit
var enemies: Array[CombatUnit]
var test_number = 0

func _ready():
	_add_button("开始战斗(2山贼)", func(): _start_battle_2())
	_add_button("开始战斗(3山贼+1头目)", func(): _start_battle_boss())
	_add_button("执行伤害测试", func(): _test_damage())
	_add_button("执行技能测试", func(): _test_skill())
	_add_button("执行逃跑测试", func(): _test_escape())
	_add_button("执行境界加成测试", func(): _test_realm_bonus())
	_add_button("执行暴击测试", func(): _test_crit())
	_add_button("执行物品测试", func(): _test_item())
	_add_button("执行全部测试", func(): _run_all_tests())
	_setup_battle_manager()

func _add_button(text: String, cb: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 36)
	btn.pressed.connect(cb)
	controls.add_child(btn)

func _setup_battle_manager():
	battle_manager = BattleManager.new()
	add_child(battle_manager)
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.action_executed.connect(_on_action_executed)

func _clear_log():
	battle_log.text = ""

func _log(msg: String):
	battle_log.text += msg + "\n"
	print("[战斗测试] " + msg)

func _setup_player():
	player = CombatUnit.new("测试玩家", 100, 15, 5, 12, 50)
	player.skills = SkillData.get_player_starting_skills()

func _start_battle_2():
	_clear_log()
	test_number = 0
	_setup_player()
	var e1 = EnemyTemplates.create_bandit(2)
	var e2 = EnemyTemplates.create_bandit(1)
	enemies = [e1, e2]
	battle_manager.start_battle(player, enemies)
	_log("战斗开始! 敌人: 山贼Lv2, 山贼Lv1")

func _start_battle_boss():
	_clear_log()
	test_number = 0
	_setup_player()
	var e1 = EnemyTemplates.create_bandit(2)
	var e2 = EnemyTemplates.create_bandit(1)
	var e3 = EnemyTemplates.create_bandit(1)
	var boss = EnemyTemplates.create_boss(2)
	enemies = [e1, e2, e3, boss]
	battle_manager.start_battle(player, enemies)
	_log("战斗开始! 3山贼+头目")

func _on_battle_started():
	_log("=== 战斗开始 ===")

func _on_turn_started(is_player: bool):
	if is_player:
		_log("--- 玩家回合 ---")
	else:
		_log("--- 敌人回合 ---")

func _on_action_executed(name: String, result: Dictionary):
	_log("%s: %s" % [name, result.get("message", "")])

func _on_battle_ended(victory: bool, rewards: Dictionary):
	if victory:
		_log("=== 战斗胜利! ===")
		_log("获得经验: %d" % rewards.get("exp", 0))
		_log("获得金币: %d" % rewards.get("gold", 0))
		SignalBus.exp_gained.emit(rewards.get("exp", 0))
	else:
		_log("=== 战斗失败 ===")

func _test_damage():
	_clear_log()
	_setup_player()
	var enemy = CombatUnit.new("测试敌人", 50, 5, 3, 5, 0)

	var initial_hp = enemy.current_health
	var atk_with_realm = player.get_attack_with_realm()
	var expected = max(1, atk_with_realm - enemy.get_defense_with_realm())
	var actual = enemy.take_damage(atk_with_realm)

	if actual == expected:
		_log("[PASS] 伤害计算正确: atk=%d def=%d → 实际伤害=%d (期望=%d)" % [atk_with_realm, enemy.get_defense_with_realm(), actual, expected])
	else:
		_log("[FAIL] 伤害计算错误: 实际=%d 期望=%d" % [actual, expected])

	# Test min damage = 1
	enemy.defense = 100
	enemy.current_health = enemy.max_health
	actual = enemy.take_damage(5)
	if actual == 1:
		_log("[PASS] 最低伤害=1 正确")
	else:
		_log("[FAIL] 最低伤害=%d 期望=1" % actual)

	# Test death
	enemy.current_health = 1
	enemy.is_alive = true
	enemy.take_damage(100)
	if not enemy.is_alive:
		_log("[PASS] 生命≤0时is_alive=false 正确")
	else:
		_log("[FAIL] is_alive应该为false")

func _test_skill():
	_clear_log()
	_setup_player()
	var skill = SkillData.create_palm_strike()
	player.add_skill(skill)

	var enemy = CombatUnit.new("敌人", 100, 5, 0, 5, 0)
	player.current_qi = 50

	# 测试技能使用
	var result = battle_manager.execute_player_skill(0, 0)
	if result.get("success") and result.get("damage", 0) > 0:
		_log("[PASS] 技能伤害正确")
	else:
		_log("[FAIL] 技能执行: %s" % str(result))

	# 测试内力消耗
	if player.current_qi == 30:  # 50 - 20 (palm_strike qi_cost)
		_log("[PASS] 气力消耗正确: 50-20=30")
	else:
		_log("[FAIL] 气力: %d 期望=30" % player.current_qi)

	# 测试冷却
	var cooldown = player.get_skill_cooldown(skill.skill_id)
	if cooldown == skill.cooldown_max:
		_log("[PASS] 冷却设置正确: %d" % cooldown)
	else:
		_log("[FAIL] 冷却: %d 期望=%d" % [cooldown, skill.cooldown_max])

	# 测试内力不足
	player.current_qi = 5
	result = battle_manager.execute_player_skill(0, 0)
	if not result.get("success"):
		_log("[PASS] 气力不足时无法使用技能")
	else:
		_log("[FAIL] 气力不足时应该无法使用技能")

func _test_escape():
	_clear_log()
	_setup_player()
	var e1 = EnemyTemplates.create_bandit(1)
	enemies = [e1]
	battle_manager.start_battle(player, enemies)

	var escape_results = []
	for i in range(20):
		battle_manager.player.current_health = 100
		battle_manager.player.is_alive = true
		battle_manager.state = BattleManager.BattleState.PLAYER_TURN
		var result = battle_manager.try_escape()
		escape_results.append(result.get("escaped", false))

	var escape_count = escape_results.count(true)
	var rate = escape_count * 100 / 20
	_log("逃跑测试: 20次中成功%d次 (%.0f%%)" % [escape_count, rate])
	if 30 <= rate and rate <= 70:
		_log("[PASS] 逃跑率在30-70%%范围内")
	else:
		_log("[NOTE] 逃跑率%.0f%%偏离预期范围" % rate)

func _test_realm_bonus():
	_clear_log()
	_setup_player()

	# 测试后天境界（无加成）
	player.realm = "后天"
	var base_atk = player.attack
	var atk = player.get_attack_with_realm()
	_log("后天境界: 基础攻击=%d, 实际攻击=%d" % [base_atk, atk])
	if atk == base_atk:
		_log("[PASS] 后天境界攻击加成=0%")
	else:
		_log("[FAIL] 后天境界应有0%%加成")

	# 测试先天气境界
	player.realm = "先天气"
	atk = player.get_attack_with_realm()
	var expected = int(base_atk * 1.1)
	_log("先天气境界: 基础攻击=%d, 实际攻击=%d (期望=%d)" % [base_atk, atk, expected])
	if atk == expected:
		_log("[PASS] 先天气境界攻击加成=10%%")
	else:
		_log("[FAIL] 先天气境界应有10%%加成")

	# 测试金丹境界
	player.realm = "金丹"
	atk = player.get_attack_with_realm()
	expected = int(base_atk * 1.3)
	_log("金丹境界: 基础攻击=%d, 实际攻击=%d (期望=%d)" % [base_atk, atk, expected])
	if atk == expected:
		_log("[PASS] 金丹境界攻击加成=30%%")
	else:
		_log("[FAIL] 金丹境界应有30%%加成")

func _test_crit():
	_clear_log()
	_setup_player()
	player.crit_rate = 1.0  # 100%暴击率，方便测试
	player.crit_damage = 2.0  # 200%暴击伤害

	var enemy = CombatUnit.new("敌人", 100, 10, 0, 10, 0)
	var base_damage = player.get_attack_with_realm()

	# 测试暴击
	var crit_damage = player.calc_crit_damage(base_damage)
	_log("暴击测试: 基础伤害=%d, 暴击伤害=%d (期望=%d)" % [base_damage, crit_damage, base_damage * 2])
	if crit_damage == base_damage * 2:
		_log("[PASS] 暴击伤害=基础*暴击倍率")
	else:
		_log("[FAIL] 暴击伤害计算错误")

	# 测试非暴击
	player.crit_rate = 0.0  # 0%暴击率
	crit_damage = player.calc_crit_damage(base_damage)
	if crit_damage == base_damage:
		_log("[PASS] 非暴击时伤害=基础伤害")
	else:
		_log("[FAIL] 非暴击时伤害应等于基础伤害")

func _test_item():
	_clear_log()
	_setup_player()

	# 创建测试物品
	var heal_pill = ItemTemplates.create_healing_pill()
	var qi_pill = ItemTemplates.create_qi_pill()
	var knife = ItemTemplates.create_throwing_knife()

	# 添加到背包
	var inv = GameState.player_inventory
	inv.add_item(heal_pill, 3)
	inv.add_item(qi_pill, 2)
	inv.add_item(knife, 5)

	# 测试生命恢复
	player.current_health = 50
	var result = battle_manager.execute_player_item(heal_pill.item_id, -1)
	if result.get("success") and result.get("heal", 0) > 0:
		_log("[PASS] 使用疗伤丹恢复生命: %d" % result.get("heal"))
	else:
		_log("[FAIL] 疗伤丹使用失败: %s" % str(result))

	# 测试内力恢复
	player.current_qi = 10
	result = battle_manager.execute_player_item(qi_pill.item_id, -1)
	if result.get("success") and result.get("heal", 0) > 0:
		_log("[PASS] 使用补气丹恢复内力: %d" % result.get("heal"))
	else:
		_log("[FAIL] 补气丹使用失败: %s" % str(result))

func _run_all_tests():
	_clear_log()
	_log("=== 执行全部战斗测试 ===\n")

	var passed = 0
	var failed = 0

	# ========== 伤害计算测试 ==========
	var p = CombatUnit.new("P", 100, 15, 5, 12, 50)
	var e = CombatUnit.new("E", 80, 8, 3, 8, 30)

	# 基础伤害 = atk - def
	var dmg = p.get_attack_with_realm()
	var actual = e.take_damage(dmg)
	var expected = max(1, dmg - e.get_defense_with_realm())
	if actual == expected:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 基础伤害计算: actual=%d expected=%d" % [actual, expected])

	# 死亡判定
	e.current_health = 1
	e.is_alive = true
	e.take_damage(100)
	if not e.is_alive:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 死亡判定")

	# ========== 境界加成测试 ==========
	p.realm = "金丹"
	var atk_with_realm = p.get_attack_with_realm()
	var expected_atk = int(p.attack * 1.3)
	if atk_with_realm == expected_atk:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 境界加成: atk=%d expected=%d" % [atk_with_realm, expected_atk])

	# ========== 技能测试 ==========
	p = CombatUnit.new("P2", 100, 15, 5, 12, 50)
	p.skills = SkillData.get_player_starting_skills()
	e = CombatUnit.new("E2", 80, 5, 0, 5, 0)
	p.current_qi = 50

	var bm = BattleManager.new()
	add_child(bm)
	bm.start_battle(p, [e])
	var r = bm.execute_player_skill(0, 0)
	if r.get("success") and r.get("damage", 0) > 0:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 技能执行: %s" % str(r))
	bm.queue_free()

	# ========== 冷却测试 ==========
	p = CombatUnit.new("P3", 100, 15, 5, 12, 50)
	var skill = SkillData.create_palm_strike()
	p.add_skill(skill)
	e = CombatUnit.new("E3", 80, 5, 0, 5, 0)

	# 直接测试冷却设置（不通过完整战斗流程）
	p.use_skill(skill)  # 设置冷却
	var cd = p.get_skill_cooldown(skill.skill_id)
	if cd == skill.cooldown_max:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 冷却设置: cd=%d expected=%d" % [cd, skill.cooldown_max])

	# 测试冷却减少
	p.reduce_cooldowns()
	cd = p.get_skill_cooldown(skill.skill_id)
	if cd == skill.cooldown_max - 1:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 冷却减少: cd=%d expected=%d" % [cd, skill.cooldown_max - 1])

	# ========== 治疗测试 ==========
	p = CombatUnit.new("P4", 100, 15, 5, 12, 50)
	p.current_health = 50
	p.heal(30)
	if p.current_health == 80:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 治疗: health=%d 期望=80" % p.current_health)

	p.heal(100)
	if p.current_health == p.max_health:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 治疗上限")

	# ========== 气力测试 ==========
	p.current_qi = 30
	if p.use_qi(20):
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 气力消耗")

	if not p.use_qi(50):
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 气力不足判定")

	# ========== 暴击测试 ==========
	p = CombatUnit.new("P5", 100, 100, 0, 12, 50)
	p.crit_rate = 1.0
	p.crit_damage = 2.0
	e = CombatUnit.new("E4", 100, 0, 0, 0, 0)

	var base = p.get_attack_with_realm()
	var crit = p.calc_crit_damage(base)
	if crit == base * 2:
		passed += 1
	else:
		failed += 1
		_log("[FAIL] 暴击伤害: base=%d crit=%d expected=%d" % [base, crit, base * 2])

	test_result.text = "=== 测试结果 ===\n通过: %d, 失败: %d" % [passed, failed]
	_log("\n=== 总计: %d通过 %d失败 ===" % [passed, failed])

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/test_menu.tscn")
	elif event.is_action_pressed("ui_accept"):
		_start_battle_2()
	elif event.is_action_pressed("ui_focus_next"):
		_test_damage()
	elif event.is_action_pressed("ui_focus_prev"):
		_test_skill()
