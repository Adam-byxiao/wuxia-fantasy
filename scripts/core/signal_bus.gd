extends Node

# 战斗系统 → 事件
signal battle_started
signal battle_ended(victory: bool, rewards: Dictionary)
signal exp_gained(amount: int)
signal item_acquired(item_id: String, quantity: int)

# 世界系统 → 战斗/养成
signal world_generated(world)
signal region_entered(region_id: String)
signal world_time_passed(days: int)

# 养成系统 → 战斗
signal level_up(new_level: int)
signal realm_broken(new_realm: String)
signal skill_learned(skill_id: String)
signal skill_equipped(skill_id: String)

# 沙盒系统
signal world_event_triggered(event_id: String, event_name: String)
signal sandbox_npc_tick(day: int)

# 存档系统
signal game_saved()
signal game_loaded()

# UI请求
signal ui_open_request(panel_name: String)
signal ui_close_request(panel_name: String)
signal panel_switched(panel_id: String)

signal npc_interaction_requested(npc)
signal inventory_requested()
signal skills_requested()
signal dialog_requested(dialogue_data)
signal dialog_ended()

# 物品操作
signal item_used(item_id: String)
signal item_discarded(item_id: String)

# 战斗结算
signal battle_result_continued(victory: bool, rewards: Dictionary)
