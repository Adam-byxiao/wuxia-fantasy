extends Node

var current_day: int = 1
var current_season: String = "春"

var world_data = null
var player_data = null
var player_cultivation = null
var player_inventory: InventoryData

var current_region_id: String = ""
var current_region: String = ""
var current_location_id: String = ""
var current_location_type: String = ""
var current_submap_scene: String = ""
var is_paused: bool = false

const SAVE_PATH = "user://save_game.json"

func _init():
	player_inventory = InventoryData.new()

func reset():
	current_day = 1
	current_season = "春"
	current_region_id = ""
	current_region = ""
	current_location_id = ""
	current_location_type = ""
	current_submap_scene = ""
	is_paused = false
	world_data = null
	player_inventory.clear()
	for item in ItemTemplates.get_starting_items():
		player_inventory.add_item(item)
