class_name NPCBrain
extends Node

enum AIType { PATROL, TRADER, CULTIVATOR, WANDERER, GUARD, QUEST }

var npc_id: String
var ai_type: AIType
var personality: Dictionary
var current_goal: String = "idle"
var current_state: String = "idle"

# 记忆系统
var memory: Dictionary = {
    "last_seen_player": null,
    "player_interactions": 0,
    "fought_with": [],       # 打过架的NPC ID列表
    "trade_with": [],        # 交易过的玩家
    "trust_level": 0,        # 信任度
}

# 目标评估权重
var goal_weights: Dictionary = {
    "survive": 0,     # 生存：平时0，受威胁时+20
    "trade": 3,
    "cultivate": 2,
    "socialize": 2,
    "wander": 3,
    "quest": 4,
}

func _init(p_npc_id: String = "", p_type: AIType = AIType.WANDERER):
    npc_id = p_npc_id
    ai_type = p_type

func evaluate_current_goal() -> String:
    var best_goal = "idle"
    var best_score = 0

    for goal in goal_weights:
        var score = _calculate_goal_score(goal)
        if score > best_score:
            best_score = score
            best_goal = goal

    current_goal = best_goal
    return best_goal

func _calculate_goal_score(goal: String) -> int:
    var base = goal_weights.get(goal, 0)
    match goal:
        "survive":
            # 生存：平时权重0，受威胁时+20
            if memory.get("health_check_failed", false):
                return base + 20
            return base
        "trade":
            if ai_type == AIType.TRADER:
                return base + 15
            if TimeManager.current_day % 3 == 0:
                return base + 3
        "cultivate":
            if ai_type == AIType.CULTIVATOR:
                return base + 10
        "socialize":
            if memory.get("player_interactions", 0) > 0:
                return base + memory["player_interactions"]
        "wander":
            if ai_type == AIType.WANDERER:
                return base + 5
            if ai_type == AIType.PATROL:
                return base + 3  # 巡逻也是一种游荡
        "quest":
            if ai_type == AIType.QUEST:
                return base + 5
    return base

func update_memory(key: String, value):
    memory[key] = value

func on_player_interaction(interaction_type: String):
    memory["last_seen_player"] = TimeManager.current_day
    memory["player_interactions"] += 1
    if interaction_type == "trade":
        memory["trust_level"] = min(100, memory["trust_level"] + 5)
        memory["trade_with"].append(TimeManager.current_day)
    elif interaction_type == "combat":
        memory["trust_level"] = max(-100, memory["trust_level"] - 20)
