extends Control

var battle_manager: BattleManager
var player: CombatUnit
var enemies: Array[CombatUnit]

@onready var battle_log: RichTextLabel = $VBox/BattleLog
@onready var start_button: Button = $VBox/StartButton
@onready var attack_button: Button = $VBox/AttackButton
@onready var escape_button: Button = $VBox/EscapeButton

func _ready() -> void:
	battle_log.text = "Click Start Battle to begin the combat test.\n"
	attack_button.disabled = true
	escape_button.disabled = true

	if SignalBus:
		SignalBus.battle_ended.connect(_on_battle_ended)

func _test_battle() -> void:
	battle_manager = BattleManager.new()
	add_child(battle_manager)

	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended_internal)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.action_executed.connect(_on_action_executed)

	player = CombatUnit.new("Player", 100, 15, 5, 12, 50)

	var enemy_a = EnemyTemplates.create_bandit(2)
	var enemy_b = EnemyTemplates.create_bandit(1)
	enemies = [enemy_a, enemy_b]

	battle_manager.start_battle(player, enemies)

	attack_button.disabled = false
	escape_button.disabled = false
	start_button.disabled = true

func _on_start_pressed() -> void:
	_test_battle()

func _on_attack_pressed() -> void:
	if battle_manager and battle_manager.state == BattleManager.BattleState.PLAYER_TURN:
		var target_index := -1
		for i in range(enemies.size()):
			if enemies[i].is_alive:
				target_index = i
				break

		if target_index >= 0:
			var result = battle_manager.execute_player_attack(target_index)
			_update_log(result.get("message", ""))

func _on_escape_pressed() -> void:
	if battle_manager == null:
		return

	var result = battle_manager.try_escape()
	_update_log(result.get("message", ""))
	if result.get("escaped", false):
		_end_test()

func _on_battle_started() -> void:
	_update_log("=== Battle Started ===")

func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	_update_log("[SignalBus] Battle ended. Victory=%s, EXP=%d, Gold=%d" % [
		str(victory),
		rewards.get("exp", 0),
		rewards.get("gold", 0)
	])

func _on_battle_ended_internal(victory: bool, rewards: Dictionary) -> void:
	if victory:
		_update_log("=== Victory ===")
		_update_log("EXP: %d" % rewards.get("exp", 0))
		_update_log("Gold: %d" % rewards.get("gold", 0))
		if SignalBus:
			SignalBus.exp_gained.emit(rewards.get("exp", 0))
	else:
		_update_log("=== Defeat ===")
	_end_test()

func _on_turn_started(is_player_turn: bool) -> void:
	if is_player_turn:
		_update_log("--- Player Turn ---")
	else:
		_update_log("--- Enemy Turn ---")

func _on_action_executed(_actor_name: String, result: Dictionary) -> void:
	_update_log(result.get("message", ""))

func _update_log(message: String) -> void:
	if message == "":
		return
	battle_log.append_text("\n" + message)
	battle_log.scroll_to_line(battle_log.get_line_count() - 1)

func _end_test() -> void:
	attack_button.disabled = true
	escape_button.disabled = true
	start_button.disabled = false

	if battle_manager:
		battle_manager.queue_free()
		battle_manager = null
