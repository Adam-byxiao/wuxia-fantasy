extends Control

@onready var run_all_btn: Button = $VBox/RunAllBtn
@onready var result_display: RichTextLabel = $VBox/ResultDisplay
@onready var back_btn: Button = $VBox/BackBtn

var _tests_passed = 0
var _tests_failed = 0
var _test_results: Array[String] = []

func _ready():
	run_all_btn.pressed.connect(_run_all_tests)
	back_btn.pressed.connect(_on_back)

func _on_back():
	get_tree().change_scene_to_file("res://scenes/menu/test_menu.tscn")

func _run_all_tests():
	_tests_passed = 0
	_tests_failed = 0
	_test_results.clear()
	_append_result("=== 开始运行测试 ===\n")

	# 测试各模块
	_test_signal_bus()
	_test_game_state()
	_test_time_manager()
	_test_world_generator()
	_test_region_generator()
	_test_battle_manager()
	_test_combat_unit()
	_test_skill()
	_test_enemy_ai()
	_test_cultivation_system()
	_test_item_data()
	_test_inventory_data()
	_test_npc_manager()

	# 显示结果
	_append_result("\n=== 测试完成 ===")
	_append_result("通过: %d | 失败: %d" % [_tests_passed, _tests_failed])
	result_display.text = "\n".join(_test_results)

func _append_result(msg: String):
	_test_results.append(msg)

func _assert(condition: bool, test_name: String, detail: String = ""):
	if condition:
		_tests_passed += 1
		_append_result("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		_append_result("[FAIL] %s%s" % [test_name, " - " + detail if detail else ""])

# ==================== 模块测试 ====================

func _test_signal_bus():
	_append_result("\n--- SignalBus ---")
	# SignalBus是全局节点，检查是否存在
	_assert(SignalBus != null, "SignalBus 存在")
	_assert(SignalBus.has_signal("battle_started"), "battle_started 信号存在")
	_assert(SignalBus.has_signal("ui_open_request"), "ui_open_request 信号存在")

func _test_game_state():
	_append_result("\n--- GameState ---")
	_assert(GameState != null, "GameState 存在")
	# 测试reset
	GameState.reset()
	_assert(GameState.current_day == 1, "reset后 current_day = 1")
	_assert(GameState.current_season == "春", "reset后 current_season = 春")
	# 测试inventory
	_assert(GameState.player_inventory != null, "player_inventory 存在")
	_assert(GameState.player_inventory.get_item_count() > 0, "初始物品已添加")

func _test_time_manager():
	_append_result("\n--- TimeManager ---")
	_assert(TimeManager != null, "TimeManager 存在")
	var initial_day = TimeManager.current_day
	TimeManager.advance_day()
	_assert(TimeManager.current_day == initial_day + 1, "advance_day() 天数增加")
	# 测试季节
	TimeManager.current_day = 30
	TimeManager.current_season = "春"
	TimeManager.advance_day()
	_assert(TimeManager.current_season == "夏", "30天后季节切换到夏")

func _test_world_generator():
	_append_result("\n--- WorldGenerator ---")
	_assert(WorldGenerator != null, "WorldGenerator 存在")
	# 测试生成
	var world = WorldGenerator.generate(20260327)
	_assert(world != null, "generate() 返回非空")
	_assert(world.regions.size() >= 5, "区域数量 >= 5")
	_assert(world.regions.size() <= 10, "区域数量 <= 10")
	_assert(world.paths.size() >= world.regions.size() - 1, "路径数量足够")
	# 测试确定性
	var world2 = WorldGenerator.generate(20260327)
	_assert(world.regions.size() == world2.regions.size(), "相同seed生成相同区域数")

func _test_region_generator():
	_append_result("\n--- RegionGenerator ---")
	var rg = RegionGenerator.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 123
	var region = rg.generate_region("forest", 1, rng)
	_assert(region != null, "generate_region() 返回非空")
	_assert(region.name != "", "区域有名称")
	_assert(region.terrain_type == "forest", "地形类型正确")
	rg.free()

func _test_battle_manager():
	_append_result("\n--- BattleManager ---")
	var bm = BattleManager.new()
	bm.free()

func _test_combat_unit():
	_append_result("\n--- CombatUnit ---")
	var unit = CombatUnit.new("测试", 100, 15, 5, 12, 50)
	_assert(unit != null, "CombatUnit 创建成功")
	_assert(unit.name == "测试", "名称正确")
	_assert(unit.max_health == 100, "最大生命正确")
	_assert(unit.attack == 15, "攻击正确")
	_assert(unit.defense == 5, "防御正确")
	# 测试受伤
	var dmg = unit.take_damage(10)
	_assert(dmg == 5, "受伤计算正确 (15-5-5=5, 最低1), 实际:%d" % dmg)
	_assert(unit.current_health == 95, "生命减少正确")
	# 测试最低伤害
	unit.defense = 100
	unit.current_health = 100
	dmg = unit.take_damage(5)
	_assert(dmg == 1, "最低伤害为1")
	unit.free()

func _test_skill():
	_append_result("\n--- Skill ---")
	var skill = Skill.new()
	skill.skill_id = "test"
	skill.name = "测试技能"
	skill.damage = 30
	skill.qi_cost = 10
	skill.cooldown_max = 2
	var owner = CombatUnit.new("Owner", 100, 15, 5, 12, 50)
	skill._owner = owner
	var target = CombatUnit.new("Target", 100, 5, 0, 5, 0)
	# 测试技能使用
	var result = skill.execute(target)
	_assert(result["success"] == true, "技能执行成功")
	skill.free()
	owner.free()
	target.free()

func _test_enemy_ai():
	_append_result("\n--- EnemyAI ---")
	var ai = EnemyAI.new()
	var enemies = [
		CombatUnit.new("E1", 50, 5, 0, 5, 0),
		CombatUnit.new("E2", 80, 5, 0, 5, 0),
	]
	enemies[0].is_alive = true
	enemies[1].is_alive = false
	var target = ai.select_target(enemies)
	_assert(target != null, "select_target 返回非空")
	_assert(target.name == "E1", "选择最低血量存活目标")
	ai.free()
	for e in enemies:
		e.free()

func _test_cultivation_system():
	_append_result("\n--- CultivationSystem ---")
	_assert(CultivationSystem != null, "CultivationSystem 存在")
	var data = CultivationSystem.data
	_assert(data != null, "CultivationData 存在")
	var initial_level = data.level
	data.exp = 150
	data.level_up()
	_assert(data.level == initial_level + 1, "升级后等级+1")

func _test_item_data():
	_append_result("\n--- ItemData ---")
	var item = ItemData.new("test", "测试物品", ItemData.ItemType.PILl, ItemData.Quality.COMMON, "测试")
	_assert(item.item_id == "test", "item_id 正确")
	_assert(item.name == "测试物品", "name 正确")
	_assert(item.type == ItemData.ItemType.PILl, "type 正确")
	_assert(item.can_use() == true, "丹药类型可使用")
	item.free()

func _test_inventory_data():
	_append_result("\n--- InventoryData ---")
	var inv = InventoryData.new()
	_assert(inv.get_item_count() == 0, "新背包为空")
	# 添加物品
	var item = ItemTemplates.create_healing_pill(50)
	var added = inv.add_item(item, 2)
	_assert(added == true, "添加物品成功")
	_assert(inv.get_item_count() == 1, "物品数量=1")
	# 再次添加同类物品应该堆叠
	var added2 = inv.add_item(item, 3)
	var entry = inv.get_item("healing_pill")
	_assert(entry["quantity"] == 5, "堆叠后数量=5")
	# 使用物品
	var result = inv.use_item("healing_pill")
	_assert(result["success"] == true, "使用物品成功")
	entry = inv.get_item("healing_pill")
	_assert(entry["quantity"] == 4, "使用后数量=4")
	inv.free()

func _test_npc_manager():
	_append_result("\n--- NPCManager ---")
	_assert(NPCManager != null, "NPCManager 存在")
	NPCManager.npcs.clear()
	_assert(NPCManager.npcs.size() == 0, "NPC列表清空")
