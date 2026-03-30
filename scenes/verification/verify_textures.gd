# 纹理生成验证脚本
# 验证并生成所有地形纹理资源

extends Node

@export var generate_at_start: bool = true
@export var output_path: String = "res://assets/textures/"

var _tile_generator: TerrainTileGenerator
var _noise_gen: NoiseGenerator
var _atlas_generator: TextureAtlasGenerator

func _ready() -> void:
	_tile_generator = TerrainTileGenerator.new()
	_noise_gen = NoiseGenerator.new()
	_atlas_generator = TextureAtlasGenerator.new()

	_tile_generator._noise_gen = _noise_gen

	if generate_at_start:
		generate_all_textures()

# 生成所有纹理
func generate_all_textures() -> void:
	print("=== 开始生成地形纹理 ===")

	# 生成单个瓦片纹理
	var tiles = _tile_generator.generate_all_tiles(20260327)
	print("生成了 ", tiles.size(), " 种地形瓦片")

	# 生成纹理图集
	var atlas = TextureAtlasGenerator.generate_atlas(_tile_generator, 20260327)
	var atlas_path = output_path + "terrain_atlas.png"
	var success = TextureAtlasGenerator.save_atlas(atlas, atlas_path)
	if success:
		print("纹理图集已保存")

	# 生成混合图集
	var blend_atlas = TextureAtlasGenerator.generate_blend_atlas(_tile_generator, 20260327)
	var blend_path = output_path + "terrain_blend_atlas.png"
	var blend_img = Image.new()
	blend_img = blend_atlas
	blend_img.save_png(blend_path)
	print("混合图集已保存")

	# 生成各区域预览
	_generate_region_previews()

	print("=== 纹理生成完成 ===")

# 生成区域预览
func _generate_region_previews() -> void:
	# 创建测试世界
	var world_gen = WorldGenerator.new()
	var world = world_gen.generate(20260327)

	var exporter = WorldMapExporter.new()

	# 生成小地图
	var mini_map = exporter.generate_thumbnail(world, 256)
	mini_map.save_png(output_path + "world_minimap.png")
	print("世界小地图已保存")

	# 生成完整地图
	var full_map = exporter.export_world_map(world, 512, 256)
	full_map.save_png(output_path + "world_fullmap.png")
	print("世界完整地图已保存")

# 验证噪声生成
func verify_noise() -> void:
	print("=== 验证噪声生成 ===")

	var noise = NoiseGenerator.new(12345)

	# 测试各类型噪声
	var configs = NoiseGenerator.TERRAIN_NOISE_CONFIGS
	for terrain in configs:
		var val = noise.get_noise_2d(100.0, 100.0, configs[terrain])
		print(terrain, " 噪声值: ", val)

	print("噪声验证完成")

# 验证材质生成
func verify_materials() -> void:
	print("=== 验证材质生成 ===")

	var mat_forest = ProceduralTerrainMaterial.from_terrain_type("forest")
	print("森林材质 - base: ", mat_forest.base_color)

	var mat_mountain = ProceduralTerrainMaterial.from_terrain_type("mountain")
	print("山脉材质 - base: ", mat_mountain.base_color)

	# 测试材质混合
	var blended = ProceduralTerrainMaterial.blend(mat_forest, mat_mountain, 0.5)
	print("混合材质 - base: ", blended.base_color)

	print("材质验证完成")
