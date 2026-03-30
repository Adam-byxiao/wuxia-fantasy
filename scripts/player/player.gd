class_name Player
extends CharacterBody2D

@export var player_name: String = "无名侠客"

var player_data: PlayerData
var combat_unit: CombatUnit
var move_speed: float = 200.0

func _ready():
    player_data = PlayerData.new()
    _create_combat_unit()
    GameState.player_data = player_data

func _create_combat_unit():
    var stats = CultivationSystem.new().get_combat_stats() if has_node("/root/CultivationSystem") else {
        "max_health": 100, "max_qi": 50, "attack": 10, "defense": 5, "speed": 8
    }
    combat_unit = CombatUnit.new(
        player_name,
        stats.get("max_health", 100),
        stats.get("attack", 10),
        stats.get("defense", 5),
        stats.get("speed", 8),
        stats.get("max_qi", 50)
    )
    combat_unit.is_player = true

func _physics_process(delta):
    var input_dir = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    ).normalized()

    if input_dir != Vector2.ZERO:
        position += input_dir * move_speed * delta

func get_combat_unit() -> CombatUnit:
    return combat_unit
