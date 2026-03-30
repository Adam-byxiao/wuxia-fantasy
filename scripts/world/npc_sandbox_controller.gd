class_name NPCTAController
extends Node

func _ready():
    TimeManager.day_passed.connect(_on_day_passed)

func _on_day_passed(day: int):
    SignalBus.sandbox_npc_tick.emit(day)

func execute_npc_daily_actions(npc_data: Dictionary, ai_type: String) -> Dictionary:
    match ai_type:
        "patrol":
            return {"action": "move", "target": "next_patrol_point"}
        "cultivate":
            return {"action": "gain_exp", "amount": randi() % 5 + 1}
        "trade":
            return {"action": "refresh_stock"}
        "wander":
            return {"action": "move", "target": "random"}
    return {}
