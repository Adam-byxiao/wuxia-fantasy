class_name EnemyTemplates
extends Node

# 快速创建敌人实例的工厂

static func create_bandit(level: int = 1) -> CombatUnit:
    var u = CombatUnit.new(
        "山贼",
        80 + level * 20,
        8 + level * 3,
        3 + level,
        8,
        30
    )
    u.unit_id = "bandit"
    return u

static func create_wolf(level: int = 1) -> CombatUnit:
    var u = CombatUnit.new(
        "野狼",
        50 + level * 10,
        10 + level * 2,
        2,
        15,
        0
    )
    u.unit_id = "wolf"
    # 狼没有技能，直接用普攻
    return u

static func create_boss(region_difficulty: int) -> CombatUnit:
    var u = CombatUnit.new(
        "副本头目",
        200 + region_difficulty * 100,
        15 + region_difficulty * 5,
        5 + region_difficulty * 2,
        10,
        100
    )
    u.unit_id = "boss"
    return u
