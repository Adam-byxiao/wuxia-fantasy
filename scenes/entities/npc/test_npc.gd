extends Node2D

@onready var npc_manager: NPCManager = $NPCManager

func _ready():
	print("=== NPC AI System Test ===")
	_spawn_test_npcs()
	# 加速时间以便观察
	TimeManager.set_time_scale(50.0)

func _spawn_test_npcs():
	# 直接通过代码创建 NPC，不依赖场景加载
	var templates = [
		{
			"id": "patrol_001",
			"name": "守卫张三",
			"ai_type": 0,  # PATROL
			"region": "region_road",
			"position": Vector2(200, 200)
		},
		{
			"id": "trader_001",
			"name": "李掌柜",
			"ai_type": 1,  # TRADER
			"region": "region_town",
			"position": Vector2(400, 300)
		},
		{
			"id": "cultivator_001",
			"name": "闭关道人",
			"ai_type": 2,  # CULTIVATOR
			"region": "region_mountain",
			"position": Vector2(600, 150)
		},
		{
			"id": "wanderer_001",
			"name": "江湖散人",
			"ai_type": 3,  # WANDERER
			"region": "region_forest",
			"position": Vector2(300, 400)
		},
	]

	for t in templates:
		var npc = npc_manager.spawn_npc(t)
		if npc:
			print("  [%s] 目标: %s, 状态: %s" % [npc.display_name, npc.brain.current_goal, npc.brain.current_state])
		else:
			print("  [警告] NPC %s 创建失败" % t["name"])

	print("")
	print("NPC总数: ", npc_manager.npcs.size())

func _input(event: InputEvent):
	if event.is_action_pressed("ui_f5"):
		TimeManager.set_time_scale(50.0 if TimeManager.time_scale < 50.0 else 1.0)
		print("[TimeManager] 速度切换: ", TimeManager.time_scale)

	if event.is_action_pressed("ui_f6"):
		print("=== NPC状态快照 ===")
		for npc in npc_manager.npcs.values():
			var ai_type_names = ["PATROL", "TRADER", "CULTIVATOR", "WANDERER", "GUARD", "QUEST"]
			print("  %s | 类型: %s | 目标: %s | 状态: %s" % [
				npc.display_name,
				ai_type_names[npc.ai_type] if npc.ai_type < ai_type_names.size() else "UNKNOWN",
				npc.brain.current_goal,
				npc.brain.current_state
			])
