extends Node

const PLAYER_SCENE = preload("res://scenes/entities/player/player.tscn")
const WORLD_RENDERER_SCENE = preload("res://scenes/world/world_renderer.tscn")

@export var seed: int = 20260327

var main_root: Node2D
var world_layer: Node2D
var generated_world: WorldData = null
var player: Player = null
var world_renderer: Node2D = null

func _ready() -> void:
	main_root = get_parent() as Node2D
	if main_root == null:
		return

	world_layer = main_root.get_node("WorldLayer")
	SignalBus.world_generated.connect(_on_world_generated)
	_ensure_world()

func _ensure_world() -> void:
	if GameState.world_data == null:
		generated_world = WorldGenerator.generate(seed)
	else:
		generated_world = GameState.world_data
		_on_world_generated(generated_world)

func _on_world_generated(world: WorldData) -> void:
	generated_world = world
	_ensure_world_renderer()
	_ensure_player()
	_place_player_at_start()

func _ensure_world_renderer() -> void:
	if world_renderer == null or not is_instance_valid(world_renderer):
		world_renderer = world_layer.get_node_or_null("WorldRenderer")
	if world_renderer == null:
		world_renderer = WORLD_RENDERER_SCENE.instantiate()
		world_renderer.name = "WorldRenderer"
		world_layer.add_child(world_renderer)
	if world_renderer.has_method("initialize"):
		world_renderer.initialize(generated_world)

func _ensure_player() -> void:
	if player == null or not is_instance_valid(player):
		player = world_layer.get_node_or_null("Player")
	if player == null:
		player = PLAYER_SCENE.instantiate()
		player.name = "Player"
		world_layer.add_child(player)

func _place_player_at_start() -> void:
	if player == null or generated_world == null:
		return

	var render_scale := _get_render_scale()
	var spawn_position = Vector2(64, 64)
	var current_location = generated_world.get_location_by_id(GameState.current_location_id)
	if current_location != null:
		spawn_position = Vector2(current_location.tile_x * render_scale, current_location.tile_y * render_scale)
	else:
		var current_region = generated_world.get_region_by_id(GameState.current_region_id)
		if current_region != null:
			spawn_position = Vector2(
				(current_region.tile_x + current_region.tile_w / 2.0) * render_scale,
				(current_region.tile_y + current_region.tile_h / 2.0) * render_scale
			)

	player.position = spawn_position
	if GameState.player_data is PlayerData:
		GameState.player_data.position = spawn_position
	else:
		GameState.player_data = {"position": spawn_position}

	if generated_world != null and world_renderer != null and world_renderer.has_method("get_region_at_position"):
		var region = world_renderer.get_region_at_position(spawn_position)
		if region != null:
			GameState.current_region_id = region.id
			GameState.current_region = region.name

func _get_render_scale() -> float:
	if world_renderer != null:
		return float(world_renderer.get("render_scale"))
	return 9.0
