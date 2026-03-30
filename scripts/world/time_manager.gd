extends Node

signal day_passed(day: int)
signal season_changed(season: String)

const SEASON_SPRING := "春"
const SEASON_SUMMER := "夏"
const SEASON_AUTUMN := "秋"
const SEASON_WINTER := "冬"
const SEASONS := [SEASON_SPRING, SEASON_SUMMER, SEASON_AUTUMN, SEASON_WINTER]
const DAYS_PER_SEASON := 30

var current_day: int = 1
var current_season: String = SEASON_SPRING
var time_scale: float = 1.0

var _accumulated: float = 0.0
var _realtime_per_day: float = 10.0

func _ready() -> void:
	GameState.current_day = current_day
	GameState.current_season = current_season

func _process(delta: float) -> void:
	if time_scale <= 0.0:
		return

	_accumulated += delta * time_scale
	if _accumulated >= _realtime_per_day:
		_accumulated -= _realtime_per_day
		advance_day()

func advance_day() -> void:
	current_day += 1
	GameState.current_day = current_day
	day_passed.emit(current_day)

	var new_season = get_season_for_day(current_day)
	if new_season != current_season:
		current_season = new_season
		GameState.current_season = current_season
		season_changed.emit(current_season)

func set_time_scale(scale: float) -> void:
	time_scale = maxf(0.0, scale)

func get_season_for_day(day: int) -> String:
	return SEASONS[int(day as float / DAYS_PER_SEASON) % SEASONS.size()]
