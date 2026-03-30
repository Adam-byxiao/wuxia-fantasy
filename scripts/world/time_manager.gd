extends Node

signal day_passed(day: int)
signal season_changed(season: String)

const SEASONS = ["春", "夏", "秋", "冬"]
const DAYS_PER_SEASON = 30

var current_day: int = 1
var current_season: String = "春"
var time_scale: float = 1.0  # 1.0=正常, 10.0=10倍速

var _accumulated: float = 0.0
var _realtime_per_day: float = 10.0  # 10秒=1天

func _process(delta):
	_accumulated += delta * time_scale
	if _accumulated >= _realtime_per_day:
		_accumulated -= _realtime_per_day
		advance_day()

func advance_day():
	current_day += 1
	GameState.current_day = current_day
	day_passed.emit(current_day)

	var new_season = SEASONS[int(current_day as float / DAYS_PER_SEASON) % 4]
	if new_season != current_season:
		current_season = new_season
		GameState.current_season = current_season
		season_changed.emit(current_season)

func set_time_scale(scale: float):
	time_scale = scale
