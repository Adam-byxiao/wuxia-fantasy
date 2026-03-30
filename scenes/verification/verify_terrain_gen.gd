# 独立地形生成校验场景
# 使用Ridged噪声创建山脉和河流谷地

extends Node2D

const WIDTH = 320
const HEIGHT = 240
const SCALE = 2

var _terrain: Array = []
var _heights: Array = []
var _rivers: Array = []

# 噪声：基础地形
var _noise_base: FastNoiseLite
# 噪声：山脉（ridged）
var _noise_mountain: FastNoiseLite
# 噪声：河流谷地
var _noise_valley: FastNoiseLite

func _ready() -> void:
	print("=== 地形生成校验开始 ===")
	_init_noise()
	_generate_terrain()
	_print_stats()
	queue_redraw()

func _init_noise() -> void:
	_noise_base = FastNoiseLite.new()
	_noise_base.seed = 20260328
	_noise_base.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise_base.frequency = 0.005

	_noise_mountain = FastNoiseLite.new()
	_noise_mountain.seed = 20260328 + 1
	_noise_mountain.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise_mountain.frequency = 0.008

	_noise_valley = FastNoiseLite.new()
	_noise_valley.seed = 20260328 + 2
	_noise_valley.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise_valley.frequency = 0.015

func _generate_terrain() -> void:
	_terrain.clear()
	_heights.clear()
	_rivers.clear()

	for y in range(HEIGHT):
		for x in range(WIDTH):
			var h = _get_height(x, y)
			var t = _height_to_terrain(h)
			_terrain.append(t)
			_heights.append(h)
			_rivers.append(false)

func _get_height(x: int, y: int) -> float:
	# 1. 基础噪声（宏观地形）
	var base_h = _noise_base.get_noise_2d(x as float, y as float)
	base_h = (base_h + 1.0) / 2.0  # 0-1

	# 2. Ridged噪声（山脉）- 1 - |noise| 产生尖锐山脊
	var mountain = _noise_mountain.get_noise_2d(x as float, y as float)
	mountain = 1.0 - absf(mountain)  # 0-1
	# ridged值域在0-1，但只有接近0的噪声才产生高值
	# 用三次方锐化山脊，降低整体海拔
	mountain = mountain * mountain * mountain
	# 只用0.25权重，不会主导地图
	base_h = base_h * 0.75 + mountain * 0.25

	# 3. 河流谷地（低值区域）
	var valley = _noise_valley.get_noise_2d(x as float, y as float)
	valley = (valley + 1.0) / 2.0  # 0-1
	# 低谷值形成河流
	if valley < 0.3:
		base_h = base_h * 0.15 + valley * 0.15

	return clampf(base_h, 0.0, 1.0)

func _height_to_terrain(h: float) -> String:
	if h < 0.25: return "water"
	if h < 0.32: return "wetland"
	if h < 0.40: return "plains"
	if h < 0.50: return "hills"
	if h < 0.62: return "forest"
	if h < 0.78: return "mountain"
	return "peak"

func _print_stats() -> void:
	var counts: Dictionary = {}
	var min_h: float = 1.0
	var max_h: float = 0.0
	var sum_h: float = 0.0

	for i in range(WIDTH * HEIGHT):
		var t = _terrain[i]
		var h = _heights[i]
		counts[t] = counts.get(t, 0) + 1
		min_h = minf(min_h, h)
		max_h = maxf(max_h, h)
		sum_h += h

	print("=== 地形统计 ===")
	print("高度范围: ", min_h, " - ", max_h)
	print("平均高度: ", sum_h / float(WIDTH * HEIGHT))
	print("各地形数量:")
	for t in counts:
		var pct = float(counts[t]) / float(WIDTH * HEIGHT) * 100.0
		print("  ", t, ": ", counts[t], " (", pct, "%)")

func _draw() -> void:
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var i = y * WIDTH + x
			var t = _terrain[i]
			var h = _heights[i]
			var c = _get_color(t, h)
			draw_rect(Rect2(x * SCALE, y * SCALE, SCALE, SCALE), c, true)

func _get_color(t: String, h: float) -> Color:
	match t:
		"water": return Color(0.05, 0.15, 0.55)      # 深海蓝
		"wetland": return Color(0.15, 0.4, 0.35)    # 湿地青
		"plains": return Color(0.55, 0.65, 0.25)    # 平原黄绿
		"hills": return Color(0.5, 0.45, 0.22)      # 丘陵土黄
		"forest": return Color(0.12, 0.35, 0.12)     # 森林深绿
		"mountain": return Color(0.5, 0.4, 0.32)    # 山地褐
		"peak": return Color(0.7, 0.7, 0.75)         # 山峰灰白
		_: return Color(0.5, 0.5, 0.5)
