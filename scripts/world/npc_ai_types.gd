class_name NPCTypes
extends Node

# AI Type constants: 0=PATROL, 1=TRADER, 2=CULTIVATOR, 3=WANDERER, 4=GUARD, 5=QUEST
static func get_default_personality(ai_type: int) -> Dictionary:
    match ai_type:
        0:  # PATROL
            return {
                "aggression": 0.3,
                "sociability": 0.5,
                "curiosity": 0.2,
                "caution": 0.4,
                "dialogue_templates": ["过路人", "巡逻中", "无事"]
            }
        1:  # TRADER
            return {
                "aggression": 0.0,
                "sociability": 0.9,
                "curiosity": 0.3,
                "caution": 0.1,
                "dialogue_templates": ["欢迎光临", "来看看", "便宜卖了"]
            }
        2:  # CULTIVATOR
            return {
                "aggression": 0.1,
                "sociability": 0.2,
                "curiosity": 0.6,
                "caution": 0.5,
                "dialogue_templates": ["闭关中", "勿扰", "道法自然"]
            }
        3:  # WANDERER
            return {
                "aggression": 0.2,
                "sociability": 0.6,
                "curiosity": 0.8,
                "caution": 0.3,
                "dialogue_templates": ["江湖中人", "四处游历", "云游四方"]
            }
        4:  # GUARD
            return {
                "aggression": 0.7,
                "sociability": 0.3,
                "curiosity": 0.1,
                "caution": 0.6,
                "dialogue_templates": ["站岗中", "闲人免进", "口令"]
            }
        _:
            return {
                "aggression": 0.3,
                "sociability": 0.5,
                "curiosity": 0.4,
                "caution": 0.4,
                "dialogue_templates": ["你好"]
            }
