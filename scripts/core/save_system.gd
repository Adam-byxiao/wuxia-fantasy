extends Node

const SAVE_PATH = "user://save_game.json"

func save_game() -> bool:
	var save_data = {
		"version": "0.2.0",
		"current_day": GameState.current_day,
		"current_season": GameState.current_season,
		"current_region_id": GameState.current_region_id,
		"current_location_id": GameState.current_location_id,
		"current_location_type": GameState.current_location_type,
		"current_submap_scene": GameState.current_submap_scene
	}

	var json_str = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		SignalBus.game_saved.emit()
		return true
	return false

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			var data = json.get_data()
			GameState.current_day = data.get("current_day", 1)
			GameState.current_season = data.get("current_season", "春")
			GameState.current_region_id = data.get("current_region_id", "")
			GameState.current_location_id = data.get("current_location_id", "")
			GameState.current_location_type = data.get("current_location_type", "")
			GameState.current_submap_scene = data.get("current_submap_scene", "")
			SignalBus.game_loaded.emit()
			return true
	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
