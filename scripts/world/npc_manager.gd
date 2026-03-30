extends Node

# 管理所有NPC实例，提供查询接口

var npcs: Dictionary = {}  # npc_id -> NPCAgent

func register_npc(npc: NPCAgent):
	npcs[npc.npc_id] = npc
	var ai_type_names = ["PATROL", "TRADER", "CULTIVATOR", "WANDERER", "GUARD", "QUEST"]
	var type_name = ai_type_names[npc.ai_type] if npc.ai_type < ai_type_names.size() else "UNKNOWN"
	print("[NPCManager] 注册NPC: %s (类型: %s)" % [npc.display_name, type_name])

func unregister_npc(npc_id: String):
	npcs.erase(npc_id)

func get_npc(npc_id: String) -> NPCAgent:
	return npcs.get(npc_id)

func get_npcs_by_type(ai_type: int) -> Array[NPCAgent]:
	var result: Array[NPCAgent] = []
	for npc in npcs.values():
		if npc.ai_type == ai_type:
			result.append(npc)
	return result

func get_npcs_in_region(region_id: String) -> Array[NPCAgent]:
	var result: Array[NPCAgent] = []
	for npc in npcs.values():
		if npc.current_region == region_id:
			result.append(npc)
	return result

func spawn_npc(template: Dictionary) -> NPCAgent:
	var scene = load("res://scenes/entities/npc/npc.tscn")
	if scene == null:
		print("[NPCManager] 错误: 无法加载 npc.tscn 场景")
		return null
	var instance: NPCAgent = scene.instantiate()

	instance.npc_id = template.get("id", "npc_%d" % randi())
	instance.display_name = template.get("name", "无名")
	instance.ai_type = template.get("ai_type", 3)  # default WANDERER
	instance.current_region = template.get("region", "")

	# 支持 Vector2 或 {x,y} 两种格式
	var pos = template.get("position", Vector2.ZERO)
	if pos is Vector2:
		instance.position = pos
	elif pos is Dictionary and pos.has("x") and pos.has("y"):
		instance.position = Vector2(pos["x"], pos["y"])

	add_child(instance)
	register_npc(instance)
	return instance

func get_world_state_for_npc(npc_id: String) -> Dictionary:
	# 收集某个NPC视角的世界状态
	var npc = get_npc(npc_id)
	if not npc:
		return {}

	return {
		"game_hour": TimeManager.current_day % 24,
		"is_night": TimeManager.current_day % 2 == 1,
		"in_town": npc.current_region.begins_with("town"),
		"is_safe_location": npc.current_region != "",
		"has_unexplored": false,
		"player_nearby": _is_player_near(npc),
		"other_npcs_nearby": _has_other_npcs_near(npc),
		"nearby_enemies": false,
		"customer_nearby": _has_customer_near(npc),
		"nearest_enemy": null,
		"nearest_town": _get_nearest_town(npc),
	}

func _is_player_near(npc: NPCAgent) -> bool:
	# TODO: 接入 GameState 的 player position
	return false

func _has_other_npcs_near(npc: NPCAgent) -> bool:
	for other in npcs.values():
		if other != npc and other.current_region == npc.current_region:
			return true
	return false

func _has_customer_near(npc: NPCAgent) -> bool:
	return npc.ai_type == 1 and npc.current_region.begins_with("town")  # TRADER

func _get_nearest_town(npc: NPCAgent) -> Vector2:
	# TODO: 接入 WorldData 查找最近城镇
	return Vector2.ZERO
