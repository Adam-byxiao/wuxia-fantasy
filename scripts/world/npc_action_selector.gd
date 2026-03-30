class_name NPCActionSelector
extends Node

# 根据当前目标选择行动
static func select_action(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    match brain.current_goal:
        "survive":
            return _action_survive(brain, world_state)
        "trade":
            return _action_trade(brain, world_state)
        "cultivate":
            return _action_cultivate(brain, world_state)
        "socialize":
            return _action_socialize(brain, world_state)
        "wander":
            return _action_wander(brain, world_state)
        "quest":
            return _action_quest(brain, world_state)
    return _action_idle(brain, world_state)

# 生存优先：检查威胁，决定逃跑/战斗/躲藏
static func _action_survive(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    var has_enemy = world_state.get("nearby_enemies", false)
    var health_ratio = brain.memory.get("health_ratio", 1.0)
    var caution = brain.personality.get("caution", 0.5)

    if has_enemy and caution > 0.4 and health_ratio < 0.5:
        return {"action": "flee", "target": _get_nearest_safe_location(world_state)}
    elif has_enemy and caution > 0.2:
        return {"action": "fight", "target": world_state.get("nearest_enemy")}
    else:
        return {"action": "hide", "target": _get_nearest_hiding_spot(world_state)}

# 商贩：开店/招呼客人/收摊
static func _action_trade(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    var hour = world_state.get("game_hour", 8)
    var in_town = world_state.get("in_town", false)

    if hour >= 9 and hour < 21 and in_town:
        if world_state.get("customer_nearby", false):
            return {"action": "greet_customer", "dialogue": "欢迎光临！"}
        return {"action": "open_shop"}
    elif hour >= 21 or hour < 6:
        return {"action": "close_shop"}
    return {"action": "wait", "next": "shop_opening"}

# 修炼：打坐/吸收灵气/突破尝试
static func _action_cultivate(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    var realm_progress = brain.memory.get("realm_progress", 0.0)

    if realm_progress >= 1.0:
        return {"action": "attempt_breakthrough"}
    elif world_state.get("is_night", false):
        return {"action": "cultivate", "style": "night_meditation"}
    elif world_state.get("is_safe_location", true):
        return {"action": "cultivate", "style": "normal"}
    return {"action": "rest"}

# 社交：找人聊天/打听消息/帮助他人
static func _action_socialize(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    var curiosity = brain.personality.get("curiosity", 0.5)
    var sociability = brain.personality.get("sociability", 0.5)

    if world_state.get("player_nearby", false) and curiosity > 0.5:
        return {"action": "approach_player", "dialogue": _get_curious_dialogue(brain)}
    elif world_state.get("other_npcs_nearby", false) and sociability > 0.3:
        return {"action": "talk_to_npc"}
    return {"action": "wander_social"}

# 游荡：随机移动/探索/休息
static func _action_wander(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    var curiosity = brain.personality.get("curiosity", 0.5)
    var has_unexplored = world_state.get("has_unexplored", false)

    if has_unexplored and curiosity > 0.5:
        return {"action": "explore", "target": world_state.get("nearest_unexplored")}
    else:
        return {"action": "random_walk"}

# 任务：接受/执行/交付任务
static func _action_quest(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    var quest = brain.memory.get("current_quest", null)
    if quest == null:
        return {"action": "wait_for_quest_giver"}
    var quest_stage = quest.get("stage", "accepted")
    match quest_stage:
        "accepted":
            return {"action": "execute_quest", "quest_id": quest.get("id")}
        "completed":
            return {"action": "deliver_quest", "quest_id": quest.get("id")}
    return {"action": "idle"}

static func _action_idle(brain: NPCBrain, world_state: Dictionary) -> Dictionary:
    return {"action": "idle"}

static func _get_nearest_safe_location(world_state: Dictionary):
    return world_state.get("nearest_town", Vector2.ZERO)

static func _get_nearest_hiding_spot(world_state: Dictionary):
    return world_state.get("nearest_building", Vector2.ZERO)

static func _get_curious_dialogue(brain: NPCBrain) -> String:
    var dialogues = [
        "少侠从哪里来？",
        "最近江湖可有什么大事？",
        "我看你身手不凡，可否切磋一下？",
        "这位朋友，一起喝一杯？"
    ]
    return dialogues[randi() % dialogues.size()]
