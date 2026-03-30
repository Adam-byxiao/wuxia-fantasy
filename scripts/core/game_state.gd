extends Node

var current_day: int = 1
var current_season: String = "春"

# 核心数据引用（由各系统填充）
var world_data = null
var player_data = null
var player_cultivation = null
var player_inventory: InventoryData

# 当前区域
var current_region_id: String = ""
var current_region: String = ""  # 别名，兼容引用
var is_paused: bool = false

# 存档路径
const SAVE_PATH = "user://save_game.json"

func _init():
	player_inventory = InventoryData.new()

func reset():
	current_day = 1
	current_season = "春"
	current_region_id = ""
	current_region = ""
	is_paused = false
	world_data = null
	player_inventory.clear()
	# 添加初始物品
	for item in ItemTemplates.get_starting_items():
		player_inventory.add_item(item)
