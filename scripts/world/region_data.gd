class_name RegionData
extends RefCounted

var id: String
var name: String
var tile_x: int
var tile_y: int
var tile_w: int
var tile_h: int
var terrain_type: String  # forest, mountain, town, dungeon, road, special
var difficulty: int
var npc_spawn_count: int
var landmark: String

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
    p_landmark: String = ""
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
        "landmark": landmark
    }

func from_dict(d: Dictionary) -> RegionData:
    id = d.get("id", "")
    name = d.get("name", "")
    tile_x = d.get("tile_x", 0)
    tile_y = d.get("tile_y", 0)
    tile_w = d.get("tile_w", 32)
    tile_h = d.get("tile_h", 32)
    terrain_type = d.get("terrain_type", "forest")
    difficulty = d.get("difficulty", 1)
    npc_spawn_count = d.get("npc_spawn_count", 3)
    landmark = d.get("landmark", "")
    return self
