class_name WorldData
extends RefCounted

var seed: int
var regions: Array
var paths: Array[Dictionary]
var locations: Array

const TILE_GRID_WIDTH: int = 160
const TILE_GRID_HEIGHT: int = 120

var tiles: Array = []

func _init(p_seed: int = 0):
	seed = p_seed
	regions = []
	paths = []
	locations = []
	_init_tiles()

func _init_tiles() -> void:
	tiles.clear()
	for i in range(TILE_GRID_WIDTH * TILE_GRID_HEIGHT):
		tiles.append({
			"terrain": "plains",
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
	var region_dicts: Array = []
	for region in regions:
		region_dicts.append(region.to_dict())

	var location_dicts: Array = []
	for location in locations:
		location_dicts.append(location.to_dict())

	return {
		"seed": seed,
		"regions": region_dicts,
		"paths": paths,
		"locations": location_dicts,
		"tiles": tiles
	}

func from_dict(data: Dictionary) -> WorldData:
	seed = data.get("seed", 0)
	regions = []
	for region_data in data.get("regions", []):
		regions.append(RegionData.new().from_dict(region_data))
	paths = data.get("paths", [])
	locations = []
	for location_data in data.get("locations", []):
		locations.append(LocationData.new().from_dict(location_data))
	tiles = data.get("tiles", [])
	return self

func get_region_by_id(region_id: String) -> RegionData:
	for region in regions:
		if region.id == region_id:
			return region
	return null

func get_location_by_id(location_id: String) -> LocationData:
	for location in locations:
		if location.id == location_id:
			return location
	return null

func get_locations_in_region(region_id: String) -> Array:
	var result: Array = []
	for location in locations:
		if location.region_id == region_id:
			result.append(location)
	return result

func get_primary_location_in_region(region_id: String) -> LocationData:
	var region = get_region_by_id(region_id)
	if region == null:
		return null
	for location_id in region.location_ids:
		var location = get_location_by_id(location_id)
		if location != null:
			return location
	var fallback = get_locations_in_region(region_id)
	if fallback.is_empty():
		return null
	return fallback[0]
