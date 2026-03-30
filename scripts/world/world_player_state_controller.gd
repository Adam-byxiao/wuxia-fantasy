extends Node

var main_root: Node2D
var player: CharacterBody2D

func _ready() -> void:
	main_root = get_parent() as Node2D

func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = _find_player()
	if player == null:
		return

	var bounds = _get_world_bounds()
	player.position.x = clamp(player.position.x, 16.0, bounds.x - 16.0)
	player.position.y = clamp(player.position.y, 16.0, bounds.y - 16.0)
	_sync_player_state()

func _find_player() -> CharacterBody2D:
	if main_root == null:
		return null
	var world_layer = main_root.get_node_or_null("WorldLayer")
	if world_layer == null:
		return null
	return world_layer.get_node_or_null("Player")

func _get_world_bounds() -> Vector2:
	if GameState.world_data == null:
		return Vector2(1920.0, 1080.0)

	var world_layer = main_root.get_node_or_null("WorldLayer")
	var renderer = world_layer.get_node_or_null("WorldRenderer") if world_layer != null else null
	var render_scale = 9.0
	if renderer != null:
		render_scale = float(renderer.get("render_scale"))

	return Vector2(
		WorldData.TILE_GRID_WIDTH * render_scale,
		WorldData.TILE_GRID_HEIGHT * render_scale
	)

func _sync_player_state() -> void:
	if GameState.player_data is PlayerData:
		GameState.player_data.position = player.position
	else:
		GameState.player_data = {"position": player.position}
