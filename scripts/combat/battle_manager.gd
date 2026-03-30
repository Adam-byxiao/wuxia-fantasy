class_name BattleManager
extends Node

# 信号定义
signal battle_started
signal battle_ended(victory: bool, rewards: Dictionary)
signal turn_started(is_player_turn: bool)
signal action_executed(actor_name: String, result: Dictionary)
signal battle_log_updated(log_entry: String)
signal escape_attempt(escaped: bool)

# 战斗状态枚举
enum BattleState {
    IDLE,           # 等待开始
    PLAYER_TURN,   # 玩家回合
    ENEMY_TURN,    # 敌人回合
    ANIMATING,     # 动画播放中
    ENDED          # 战斗结束
}

# 内部变量
var state: int = BattleState.IDLE
var player: CombatUnit
var enemies: Array[CombatUnit]
var battle_log: Array[String] = []
var rng: RandomNumberGenerator

# 逃跑成功率
const ESCAPE_SUCCESS_RATE: float = 0.5

func _init():
    rng = RandomNumberGenerator.new()

# ==================== 公开接口 ====================

# 开始战斗
func start_battle(player_unit: CombatUnit, enemy_units: Array[CombatUnit]) -> void:
    player = player_unit
    enemies = enemy_units

    # 初始化
    for e in enemies:
        e.is_player = false
    player.is_player = true

    battle_log.clear()
    state = BattleState.PLAYER_TURN

    _log("=== 战斗开始！===")
    _log("你遇到了 %d 个敌人！" % enemies.size())

    battle_started.emit()
    turn_started.emit(true)

# 执行玩家普通攻击
func execute_player_attack(target_index: int) -> Dictionary:
    if state != BattleState.PLAYER_TURN:
        return _fail_result("当前不是你的回合")

    if not _is_valid_target(target_index):
        return _fail_result("无效的目标")

    var target = enemies[target_index]
    if not target.is_alive:
        return _fail_result("目标已死亡")

    # 计算伤害（考虑暴击）
    var base_damage = player.get_attack_with_realm()
    var damage = player.calc_crit_damage(base_damage)
    var actual = target.take_damage(damage)

    var crit_text = " (暴击!)" if damage > base_damage else ""
    var result = {
        "success": true,
        "damage": actual,
        "crit": crit_text != "",
        "message": "你对 %s 造成了 %d 点伤害%s" % [target.name, actual, crit_text]
    }

    _execute_result(result)

    return result

# 执行玩家技能攻击
func execute_player_skill(skill_index: int, target_index: int) -> Dictionary:
    if state != BattleState.PLAYER_TURN:
        return _fail_result("当前不是你的回合")

    if skill_index < 0 or skill_index >= player.skills.size():
        return _fail_result("无效的技能")

    var skill = player.skills[skill_index]

    # 检查冷却
    var cooldown = player.get_skill_cooldown(skill.skill_id)
    if cooldown > 0:
        return _fail_result("%s 还在冷却中 (%d回合)" % [skill.name, cooldown])

    # 检查内力
    if not player.use_qi(skill.qi_cost):
        return _fail_result("内力不足，需要 %d 点" % skill.qi_cost)

    if not _is_valid_target(target_index) and skill.target_type == SkillData.TargetType.SINGLE_ENEMY:
        return _fail_result("无效的目标")

    # 使用技能
    player.use_skill(skill)

    var target = enemies[target_index]
    var damage = skill.damage
    var actual = target.take_damage(damage)

    var result = {
        "success": true,
        "skill_name": skill.name,
        "damage": actual,
        "message": "你使用了 %s，对 %s 造成了 %d 点伤害" % [skill.name, target.name, actual]
    }

    _execute_result(result)

    return result

# 玩家使用物品
func execute_player_item(item_id: String, target_index: int) -> Dictionary:
    if state != BattleState.PLAYER_TURN:
        return _fail_result("当前不是你的回合")

    var inv = GameState.player_inventory
    var entry = inv.get_item(item_id)
    if not entry["item"]:
        return _fail_result("物品不存在")

    var item = entry["item"]

    # 检查是否是战斗可用物品
    if item.type != ItemData.ItemType.PILl and item.type != ItemData.ItemType.CONSUMABLE:
        return _fail_result("战斗中无法使用此物品")

    # 根据物品类型执行效果
    var result: Dictionary
    match item.type:
        ItemData.ItemType.PILl:
            # 丹药恢复
            if item.heal_amount > 0:
                var old_hp = player.current_health
                player.heal(item.heal_amount)
                var healed = player.current_health - old_hp
                result = {
                    "success": true,
                    "heal": healed,
                    "message": "你使用了 %s，恢复 %d 点生命" % [item.name, healed]
                }
            elif item.qi恢复_amount > 0:
                var old_qi = player.current_qi
                player.restore_qi(item.qi恢复_amount)
                var restored = player.current_qi - old_qi
                result = {
                    "success": true,
                    "heal": restored,
                    "message": "你使用了 %s，恢复 %d 点内力" % [item.name, restored]
                }
            elif item.exp_amount > 0:
                result = {
                    "success": true,
                    "exp": item.exp_amount,
                    "message": "你使用了 %s，获得 %d 经验" % [item.name, item.exp_amount]
                }
                # 实际添加经验由调用者处理
            else:
                return _fail_result("无法使用此物品")
        ItemData.ItemType.CONSUMABLE:
            # 暗器对敌人造成伤害
            if item.damage_amount > 0 and _is_valid_target(target_index):
                var target = enemies[target_index]
                var actual = target.take_damage(item.damage_amount)
                result = {
                    "success": true,
                    "damage": actual,
                    "message": "你对 %s 使用了 %s，造成 %d 点伤害" % [target.name, item.name, actual]
                }
            else:
                return _fail_result("无法使用此物品")

    # 消耗物品
    inv.remove_item(item_id, 1)

    _execute_result(result)
    return result

# 尝试逃跑
func try_escape() -> Dictionary:
    if state != BattleState.PLAYER_TURN:
        return _fail_result("当前不是你的回合")

    var success = rng.randf() < ESCAPE_SUCCESS_RATE

    var result: Dictionary
    if success:
        result = {
            "success": true,
            "escaped": true,
            "message": "你成功逃跑了！"
        }
        state = BattleState.ENDED
        battle_ended.emit(false, {})  # 逃跑算作失败
    else:
        result = {
            "success": true,
            "escaped": false,
            "message": "逃跑失败！"
        }

    _log(result["message"])
    escape_attempt.emit(success)

    if not success:
        # 逃跑失败，敌人反击
        _start_enemy_turn()

    return result

# 获取当前状态
func get_state() -> int:
    return state

# 获取战斗日志
func get_battle_log() -> Array[String]:
    return battle_log

# 获取敌人列表
func get_enemies() -> Array[CombatUnit]:
    return enemies

# 获取玩家
func get_player() -> CombatUnit:
    return player

# ==================== 内部方法 ====================

func _execute_result(result: Dictionary) -> void:
    _log(result["message"])
    action_executed.emit(player.name if "skill_name" not in result else player.name, result)

    # 检查战斗是否结束
    if _check_all_enemies_dead():
        _end_battle(true)
        return

    # 进入敌人回合
    _start_enemy_turn()

func _start_enemy_turn() -> void:
    state = BattleState.ENEMY_TURN
    turn_started.emit(false)

    # 敌人AI行动
    for enemy in enemies:
        if not enemy.is_alive:
            continue

        # 简单AI：总是攻击
        var damage = enemy.get_attack_with_realm()
        var actual = player.take_damage(damage)
        var result_msg = "%s 攻击了你，造成 %d 点伤害" % [enemy.name, actual]

        _log(result_msg)
        action_executed.emit(enemy.name, {"damage": actual, "message": result_msg})

        # 检查玩家是否死亡
        if not player.is_alive:
            _end_battle(false)
            return

    # 敌人回合结束，玩家回合开始
    player.reduce_cooldowns()  # 减少技能冷却
    state = BattleState.PLAYER_TURN
    turn_started.emit(true)

func _check_all_enemies_dead() -> bool:
    for e in enemies:
        if e.is_alive:
            return false
    return true

func _is_valid_target(index: int) -> bool:
    return index >= 0 and index < enemies.size() and enemies[index].is_alive

func _fail_result(message: String) -> Dictionary:
    return {"success": false, "message": message}

func _end_battle(victory: bool) -> void:
    state = BattleState.ENDED

    var rewards: Dictionary
    if victory:
        var total_exp = 0
        var total_gold = 0
        var loot: Array[Dictionary] = []

        for e in enemies:
            total_exp += _calc_exp_reward(e)
            total_gold += _calc_gold_reward(e)
            # TODO: 物品掉落

        rewards = {
            "exp": total_exp,
            "gold": total_gold,
            "loot": loot
        }

        _log("=== 战斗胜利！===")
        _log("获得经验: %d" % total_exp)
        _log("获得金币: %d" % total_gold)
    else:
        # 失败时给10点安慰经验
        var exp_consolation = 10
        rewards = {
            "exp": exp_consolation,
            "gold": 0,
            "loot": []
        }
        _log("=== 战斗失败...===")
        _log("获得鼓励经验: %d" % exp_consolation)

    battle_ended.emit(victory, rewards)

func _calc_exp_reward(enemy: CombatUnit) -> int:
    # 基础经验 + 难度加成
    return 50 + enemy.max_health / 2

func _calc_gold_reward(enemy: CombatUnit) -> int:
    return 20 + enemy.attack * 2

func _log(message: String) -> void:
    battle_log.append(message)
    battle_log_updated.emit(message)
