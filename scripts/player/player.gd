class_name Player
extends CharacterBody2D

@export var player_name: String = "无名侠客"

var player_data: PlayerData
var combat_unit: CombatUnit
var move_speed: float = 200.0

func _ready() -> void:
	player_data = PlayerData.new()
	_create_combat_unit()
	GameState.player_data = player_data

func _create_combat_unit() -> void:
	var stats := _get_initial_combat_stats()
	combat_unit = CombatUnit.new(
		player_name,
		stats.get("max_health", 100),
		stats.get("attack", 10),
		stats.get("defense", 5),
		stats.get("speed", 8),
		stats.get("max_qi", 50)
	)
	combat_unit.is_player = true

func _get_initial_combat_stats() -> Dictionary:
	var fallback_stats := {
		"max_health": 100,
		"max_qi": 50,
		"attack": 10,
		"defense": 5,
		"speed": 8
	}

	if has_node("/root/CultivationSystem"):
		var cultivation_system = get_node("/root/CultivationSystem")
		if cultivation_system != null and cultivation_system.has_method("get_combat_stats"):
			return cultivation_system.get_combat_stats()

	return fallback_stats

func _physics_process(delta: float) -> void:
	var input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	if input_dir != Vector2.ZERO:
		position += input_dir * move_speed * delta

func get_combat_unit() -> CombatUnit:
	return combat_unit
