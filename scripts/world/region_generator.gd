class_name RegionGenerator
extends Node

var _terrain_config: TerrainConfig

func _init():
    _terrain_config = TerrainConfig.new()

func generate_region(region_type: String, difficulty: int, rng: RandomNumberGenerator) -> RegionData:
    var id = "region_%s_%d" % [region_type, rng.randi()]
    var name = _terrain_config.generate_region_name(region_type, rng)
    var landmark = _get_random_landmark(region_type, rng)
    var npc_count = _calc_npc_count(region_type, difficulty)
    var size = _calc_region_size(region_type)

    return RegionData.new(
        id,
        name,
        0, 0,  # tile_x, tile_y 由 world_generator 布局时设置
        size.x, size.y,
        region_type,
        difficulty,
        npc_count,
        landmark
    )

func _get_random_landmark(terrain: String, rng: RandomNumberGenerator) -> String:
    var landmarks = _terrain_config.terrain_landmarks.get(terrain, ["无名地"])
    return landmarks[rng.randi() % landmarks.size()]

func _calc_npc_count(terrain: String, difficulty: int) -> int:
    var base = 3
    match terrain:
        "town": base = 8
        "dungeon": base = 5
        "road": base = 2
    return base + difficulty

func _calc_region_size(terrain: String) -> Vector2i:
    match terrain:
        "town": return Vector2i(24, 24)
        "dungeon": return Vector2i(20, 20)
        "road": return Vector2i(16, 16)
    return Vector2i(32, 32)
