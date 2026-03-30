extends Control

var battle_manager: BattleManager
var player: CombatUnit
var enemies: Array[CombatUnit]

@onready var battle_log: RichTextLabel = $VBox/BattleLog
@onready var start_button: Button = $VBox/StartButton
@onready var attack_button: Button = $VBox/AttackButton
@onready var escape_button: Button = $VBox/EscapeButton

func _ready():
    battle_log.text = "点击\"开始战斗\"按钮启动测试\n"
    attack_button.disabled = true
    escape_button.disabled = true

    # 连接信号
    if SignalBus:
        SignalBus.battle_ended.connect(_on_battle_ended)

func _test_battle():
    battle_manager = BattleManager.new()
    add_child(battle_manager)

    # 连接 BattleManager 信号
    battle_manager.battle_started.connect(_on_battle_started)
    battle_manager.battle_ended.connect(_on_battle_ended_internal)
    battle_manager.turn_started.connect(_on_turn_started)
    battle_manager.action_executed.connect(_on_action_executed)

    # 创建玩家
    player = CombatUnit.new("玩家", 100, 15, 5, 12, 50)

    # 创建敌人
    var e1 = EnemyTemplates.create_bandit(2)
    var e2 = EnemyTemplates.create_bandit(1)
    enemies = [e1, e2]

    # 开始战斗
    battle_manager.start_battle(player, enemies)

    attack_button.disabled = false
    escape_button.disabled = false
    start_button.disabled = true

func _on_start_pressed():
    _test_battle()

func _on_attack_pressed():
    if battle_manager and battle_manager.state == BattleManager.BattleState.PLAYER_TURN:
        # 攻击第一个活着的敌人
        var target_index = -1
        for i in range(enemies.size()):
            if enemies[i].is_alive:
                target_index = i
                break

        if target_index >= 0:
            var result = battle_manager.execute_player_attack(target_index)
            _update_log(result["message"])

func _on_escape_pressed():
    if battle_manager and battle_manager.try_escape():
        _update_log("逃跑成功！")
        _end_test()
    else:
        _update_log("逃跑失败！")

func _on_battle_started():
    _update_log("=== 战斗开始 ===")

func _on_battle_ended_internal(victory: bool, rewards: Dictionary):
    if victory:
        _update_log("=== 战斗胜利！ ===")
        _update_log("获得经验: %d" % rewards.get("exp", 0))
        _update_log("获得金币: %d" % rewards.get("gold", 0))
        if SignalBus:
            SignalBus.exp_gained.emit(rewards.get("exp", 0))
    else:
        _update_log("=== 战斗失败 ===")
    _end_test()

func _on_turn_started(is_player_turn: bool):
    if is_player_turn:
        _update_log("--- 玩家回合 ---")
    else:
        _update_log("--- 敌人回合 ---")

func _on_action_executed(actor_name: String, result: Dictionary):
    _update_log(result.get("message", ""))

func _update_log(msg: String):
    battle_log.append_text("\n" + msg)
    # 自动滚动到底部
    battle_log.scroll_to_line(battle_log.get_line_count() - 1)

func _end_test():
    attack_button.disabled = true
    escape_button.disabled = true
    start_button.disabled = false

    if battle_manager:
        battle_manager.queue_free()
        battle_manager = null
