extends Node

@export var interaction_radius_tiles: float = 3.0

var main_root: Node2D
var player: Node2D
var world_renderer: Node

func _ready() -> void:
	main_root = get_parent() as Node2D
	_refresh_refs()

func _process(_delta: float) -> void:
	_refresh_refs()
	var location = _get_nearby_location()
	if location != null:
		_update_prompt("\u6309 E \u8fdb\u5165\uff1a" + location.name)
		if Input.is_action_just_pressed("interact"):
			_enter_location(location)
	else:
		_update_prompt("")

func _refresh_refs() -> void:
	if main_root == null:
		return
	var world_layer = main_root.get_node_or_null("WorldLayer")
	if world_layer == null:
		return
	if player == null or not is_instance_valid(player):
		player = world_layer.get_node_or_null("Player")
	if world_renderer == null or not is_instance_valid(world_renderer):
		world_renderer = world_layer.get_node_or_null("WorldRenderer")
		if world_renderer != null and world_renderer.has_signal("location_clicked") and not world_renderer.location_clicked.is_connected(_on_location_clicked):
			world_renderer.location_clicked.connect(_on_location_clicked)

func _get_nearby_location() -> LocationData:
	if player == null or world_renderer == null or not world_renderer.has_method("get_location_at_position"):
		return null
	return world_renderer.get_location_at_position(player.position, interaction_radius_tiles)

func _on_location_clicked(location_id: String) -> void:
	var world = GameState.world_data
	if world == null:
		return
	var location = world.get_location_by_id(location_id)
	if location != null:
		_enter_location(location)

func _enter_location(location: LocationData) -> void:
	if not location.is_enterable or location.sub_scene_path == "":
		_update_prompt(location.name + " \u6682\u65f6\u8fd8\u4e0d\u80fd\u8fdb\u5165")
		return

	GameState.current_location_id = location.id
	GameState.current_location_type = location.location_type
	GameState.current_submap_scene = location.sub_scene_path
	GameState.current_region_id = location.region_id

	var world = GameState.world_data
	if world != null:
		var region = world.get_region_by_id(location.region_id)
		if region != null:
			GameState.current_region = region.name

	get_tree().change_scene_to_file(location.sub_scene_path)

func _update_prompt(text: String) -> void:
	if main_root == null:
		return
	var prompt_label = main_root.get_node_or_null("UILayer/WorldUIRoot/LocationPrompt")
	if prompt_label != null:
		prompt_label.text = text
