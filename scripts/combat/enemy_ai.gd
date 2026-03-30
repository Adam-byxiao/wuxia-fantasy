class_name EnemyAI
extends Node

# 简单AI：选择血量最低的目标 或 随机
func select_target(enemies: Array[CombatUnit]) -> CombatUnit:
    var alive = enemies.filter(func(e): e.is_alive)
    if alive.is_empty():
        return null

    # 简单策略：70%选最低血量，30%随机
    var rng = RandomNumberGenerator.new()
    if rng.randf() < 0.7:
        alive.sort_custom(func(a, b): a.current_health < b.current_health)
    return alive[randi() % alive.size()]
