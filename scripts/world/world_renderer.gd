extends Node2D

const _Config = preload("res://scripts/world/world_renderer_config.gd")

@export var render_scale: float = 4.0
@export var show_grid: bool = false
@export var show_region_names: bool = true
@export var show_paths: bool = true
@export var show_locations: bool = true

var _world: WorldData = null
var _current_season: String = ""
var _world_texture: ImageTexture = null
var _initialized: bool = false

signal region_clicked(region_id: String)
signal region_hovered(region_id: String)
signal location_clicked(location_id: String)

func _ready() -> void:
	_initialized = true

func initialize(world: WorldData) -> void:
	_world = world
	_current_season = TimeManager.current_season
	_prerender_world()
	queue_redraw()

func _prerender_world() -> void:
	if _world == null:
		return

	var width = WorldData.TILE_GRID_WIDTH
	var height = WorldData.TILE_GRID_HEIGHT
	var scaled_w = int(width * render_scale)
	var scaled_h = int(height * render_scale)
	var image = Image.create(scaled_w, scaled_h, false, Image.FORMAT_RGB8)

	for sy in range(scaled_h):
		for sx in range(scaled_w):
			var tile_x = int(sx / render_scale)
			var tile_y = int(sy / render_scale)
			var tile_data = _world.get_tile(tile_x, tile_y)
			var color = _Config.get_terrain_color_by_height(
				tile_data["terrain"],
				tile_data["height"],
				_current_season
			)
			image.set_pixel(sx, sy, color)

	_world_texture = ImageTexture.create_from_image(image)

func _draw() -> void:
	if not _initialized:
		return

	if _world == null:
		_world = GameState.world_data

	if _world == null:
		return

	if _world_texture != null:
		draw_texture(_world_texture, Vector2.ZERO)

	if show_paths:
		_draw_paths()
	if show_locations:
		_draw_locations()
	if show_grid:
		_draw_grid()
	if show_region_names:
		_draw_region_labels()

func _draw_paths() -> void:
	for path in _world.paths:
		var from_region = _world.get_region_by_id(path.get("from", ""))
		var to_region = _world.get_region_by_id(path.get("to", ""))
		if from_region == null or to_region == null:
			continue
		draw_line(_region_center(from_region), _region_center(to_region), _Config.PATH_COLOR, _Config.PATH_WIDTH)

func _draw_locations() -> void:
	for location in _world.locations:
		var pos = Vector2(location.tile_x * render_scale, location.tile_y * render_scale)
		var color = Color(0.95, 0.85, 0.3) if location.is_enterable else Color(0.7, 0.7, 0.7)
		draw_circle(pos, 4.0 + render_scale * 0.5, color)
		draw_circle(pos, 6.0 + render_scale * 0.5, Color(0, 0, 0, 0.35), false, 2.0)

func _draw_grid() -> void:
	var width = WorldData.TILE_GRID_WIDTH
	var height = WorldData.TILE_GRID_HEIGHT
	var grid_color = Color(0, 0, 0, 0.3)
	for x in range(0, width + 1, 10):
		var px = x * render_scale
		draw_line(Vector2(px, 0), Vector2(px, height * render_scale), grid_color, 1.0)
	for y in range(0, height + 1, 10):
		var py = y * render_scale
		draw_line(Vector2(0, py), Vector2(width * render_scale, py), grid_color, 1.0)

func _draw_region_labels() -> void:
	for region in _world.regions:
		var center = _region_center(region)
		_draw_label_background(center, region.name)
		_draw_label(region.name, center, Color.WHITE)
		if region.landmark != "":
			_draw_label("[" + region.landmark + "]", center + Vector2(0, 20), Color(0.85, 0.82, 0.65))

func _draw_label_background(pos: Vector2, text: String) -> void:
	var font = ThemeDB.fallback_font
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var bg_rect = Rect2(pos.x - text_width / 2.0 - 4.0, pos.y - 10.0, text_width + 8.0, 20.0)
	draw_rect(bg_rect, Color(0, 0, 0, 0.5), true)

func _draw_label(text: String, pos: Vector2, color: Color) -> void:
	var font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0, 0, 0, 0.5))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, color)

func _region_center(region: RegionData) -> Vector2:
	return Vector2(
		(region.tile_x + region.tile_w / 2.0) * render_scale,
		(region.tile_y + region.tile_h / 2.0) * render_scale
	)

func get_region_at_position(pos: Vector2) -> RegionData:
	if _world == null:
		return null

	var tile_x = int(pos.x / render_scale)
	var tile_y = int(pos.y / render_scale)
	for region in _world.regions:
		if tile_x >= region.tile_x and tile_x < region.tile_x + region.tile_w:
			if tile_y >= region.tile_y and tile_y < region.tile_y + region.tile_h:
				return region
	return null

func get_location_at_position(pos: Vector2, radius_in_tiles: float = 2.0) -> LocationData:
	if _world == null:
		return null

	var tile_x = pos.x / render_scale
	var tile_y = pos.y / render_scale
	for location in _world.locations:
		var dx = tile_x - location.tile_x
		var dy = tile_y - location.tile_y
		if sqrt(dx * dx + dy * dy) <= radius_in_tiles:
			return location
	return null

func set_highlight(region_id: String) -> void:
	queue_redraw()

func clear_highlight() -> void:
	queue_redraw()

func apply_season_overlay(season: String) -> void:
	_current_season = season
	_prerender_world()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var location = get_location_at_position(event.position)
		if location != null:
			location_clicked.emit(location.id)
			return
		var region = get_region_at_position(event.position)
		if region != null:
			region_clicked.emit(region.id)
