extends Node

@export var event_configs: Array[EventConfig]

var _last_event_day: int = 0
var _rng: RandomNumberGenerator

func _ready():
	_rng = RandomNumberGenerator.new()
	TimeManager.day_passed.connect(_on_day_passed)

func _on_day_passed(day: int):
	if day - _last_event_day < 2:
		return

	var selected = _weighted_random_select()
	if selected and _check_conditions(selected):
		_execute_event(selected)
		_last_event_day = day

func _weighted_random_select() -> EventConfig:
	if event_configs.is_empty():
		return null

	var total_weight = 0
	for e in event_configs:
		total_weight += e.weight

	if total_weight == 0:
		return null

	_rng.seed = TimeManager.current_day
	var roll = _rng.randi() % total_weight

	var current = 0
	for e in event_configs:
		current += e.weight
		if roll < current:
			return e
	return null

func _check_conditions(config: EventConfig) -> bool:
	if TimeManager.current_day < config.min_day:
		return false
	return true

func _execute_event(config: EventConfig):
	print("[事件] ", config.name, " 发生了！")
	SignalBus.world_event_triggered.emit(config.event_id, config.name)
