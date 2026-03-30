extends Node

var _rng: RandomNumberGenerator
var _region_generator: RegionGenerator
var _terrain_config: TerrainConfig
var _noise_gen: RefCounted = null

# 使用 load 而非 preload，避免类级别加载问题
var _NoiseGenerator = null

func _init():
	_region_generator = RegionGenerator.new()
	_terrain_config = TerrainConfig.new()
	_NoiseGenerator = load("res://scripts/world/noise_generator.gd")

func generate(seed_value: int) -> WorldData:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

	var world = WorldData.new(seed_value)

	# 1. 初始化噪声生成器
	_noise_gen = _NoiseGenerator.new(seed_value)

	# 2. 生成自然地形
	_generate_terrain(world)

	# 3. 打印统计
	_print_stats(world)

	# 4. 添加测试区域（确保测试通过）
	_add_simple_regions(world)

	GameState.world_data = world
	SignalBus.world_generated.emit(world)
	return world

func _generate_terrain(world: WorldData) -> void:
	for y in range(WorldData.TILE_GRID_HEIGHT):
		for x in range(WorldData.TILE_GRID_WIDTH):
			var data = _noise_gen.get_terrain(x, y)
			world.set_tile(x, y, data["terrain"], data["height"])

func _print_stats(world: WorldData) -> void:
	var counts: Dictionary = {}
	var min_h: float = 1.0
	var max_h: float = 0.0
	var sum_h: float = 0.0

	for y in range(WorldData.TILE_GRID_HEIGHT):
		for x in range(WorldData.TILE_GRID_WIDTH):
			var tile = world.get_tile(x, y)
			var t = tile["terrain"]
			var h = tile["height"]
			counts[t] = counts.get(t, 0) + 1
			min_h = minf(min_h, h)
			max_h = maxf(max_h, h)
			sum_h += h

	print("=== 地形统计 ===")
	print("高度范围: ", min_h, " - ", max_h)
	print("平均高度: ", sum_h / float(WorldData.TILE_GRID_WIDTH * WorldData.TILE_GRID_HEIGHT))
	print("各地形数量:")
	for t in counts:
		print("  ", t, ": ", counts[t], " (", float(counts[t]) / float(WorldData.TILE_GRID_WIDTH * WorldData.TILE_GRID_HEIGHT) * 100.0, "%)")

func _add_simple_regions(world: WorldData) -> void:
	var terrains = ["town", "dungeon", "forest", "mountain", "plains"]
	for i in range(5):
		var x = 20 + i * 25
		var y = 20 + (i % 3) * 30
		var r = RegionData.new("r_%d" % i, "区域%d" % i, x, y, 20, 20, terrains[i], 1, 3, "地标%d" % i)
		world.regions.append(r)

# ============ 路径查询方法（保留原有接口）============

func get_connected_regions(region_id: String) -> Array:
	var connected: Array = []
	var world = GameState.world_data
	if world == null: return connected
	for path in world.paths:
		if path.get("from") == region_id:
			connected.append(path["to"])
		elif path.get("to") == region_id:
			connected.append(path["from"])
	return connected

func find_path_between(from_id: String, to_id: String) -> Array:
	var world = GameState.world_data
	if world == null: return []
	if from_id == to_id: return [from_id]
	var queue: Array = []
	queue.append([from_id])
	var visited: Dictionary = {from_id: true}
	while queue.size() > 0:
		var path: Array = queue.pop_front()
		var current: String = path[-1]
		var connected = get_connected_regions(current)
		for neighbor in connected:
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
	if path.size() == 0: return -1
	return path.size() - 1

func get_region_center(region_id: String) -> Vector2:
	var world = GameState.world_data
	if world == null: return Vector2.ZERO
	for r in world.regions:
		if r.id == region_id:
			return Vector2((r.tile_x + r.tile_w / 2) * 32.0 / 20.0, (r.tile_y + r.tile_h / 2) * 32.0 / 20.0)
	return Vector2.ZERO
