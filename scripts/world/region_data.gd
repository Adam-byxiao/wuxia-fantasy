class_name RegionData
extends RefCounted

var id: String
var name: String
var tile_x: int
var tile_y: int
var tile_w: int
var tile_h: int
var terrain_type: String
var difficulty: int
var npc_spawn_count: int
var landmark: String
var location_ids: Array[String]

func _init(
	p_id: String = "",
	p_name: String = "",
	p_tile_x: int = 0,
	p_tile_y: int = 0,
	p_tile_w: int = 32,
	p_tile_h: int = 32,
	p_terrain: String = "forest",
	p_difficulty: int = 1,
	p_npc_count: int = 3,
	p_landmark: String = "",
	p_location_ids: Array[String] = []
):
	id = p_id
	name = p_name
	tile_x = p_tile_x
	tile_y = p_tile_y
	tile_w = p_tile_w
	tile_h = p_tile_h
	terrain_type = p_terrain
	difficulty = p_difficulty
	npc_spawn_count = p_npc_count
	landmark = p_landmark
	location_ids = p_location_ids.duplicate()

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"tile_x": tile_x,
		"tile_y": tile_y,
		"tile_w": tile_w,
		"tile_h": tile_h,
		"terrain_type": terrain_type,
		"difficulty": difficulty,
		"npc_spawn_count": npc_spawn_count,
		"landmark": landmark,
		"location_ids": location_ids
	}

func from_dict(data: Dictionary) -> RegionData:
	id = data.get("id", "")
	name = data.get("name", "")
	tile_x = data.get("tile_x", 0)
	tile_y = data.get("tile_y", 0)
	tile_w = data.get("tile_w", 32)
	tile_h = data.get("tile_h", 32)
	terrain_type = data.get("terrain_type", "forest")
	difficulty = data.get("difficulty", 1)
	npc_spawn_count = data.get("npc_spawn_count", 3)
	landmark = data.get("landmark", "")
	location_ids = data.get("location_ids", [])
	return self
