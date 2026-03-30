class_name NPCAgent
extends Node2D

@export var npc_id: String = ""
@export var display_name: String = "无名NPC"
@export var ai_type: int = 3  # 0=PATROL, 1=TRADER, 2=CULTIVATOR, 3=WANDERER, 4=GUARD, 5=QUEST

var brain: NPCBrain
var cultivation_data: CultivationData
var current_action: Dictionary = {"action": "idle"}
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var current_region: String = ""

# ============ 区域间移动相关 ============
var _target_region: String = ""
var _path_to_target: Array[String] = []
var _path_index: int = 0
var _moving_along_path: bool = false
var _last_region_check_day: int = -1

func _ready():
	brain = NPCBrain.new(npc_id, ai_type)
	brain.personality = NPCTypes.get_default_personality(ai_type)
	cultivation_data = CultivationData.new()

	# 初始化巡逻点（基于AI类型）
	_init_ai_behavior()

	# 监听沙盒 tick
	SignalBus.sandbox_npc_tick.connect(_on_sandbox_tick)

	# 监听世界生成
	SignalBus.world_generated.connect(_on_world_generated)

func _init_ai_behavior():
	match ai_type:
		0:  # PATROL
			var base_pos = position
			patrol_points = [
				base_pos + Vector2(100, 0),
				base_pos + Vector2(200, 50),
				base_pos + Vector2(150, 150),
				base_pos + Vector2(0, 100),
			]
		1:  # TRADER
			brain.current_goal = "trade"
		2:  # CULTIVATOR
			brain.current_goal = "cultivate"
			cultivation_data.realm_progress = randf() * 0.5
		4:  # GUARD
			brain.current_goal = "survive"
			brain.goal_weights["survive"] = 20

func _on_sandbox_tick(day: int):
	# 评估目标
	var world_state = _collect_world_state()
	var goal = brain.evaluate_current_goal()
	var action = NPCActionSelector.select_action(brain, world_state)
	current_action = action

	_execute_action(action, world_state)

func _collect_world_state() -> Dictionary:
	return {
		"game_hour": TimeManager.current_day % 24,
		"is_night": TimeManager.current_day % 2 == 1,
		"in_town": current_region.begins_with("town"),
		"is_safe_location": true,  # TODO: 根据区域类型
		"has_unexplored": false,
		"player_nearby": false,
		"other_npcs_nearby": false,
		"nearby_enemies": false,
		"customer_nearby": false,
		"nearest_enemy": null,
		"nearest_town": Vector2.ZERO,
	}

func _execute_action(action: Dictionary, world_state: Dictionary):
	match action["action"]:
		"idle":
			pass
		"cultivate":
			cultivation_data.realm_progress += 0.01
			if cultivation_data.realm_progress >= 1.0:
				_try_breakthrough()
		"move", "wander", "explore":
			if _moving_along_path and _path_to_target.size() > 0:
				_move_along_path()
			else:
				_move_toward(action.get("target", _get_random_position()))
		"travel_to_region":
			var target_region_id = action.get("region_id", "")
			if target_region_id != "":
				_start_travel(target_region_id)
		"open_shop":
			brain.current_state = "trading"
		"approach_player":
			brain.current_state = "socializing"
		"fight":
			brain.current_state = "combat"

func _move_toward(target_pos: Vector2):
	var direction = (target_pos - position).normalized()
	position = position + direction * 50.0 * (1.0 / 60.0)  # 约50像素/秒

func _get_random_position() -> Vector2:
	return position + Vector2(randf() * 200 - 100, randf() * 200 - 100)

func _try_breakthrough():
	if cultivation_data.realm_progress >= 1.0:
		var idx = CultivationData.REALMS.find(cultivation_data.realm)
		if idx < CultivationData.REALMS.size() - 1:
			cultivation_data.realm = CultivationData.REALMS[idx + 1]
			cultivation_data.realm_progress = 0.0
			print("[NPC] %s 境界突破至 %s" % [display_name, cultivation_data.realm])

func get_dialogue(player_relation: int) -> Dictionary:
	var base_responses = brain.personality.get("dialogue_templates", ["你好"])
	match brain.current_goal:
		"trade":
			return {
				"speaker": display_name,
				"text": "这位客官，进来看看？",
				"type": "trade"
			}
		"cultivate":
			return {
				"speaker": display_name,
				"text": "道法自然，施主请回吧。",
				"type": "cultivate"
			}
	return {
		"speaker": display_name,
		"text": base_responses[randi() % base_responses.size()],
		"type": "normal"
	}

# ============ 区域间移动方法 ============

func _on_world_generated(world) -> void:
	# 世界生成后，随机分配初始区域
	if world != null and world.regions.size() > 0:
		var random_region = world.regions[randi() % world.regions.size()]
		current_region = random_region.id
		_update_position_to_region_center()
		print("[NPCAgent] %s 初始化在区域: %s" % [display_name, current_region])

func _start_travel(target_region_id: String) -> void:
	if current_region == target_region_id:
		return

	# 使用 WorldGenerator 的路径查找
	_path_to_target = WorldGenerator.find_path_between(current_region, target_region_id)
	_target_region = target_region_id
	_path_index = 0
	_moving_along_path = true

	print("[NPCAgent] %s 开始旅行: %s -> %s，路径: %s" % [display_name, current_region, target_region_id, _path_to_target])

func _move_along_path() -> void:
	if not _moving_along_path or _path_to_target.size() == 0:
		_moving_along_path = false
		return

	# 确保在当前路径点的中心
	if _path_index < _path_to_target.size():
		var target_region_id = _path_to_target[_path_index]
		var target_pos = WorldGenerator.get_region_center(target_region_id)

		# 检查是否到达目标区域
		if position.distance_to(target_pos) < 10.0:
			# 到达路径点
			current_region = target_region_id
			_path_index += 1

			if _path_index >= _path_to_target.size():
				# 到达终点
				_moving_along_path = false
				print("[NPCAgent] %s 到达目的地: %s" % [display_name, target_region_id])
				return

		# 移动向当前路径点
		_move_toward(target_pos)
	else:
		_moving_along_path = false

func _update_position_to_region_center() -> void:
	if current_region != "":
		var center = WorldGenerator.get_region_center(current_region)
		position = center

# ============ 公共方法 ============

# NPC 是否正在旅行
func is_traveling() -> bool:
	return _moving_along_path

# 获取 NPC 当前所在区域
func get_current_region() -> String:
	return current_region

# 获取 NPC 目标区域
func get_target_region() -> String:
	return _target_region

# 获取路径
func get_travel_path() -> Array[String]:
	return _path_to_target
