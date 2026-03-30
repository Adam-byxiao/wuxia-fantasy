# 世界渲染器 - Tile 网格渲染
# 整个世界是一个 Tiles 网格，每个 tile 根据噪声有地形和高度

extends Node2D

# 预加载配置类
const _Config = preload("res://scripts/world/world_renderer_config.gd")

# ============ 导出配置 ============
@export var render_scale: float = 4.0  # 每个 tile 渲染为 4x4 像素
@export var show_grid: bool = false     # 显示网格线
@export var show_region_names: bool = true  # 显示区域名称
@export var show_paths: bool = true     # 显示路径

# ============ 内部变量 ============
var _world: WorldData = null
var _current_season: String = "春"
var _world_texture: ImageTexture = null  # 整个世界的预渲染贴图
var _initialized: bool = false

# ============ 信号 ============
signal region_clicked(region_id: String)
signal region_hovered(region_id: String)

# ============ 生命周期 ============
func _ready() -> void:
	_initialized = true

# ============ 初始化 ============
func initialize(world: WorldData) -> void:
	_world = world
	_prerender_world()
	queue_redraw()

# ============ 预渲染整个世界 ============
func _prerender_world() -> void:
	if _world == null:
		return

	var width = WorldData.TILE_GRID_WIDTH
	var height = WorldData.TILE_GRID_HEIGHT
	var scaled_w = (width * render_scale) as int
	var scaled_h = (height * render_scale) as int

	# 创建世界图像
	var image = Image.create(scaled_w, scaled_h, false, Image.FORMAT_RGB8)

	for sy in range(scaled_h):
		for sx in range(scaled_w):
			# 反向映射到 tile 坐标
			var tile_x = sx / render_scale
			var tile_y = sy / render_scale

			var tile_data = _world.get_tile(tile_x as int, tile_y as int)
			var terrain = tile_data["terrain"]
			var tile_height = tile_data["height"]

			# 获取颜色
			var color = _get_tile_color(terrain, tile_height)

			image.set_pixel(sx, sy, color)

	# 创建纹理
	_world_texture = ImageTexture.create_from_image(image)

# ============ 获取 tile 颜色 ============
func _get_tile_color(terrain: String, height: float) -> Color:
	# 使用简单的高对比度颜色便于调试
	match terrain:
		"water": return Color(0.1, 0.2, 0.5)
		"wetland": return Color(0.2, 0.4, 0.2)
		"swamp": return Color(0.15, 0.35, 0.15)
		"plains": return Color(0.5, 0.6, 0.2)
		"hills": return Color(0.4, 0.5, 0.15)
		"forest": return Color(0.15, 0.4, 0.15)
		"mountain": return Color(0.5, 0.45, 0.35)
		"peak": return Color(0.7, 0.7, 0.75)
		_: return Color(0.5, 0.5, 0.5)

# ============ 绘制 ============
func _draw() -> void:
	if not _initialized:
		return

	if _world == null:
		_world = GameState.world_data

	if _world == null:
		return

	# 绘制整个世界纹理
	if _world_texture != null:
		draw_texture(_world_texture, Vector2.ZERO)

	# 绘制网格
	if show_grid:
		_draw_grid()

	# 绘制区域名称
	if show_region_names:
		_draw_region_labels()

# ============ 绘制网格 ============
func _draw_grid() -> void:
	var width = WorldData.TILE_GRID_WIDTH
	var height = WorldData.TILE_GRID_HEIGHT
	var grid_color = Color(0, 0, 0, 0.3)

	# 垂直线
	for x in range(0, width + 1, 10):
		var px = x * render_scale
		draw_line(Vector2(px, 0), Vector2(px, height * render_scale), grid_color, 1.0)

	# 水平线
	for y in range(0, height + 1, 10):
		var py = y * render_scale
		draw_line(Vector2(0, py), Vector2(width * render_scale, py), grid_color, 1.0)

# ============ 绘制区域标签 ============
func _draw_region_labels() -> void:
	if _world == null:
		return

	for region in _world.regions:
		# 计算区域中心
		var center_x = (region.tile_x + region.tile_w / 2) * render_scale
		var center_y = (region.tile_y + region.tile_h / 2) * render_scale
		var center = Vector2(center_x, center_y)

		# 绘制区域名称背景
		_draw_label_background(center, region.name)

		# 绘制区域名称
		_draw_label(region.name, center, Color.WHITE)

		# 绘制地标
		if region.landmark != "":
			var landmark_pos = center + Vector2(0, 20 * render_scale / 4.0)
			_draw_label("[" + region.landmark + "]", landmark_pos, Color(0.8, 0.8, 0.6))

# ============ 绘制标签 ============
func _draw_label_background(pos: Vector2, text: String) -> void:
	var font = ThemeDB.fallback_font
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var bg_rect = Rect2(
		pos.x - text_width / 2 - 4,
		pos.y - 10,
		text_width + 8,
		20
	)
	draw_rect(bg_rect, Color(0, 0, 0, 0.5), true)

func _draw_label(text: String, pos: Vector2, color: Color) -> void:
	var font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0, 0, 0, 0.5))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, color)

# ============ 公共方法 ============
func get_region_at_position(pos: Vector2) -> RegionData:
	if _world == null:
		return null

	# 将像素坐标转换为 tile 坐标
	var tile_x = (pos.x / render_scale) as int
	var tile_y = (pos.y / render_scale) as int

	for region in _world.regions:
		if tile_x >= region.tile_x and tile_x < region.tile_x + region.tile_w:
			if tile_y >= region.tile_y and tile_y < region.tile_y + region.tile_h:
				return region

	return null

func set_highlight(region_id: String) -> void:
	# 暂未实现高亮
	queue_redraw()

func clear_highlight() -> void:
	queue_redraw()

# ============ 季节系统 ============
func apply_season_overlay(season: String) -> void:
	_current_season = season
	_prerender_world()
	queue_redraw()

# ============ 输入处理 ============
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var region = get_region_at_position(event.position)
			if region != null:
				region_clicked.emit(region.id)
