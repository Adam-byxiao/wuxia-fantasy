extends Node

var _rng: RandomNumberGenerator
var _region_generator: RegionGenerator
var _terrain_config: TerrainConfig
var _noise_gen: RefCounted = null
var _NoiseGenerator = null

func _init():
	_region_generator = RegionGenerator.new()
	_terrain_config = TerrainConfig.new()
	_NoiseGenerator = load("res://scripts/world/noise_generator.gd")

func generate(seed_value: int) -> WorldData:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

	var world = WorldData.new(seed_value)
	_noise_gen = _NoiseGenerator.new(seed_value)

	_generate_terrain(world)
	var region_specs = _build_region_specs()
	_generate_regions(world, region_specs)
	_generate_locations(world, region_specs)
	_generate_paths(world)
	_stamp_region_tiles(world)
	_print_stats(world)
	_apply_world_state(world)
	return world

func _generate_terrain(world: WorldData) -> void:
	for y in range(WorldData.TILE_GRID_HEIGHT):
		for x in range(WorldData.TILE_GRID_WIDTH):
			var data = _noise_gen.get_terrain(x, y)
			world.set_tile(x, y, data["terrain"], data["height"])

func _build_region_specs() -> Array:
	return [
		{
			"id": "region_starting_village",
			"name": "\u9752\u77f3\u6751",
			"terrain": "town",
			"tile_x": 18,
			"tile_y": 24,
			"tile_w": 18,
			"tile_h": 18,
			"difficulty": 1,
			"landmark": "\u53e4\u4e95",
			"location_type": "village",
			"scene": "res://scenes/ui/town_scene.tscn"
		},
		{
			"id": "region_bamboo_forest",
			"name": "\u9752\u7af9\u6797",
			"terrain": "forest",
			"tile_x": 44,
			"tile_y": 18,
			"tile_w": 22,
			"tile_h": 24,
			"difficulty": 1,
			"landmark": "\u7af9\u4ead",
			"location_type": "wild",
			"scene": ""
		},
		{
			"id": "region_market_town",
			"name": "\u5e73\u5b89\u9547",
			"terrain": "town",
			"tile_x": 72,
			"tile_y": 36,
			"tile_w": 20,
			"tile_h": 20,
			"difficulty": 2,
			"landmark": "\u96c6\u5e02",
			"location_type": "town",
			"scene": "res://scenes/ui/town_scene.tscn"
		},
		{
			"id": "region_north_sect",
			"name": "\u5317\u5cb3\u95e8",
			"terrain": "mountain",
			"tile_x": 102,
			"tile_y": 20,
			"tile_w": 22,
			"tile_h": 22,
			"difficulty": 2,
			"landmark": "\u5c71\u95e8",
			"location_type": "sect",
			"scene": "res://scenes/ui/sect_scene.tscn"
		},
		{
			"id": "region_ruins",
			"name": "\u9ed1\u98ce\u9057\u8ff9",
			"terrain": "dungeon",
			"tile_x": 124,
			"tile_y": 54,
			"tile_w": 20,
			"tile_h": 18,
			"difficulty": 3,
			"landmark": "\u6b8b\u5854",
			"location_type": "ruins",
			"scene": ""
		}
	]

func _generate_regions(world: WorldData, region_specs: Array) -> void:
	for spec in region_specs:
		var region := RegionData.new(
			spec["id"],
			spec["name"],
			spec["tile_x"],
			spec["tile_y"],
			spec["tile_w"],
			spec["tile_h"],
			spec["terrain"],
			spec["difficulty"],
			2 + int(spec["difficulty"]),
			spec["landmark"]
		)
		region.location_ids.append(_location_id_for_region(spec["id"]))
		world.regions.append(region)

func _generate_locations(world: WorldData, region_specs: Array) -> void:
	for spec in region_specs:
		var region = world.get_region_by_id(spec["id"])
		if region == null:
			continue

		var location := LocationData.new(
			_location_id_for_region(spec["id"]),
			spec["name"],
			spec["location_type"],
			region.id,
			region.tile_x + int(region.tile_w / 2),
			region.tile_y + int(region.tile_h / 2),
			spec["scene"],
			spec["scene"] != "",
			{
				"landmark": spec["landmark"],
				"difficulty": spec["difficulty"]
			}
		)
		world.locations.append(location)

func _generate_paths(world: WorldData) -> void:
	world.paths = [
		{"from": "region_starting_village", "to": "region_bamboo_forest", "cost": 1.0},
		{"from": "region_bamboo_forest", "to": "region_market_town", "cost": 1.0},
		{"from": "region_market_town", "to": "region_north_sect", "cost": 1.0},
		{"from": "region_market_town", "to": "region_ruins", "cost": 1.0},
		{"from": "region_bamboo_forest", "to": "region_north_sect", "cost": 1.0}
	]

func _stamp_region_tiles(world: WorldData) -> void:
	for region in world.regions:
		for y in range(region.tile_y, region.tile_y + region.tile_h):
			for x in range(region.tile_x, region.tile_x + region.tile_w):
				var height = world.get_tile_height(x, y)
				world.set_tile(x, y, region.terrain_type, height)

func _location_id_for_region(region_id: String) -> String:
	return "location_" + region_id

func _apply_world_state(world: WorldData) -> void:
	GameState.world_data = world
	var starting_region = world.get_region_by_id("region_starting_village")
	if starting_region != null:
		GameState.current_region_id = starting_region.id
		GameState.current_region = starting_region.name
		var starting_location = world.get_primary_location_in_region(starting_region.id)
		if starting_location != null:
			GameState.current_location_id = starting_location.id
			GameState.current_location_type = starting_location.location_type
			GameState.current_submap_scene = starting_location.sub_scene_path
	SignalBus.world_generated.emit(world)

func _print_stats(world: WorldData) -> void:
	var counts: Dictionary = {}
	var min_h: float = 1.0
	var max_h: float = 0.0
	var sum_h: float = 0.0

	for y in range(WorldData.TILE_GRID_HEIGHT):
		for x in range(WorldData.TILE_GRID_WIDTH):
			var tile = world.get_tile(x, y)
			var terrain = tile["terrain"]
			var height = tile["height"]
			counts[terrain] = counts.get(terrain, 0) + 1
			min_h = minf(min_h, height)
			max_h = maxf(max_h, height)
			sum_h += height

	print("=== Terrain Stats ===")
	print("Height Range: ", min_h, " - ", max_h)
	print("Average Height: ", sum_h / float(WorldData.TILE_GRID_WIDTH * WorldData.TILE_GRID_HEIGHT))
	for terrain in counts:
		print("  ", terrain, ": ", counts[terrain])

func get_connected_regions(region_id: String) -> Array:
	var connected: Array = []
	var world = GameState.world_data
	if world == null:
		return connected
	for path in world.paths:
		if path.get("from") == region_id:
			connected.append(path["to"])
		elif path.get("to") == region_id:
			connected.append(path["from"])
	return connected

func find_path_between(from_id: String, to_id: String) -> Array:
	var world = GameState.world_data
	if world == null:
		return []
	if from_id == to_id:
		return [from_id]
	var queue: Array = [[from_id]]
	var visited: Dictionary = {from_id: true}
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var current: String = path[-1]
		for neighbor in get_connected_regions(current):
			if neighbor == to_id:
				var result: Array = path.duplicate()
				result.append(neighbor)
				return result
			if not visited.has(neighbor):
				visited[neighbor] = true
				var new_path: Array = path.duplicate()
				new_path.append(neighbor)
				queue.append(new_path)
	return []

func get_distance_between(from_id: String, to_id: String) -> int:
	var path = find_path_between(from_id, to_id)
	if path.is_empty():
		return -1
	return path.size() - 1

func get_region_center(region_id: String) -> Vector2:
	var world = GameState.world_data
	if world == null:
		return Vector2.ZERO
	var region = world.get_region_by_id(region_id)
	if region == null:
		return Vector2.ZERO
	return Vector2(
		(region.tile_x + region.tile_w / 2.0) * 32.0 / 20.0,
		(region.tile_y + region.tile_h / 2.0) * 32.0 / 20.0
	)
