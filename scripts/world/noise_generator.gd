class_name NoiseGenerator
extends RefCounted

var noise: FastNoiseLite
var seed_value: int

enum NoiseType {
	PERLIN = 0,
	SIMPLEX = 1,
	WORLEY = 2,
	FBM = 3
}

const MULTI_SCALE_CONFIG: Dictionary = {
	"macro": {"frequency": 0.008, "octaves": 4, "persistence": 0.6, "lacunarity": 2.0, "weight": 0.4},
	"mid": {"frequency": 0.02, "octaves": 4, "persistence": 0.5, "lacunarity": 2.0, "weight": 0.35},
	"micro": {"frequency": 0.05, "octaves": 3, "persistence": 0.5, "lacunarity": 2.0, "weight": 0.25}
}

func _init(p_seed: int = 0) -> void:
	seed_value = p_seed
	noise = FastNoiseLite.new()
	noise.seed = seed_value

func _get_noise_type(nt: NoiseType) -> int:
	match nt:
		NoiseType.PERLIN: return FastNoiseLite.TYPE_PERLIN
		NoiseType.SIMPLEX: return FastNoiseLite.TYPE_SIMPLEX
		NoiseType.WORLEY: return FastNoiseLite.TYPE_CELLULAR
		_: return FastNoiseLite.TYPE_SIMPLEX

func _fbm(x: float, y: float, amp: float, octaves: int, persist: float, lac: float) -> float:
	var total: float = 0.0
	var freq: float = 1.0
	var amp_cur: float = amp
	var max_val: float = 0.0
	for i in range(octaves):
		total += noise.get_noise_2d(x * freq, y * freq) * amp_cur
		max_val += amp_cur
		amp_cur *= persist
		freq *= lac
	return (total / max_val + 1.0) / 2.0

func get_noise_2d(x: float, y: float, freq: float, octaves: int, persist: float, lac: float) -> float:
	noise.frequency = freq
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	return _fbm(x, y, 1.0, octaves, persist, lac)

func get_height(world_x: int, world_y: int) -> float:
	var h: float = 0.0
	var weight_sum: float = 0.0
	for key in MULTI_SCALE_CONFIG:
		var cfg = MULTI_SCALE_CONFIG[key]
		var freq = cfg["frequency"]
		var oct = cfg["octaves"]
		var pers = cfg["persistence"]
		var lac = cfg["lacunarity"]
		var w = cfg["weight"]
		var v = get_noise_2d(world_x as float, world_y as float, freq, oct, pers, lac)
		h += v * w
		weight_sum += w
	return clampf(h / weight_sum, 0.0, 1.0)

func get_terrain(world_x: int, world_y: int) -> Dictionary:
	var h = get_height(world_x, world_y)
	var t = _height_to_terrain(h)
	return {"height": h, "terrain": t}

func _height_to_terrain(h: float) -> String:
	if h < 0.25: return "water"
	if h < 0.32: return "wetland"
	if h < 0.42: return "plains"
	if h < 0.52: return "hills"
	if h < 0.65: return "forest"
	if h < 0.8: return "mountain"
	return "peak"
