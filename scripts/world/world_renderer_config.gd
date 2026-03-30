# 世界渲染配置常量
# 存放渲染相关的常量配置

# 不继承 Node，改为 RefCounted 以便作为纯类使用
# 如需在场景中使用，请在 project.godot 中添加为 Autoload 或使用实例

# ============ 渲染尺寸配置 ============
const CELL_PIXEL_SIZE: int = 32
const TILE_SIZE: int = 64
const WORLD_TILES_X: int = 160
const WORLD_TILES_Y: int = 120

# 每个 tile 的像素大小（用于程序化渲染）
const TILE_PIXEL_SIZE: int = 1

# ============ 高度配置 ============
const WATER_LEVEL: float = 0.2   # 水域阈值
const WETLAND_LEVEL: float = 0.35  # 湿地阈值
const PLAINS_LEVEL: float = 0.45    # 平原阈值
const HILLS_LEVEL: float = 0.55     # 丘陵阈值

# ============ 地形类型（按高度排序） ============
const TERRAIN_TYPES: Array[String] = [
	"water", "wetland", "swamp", "plains", "hills", "forest", "mountain", "peak", "town", "dungeon", "road", "special"
]

# ============ 季节色调配置 ============
const SEASON_COLORS: Dictionary = {
	"春": {
		"water": Color(0.15, 0.35, 0.6),
		"wetland": Color(0.35, 0.5, 0.35),
		"swamp": Color(0.25, 0.4, 0.25),
		"tundra": Color(0.4, 0.45, 0.4),
		"desert": Color(0.7, 0.6, 0.3),
		"rainforest": Color(0.1, 0.35, 0.1),
		"taiga": Color(0.2, 0.3, 0.25),
		"snow": Color(0.85, 0.88, 0.92),
		"plains": Color(0.45, 0.6, 0.2),
		"hills": Color(0.35, 0.5, 0.15),
		"forest": Color(0.15, 0.45, 0.15),
		"mountain": Color(0.45, 0.4, 0.35),
		"peak": Color(0.7, 0.7, 0.75),
		"town": Color(0.6, 0.55, 0.45),
		"dungeon": Color(0.25, 0.22, 0.28),
		"road": Color(0.55, 0.5, 0.4),
		"special": Color(0.2, 0.3, 0.5)
	},
	"夏": {
		"water": Color(0.1, 0.25, 0.55),
		"wetland": Color(0.25, 0.5, 0.3),
		"swamp": Color(0.2, 0.38, 0.22),
		"tundra": Color(0.45, 0.5, 0.45),
		"desert": Color(0.75, 0.55, 0.2),
		"rainforest": Color(0.08, 0.3, 0.08),
		"taiga": Color(0.22, 0.32, 0.2),
		"snow": Color(0.88, 0.9, 0.94),
		"plains": Color(0.55, 0.65, 0.15),
		"hills": Color(0.4, 0.55, 0.12),
		"forest": Color(0.2, 0.5, 0.1),
		"mountain": Color(0.5, 0.45, 0.35),
		"peak": Color(0.75, 0.75, 0.8),
		"town": Color(0.65, 0.6, 0.45),
		"dungeon": Color(0.3, 0.25, 0.32),
		"road": Color(0.6, 0.55, 0.4),
		"special": Color(0.25, 0.35, 0.55)
	},
	"秋": {
		"water": Color(0.12, 0.3, 0.5),
		"wetland": Color(0.4, 0.45, 0.25),
		"swamp": Color(0.3, 0.35, 0.2),
		"tundra": Color(0.45, 0.42, 0.4),
		"desert": Color(0.65, 0.5, 0.25),
		"rainforest": Color(0.12, 0.28, 0.08),
		"taiga": Color(0.25, 0.28, 0.2),
		"snow": Color(0.82, 0.85, 0.88),
		"plains": Color(0.6, 0.55, 0.2),
		"hills": Color(0.5, 0.42, 0.15),
		"forest": Color(0.4, 0.35, 0.1),
		"mountain": Color(0.5, 0.42, 0.3),
		"peak": Color(0.65, 0.65, 0.7),
		"town": Color(0.6, 0.52, 0.4),
		"dungeon": Color(0.28, 0.24, 0.3),
		"road": Color(0.58, 0.52, 0.38),
		"special": Color(0.3, 0.28, 0.5)
	},
	"冬": {
		"water": Color(0.1, 0.2, 0.5),
		"wetland": Color(0.3, 0.35, 0.4),
		"swamp": Color(0.25, 0.32, 0.35),
		"tundra": Color(0.5, 0.52, 0.55),
		"desert": Color(0.6, 0.55, 0.4),
		"rainforest": Color(0.08, 0.25, 0.1),
		"taiga": Color(0.2, 0.25, 0.25),
		"snow": Color(0.92, 0.94, 0.96),
		"plains": Color(0.5, 0.5, 0.5),
		"hills": Color(0.4, 0.4, 0.45),
		"forest": Color(0.12, 0.35, 0.2),
		"mountain": Color(0.5, 0.48, 0.45),
		"peak": Color(0.85, 0.88, 0.9),
		"town": Color(0.55, 0.5, 0.42),
		"dungeon": Color(0.22, 0.2, 0.25),
		"road": Color(0.5, 0.45, 0.35),
		"special": Color(0.15, 0.22, 0.45)
	}
}

# ============ 高度颜色映射（用于程序化渲染） ============
# 基础色，低高度 -> 高高度
const HEIGHT_BASE_COLORS: Dictionary = {
	"water": Color(0.1, 0.25, 0.5),
	"wetland": Color(0.3, 0.45, 0.3),
	"swamp": Color(0.25, 0.4, 0.25),
	"tundra": Color(0.4, 0.45, 0.4),
	"desert": Color(0.7, 0.6, 0.3),
	"rainforest": Color(0.1, 0.35, 0.1),
	"taiga": Color(0.2, 0.3, 0.25),
	"snow": Color(0.85, 0.88, 0.92),
	"plains": Color(0.5, 0.6, 0.2),
	"hills": Color(0.4, 0.5, 0.15),
	"forest": Color(0.15, 0.4, 0.12),
	"mountain": Color(0.4, 0.35, 0.3),
	"peak": Color(0.7, 0.7, 0.72),
	"town": Color(0.55, 0.5, 0.4),
	"dungeon": Color(0.2, 0.18, 0.25),
	"road": Color(0.5, 0.45, 0.35),
	"special": Color(0.15, 0.25, 0.45)
}

# ============ 高亮配置 ============
const HIGHLIGHT_COLOR: Color = Color(1.0, 1.0, 0.0, 0.3)
const HIGHLIGHT_BORDER_COLOR: Color = Color(1.0, 1.0, 0.0, 0.8)
const HIGHLIGHT_BORDER_WIDTH: float = 4.0

# ============ 过渡动画配置 ============
const TRANSITION_FADE_IN_DURATION: float = 0.3
const TRANSITION_TEXT_DURATION: float = 0.5
const TRANSITION_FADE_OUT_DURATION: float = 0.3

# ============ 路径配置 ============
const PATH_WIDTH: float = 4.0
const PATH_COLOR: Color = Color(0.55, 0.5, 0.4)

# ============ 公共方法 ============

# 获取指定季节和地形的颜色
static func get_season_terrain_color(season: String, terrain_type: String) -> Color:
	if SEASON_COLORS.has(season) and SEASON_COLORS[season].has(terrain_type):
		return SEASON_COLORS[season][terrain_type]
	if SEASON_COLORS["春"].has(terrain_type):
		return SEASON_COLORS["春"][terrain_type]
	return Color(0.3, 0.3, 0.3)

# 根据地形类型和高度获取颜色
static func get_terrain_color_by_height(terrain_type: String, height: float, season: String = "春") -> Color:
	var base_color = HEIGHT_BASE_COLORS.get(terrain_type, Color(0.3, 0.3, 0.3))
	var season_color = get_season_terrain_color(season, terrain_type)

	# 混合基础色和季节色
	var blended = base_color.lerp(season_color, 0.5)

	# 高海拔更亮，低海拔更暗
	var height_factor = (height - 0.2) / 0.8 if height > 0.2 else 0.0
	blended = blended.lightened(height_factor * 0.3)

	return blended

# 获取所有季节名称
static func get_seasons() -> Array:
	var arr: Array[String] = []
	arr.append("春")
	arr.append("夏")
	arr.append("秋")
	arr.append("冬")
	return arr

# 获取所有地形类型
static func get_terrain_types() -> Array:
	return TERRAIN_TYPES.duplicate()

# 检查是否为水域
static func is_water(terrain_type: String) -> bool:
	return terrain_type == "water"

# 检查是否可通行（NPC/玩家）
static func is_traversable(terrain_type: String) -> bool:
	return terrain_type != "water" and terrain_type != "peak"
