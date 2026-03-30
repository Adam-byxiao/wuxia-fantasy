class_name WorldData
extends RefCounted

var seed: int
var regions: Array  # Array[RegionData] - 存储区域数据
var paths: Array[Dictionary]  # {"from": region_id, "to": region_id, "cost": int}

# Tile 网格配置
const TILE_GRID_WIDTH: int = 160
const TILE_GRID_HEIGHT: int = 120

# Tile 网格数据 (flattened 2D array: tiles[y * width + x])
var tiles: Array = []

func _init(p_seed: int = 0):
    seed = p_seed
    regions = []  # 初始化为空数组
    paths = []
    _init_tiles()

func _init_tiles() -> void:
    tiles.clear()
    for i in range(TILE_GRID_WIDTH * TILE_GRID_HEIGHT):
        tiles.append({
            "terrain": "plains",  # 默认地形
            "height": 0.5
        })

func get_tile(x: int, y: int) -> Dictionary:
    if x < 0 or x >= TILE_GRID_WIDTH or y < 0 or y >= TILE_GRID_HEIGHT:
        return {"terrain": "water", "height": 0.0}
    return tiles[y * TILE_GRID_WIDTH + x]

func set_tile(x: int, y: int, terrain: String, height: float) -> void:
    if x < 0 or x >= TILE_GRID_WIDTH or y < 0 or y >= TILE_GRID_HEIGHT:
        return
    tiles[y * TILE_GRID_WIDTH + x] = {"terrain": terrain, "height": height}

func get_tile_terrain(x: int, y: int) -> String:
    return get_tile(x, y)["terrain"]

func get_tile_height(x: int, y: int) -> float:
    return get_tile(x, y)["height"]

func to_dict() -> Dictionary:
    return {
        "seed": seed,
        "regions": regions.map(func(r): r.to_dict()),
        "paths": paths,
        "tiles": tiles
    }

func from_dict(d: Dictionary) -> WorldData:
    seed = d.get("seed", 0)
    regions = []
    for rd in d.get("regions", []):
        regions.append(RegionData.new().from_dict(rd))
    paths = d.get("paths", [])
    tiles = d.get("tiles", [])
    return self

func get_region_by_id(rid: String) -> RegionData:
    for r in regions:
        if r.id == rid:
            return r
    return null
