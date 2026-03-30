extends Node

@export var generate_at_start: bool = true

func _ready() -> void:
	if generate_at_start:
		run_verification()

func run_verification() -> void:
	print("=== Texture / Noise Verification ===")
	verify_noise()
	verify_world_generation()
	print("=== Verification Complete ===")

func verify_noise() -> void:
	print("--- Noise Generator ---")
	var noise = NoiseGenerator.new(12345)
	var sample_points = [
		Vector2i(0, 0),
		Vector2i(32, 24),
		Vector2i(80, 60),
		Vector2i(120, 90)
	]

	for point in sample_points:
		var data = noise.get_terrain(point.x, point.y)
		print("Point ", point, " => terrain=", data["terrain"], " height=", data["height"])

func verify_world_generation() -> void:
	print("--- World Generator ---")
	var world = WorldGenerator.generate(20260327)
	if world == null:
		push_error("WorldGenerator returned null")
		return

	print("Regions: ", world.regions.size())
	print("Locations: ", world.locations.size())
	print("Paths: ", world.paths.size())

	for region in world.regions:
		print("Region: ", region.id, " / ", region.name, " / difficulty=", region.difficulty)

	for location in world.locations:
		print("Location: ", location.id, " / ", location.name, " / type=", location.location_type, " / enterable=", location.is_enterable)
