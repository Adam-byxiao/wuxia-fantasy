# 世界渲染美术资源 - 实现与使用文档

> 本文档描述世界渲染模块的程序化美术资产生成器，供其他 agent 调用。

---

## 1. 模块概览

```
assets/
├── textures/                          # 输出纹理目录
│   ├── tile_{terrain}.png            # 各地形瓦片
│   ├── terrain_atlas.png             # 纹理图集
│   └── world_minimap.png             # 世界小地图
├── shaders/
│   └── terrain_noise.gdshader       # 地形噪声着色器
scripts/world/
├── noise_generator.gd                # 噪声生成器
├── terrain_tile_generator.gd         # 瓦片生成器
├── texture_atlas_generator.gd        # 图集打包器
├── procedural_terrain_material.gd    # 材质生成器
├── terrain_visualizer.gd             # 2D 地图可视化
└── world_map_exporter.gd             # 地图导出器
```

---

## 2. 噪声生成器 (NoiseGenerator)

### 2.1 位置
`scripts/world/noise_generator.gd`

### 2.2 类定义
```gdscript
class_name NoiseGenerator
extends RefCounted
```

### 2.3 构造
```gdscript
var noise_gen = NoiseGenerator.new()           # 默认种子 0
var noise_gen = NoiseGenerator.new(12345)       # 指定种子
```

### 2.4 噪声类型 (NoiseType)
| 枚举值 | 说明 |
|--------|------|
| `PERLIN = 0` | Perlin 噪声 |
| `SIMPLEX = 1` | Simplex 噪声（默认） |
| `WORLEY = 2` | Worley/Cellular 噪声 |
| `FBM = 3` | 分形布朗运动（多层叠加） |

### 2.5 地形噪声配置 (TERRAIN_NOISE_CONFIGS)

每种地形有独立的噪声参数：
- `noise_type` - 噪声类型
- `frequency` - 频率
- `amplitude` - 振幅
- `octaves` - 分形层数
- `persistence` - 持续性
- `lacunarity` - 间隙度
- `bias_r/g/b` - 颜色偏移

```gdscript
NoiseGenerator.TERRAIN_NOISE_CONFIGS.keys()
# => ["forest", "mountain", "town", "dungeon", "road", "special"]
```

### 2.6 核心方法

#### get_noise_2d(x, y, config)
获取 2D 噪声值 [0, 1]
```gdscript
var val = noise_gen.get_noise_2d(100.0, 200.0,
    {"noise_type": NoiseGenerator.NoiseType.SIMPLEX,
     "frequency": 0.02, "amplitude": 1.0,
     "octaves": 4, "persistence": 0.5, "lacunarity": 2.0})
# 返回 0.0 ~ 1.0
```

#### generate_terrain_texture(terrain_type, width=512, height=512)
生成程序化地形纹理图像
```gdscript
var img = noise_gen.generate_terrain_texture("forest", 512, 512)
img.save_png("res://assets/textures/forest_tex.png")
```

#### get_terrain_value(world_x, world_y, terrain_type)
获取地形噪声值（用于地形演变）
```gdscript
var n = noise_gen.get_terrain_value(100, 200, "mountain")
```

#### blend_terrains(p, terrain_a, terrain_b, world_x, world_y)
混合两种地形
```gdscript
var result = noise_gen.blend_terrains(0.3, "forest", "mountain", 100, 200)
# result = { "value": 0.x, "primary": "forest", "blend_factor": 0.x }
```

---

## 3. 地形瓦片生成器 (TerrainTileGenerator)

### 3.1 位置
`scripts/world/terrain_tile_generator.gd`

### 3.2 类定义
```gdscript
class_name TerrainTileGenerator
extends Node
```

### 3.3 地形颜色常量 (TERRAIN_COLORS)

| 地形 | base | secondary | accent |
|------|------|-----------|--------|
| forest | 深绿 (0.15,0.45,0.15) | 浅绿 (0.25,0.55,0.2) | 暗绿 (0.1,0.35,0.1) |
| mountain | 岩石灰褐 | 浅岩石 | 深岩石 |
| town | 土墙黄 | 浅黄 | 深土 |
| dungeon | 暗紫灰 | 浅紫灰 | 深渊紫 |
| road | 土路黄褐 | 浅土路 | 深土路 |
| special | 深蓝 | 浅蓝 | 暗蓝 |

### 3.4 核心方法

#### generate_all_tiles(seed_val=0)
批量生成所有地形瓦片
```gdscript
var generator = TerrainTileGenerator.new()
var textures = generator.generate_all_tiles(20260327)
# textures = { "forest": Image, "mountain": Image, ... }
```

#### generate_tile(terrain_type, tile_size=64)
生成单个瓦片
```gdscript
var tile = generator.generate_tile("forest", 64)
tile.save_png("res://assets/textures/tile_forest.png")
```

#### generate_path_texture()
生成路径/道路纹理
```gdscript
var path_tex = generator.generate_path_texture()
```

#### generate_region_texture(terrain_type, region_width=256, region_height=256)
生成大尺寸区域贴图
```gdscript
var region_tex = generator.generate_region_texture("mountain", 256, 256)
```

#### save_tile_as_png(image, terrain_type)
保存瓦片到文件
```gdscript
generator.save_tile_as_png(tile, "forest")  # => res://assets/textures/tile_forest.png
```

---

## 4. 纹理图集生成器 (TextureAtlasGenerator)

### 4.1 位置
`scripts/world/texture_atlas_generator.gd`

### 4.2 类定义
```gdscript
class_name TextureAtlasGenerator
extends RefCounted
```

### 4.3 图集布局

- 图集大小: 512x512
- 瓦片大小: 64x64
- 每行瓦片数: 8

| 索引 | 地形 |
|------|------|
| 0 | forest |
| 1 | mountain |
| 2 | town |
| 3 | dungeon |
| 4 | road |
| 5 | special |

### 4.4 核心方法

#### generate_atlas(tile_generator, seed_val=0)
生成纹理图集
```gdscript
var tile_gen = TerrainTileGenerator.new()
var atlas = TextureAtlasGenerator.generate_atlas(tile_gen, 12345)
TextureAtlasGenerator.save_atlas(atlas, "res://assets/textures/terrain_atlas.png")
```

#### get_tile_from_atlas(atlas, tile_index)
从图集提取单个瓦片
```gdscript
var atlas_img = Image.new()
atlas_img.load("res://assets/textures/terrain_atlas.png")
var forest_tile = TextureAtlasGenerator.get_tile_from_atlas(atlas_img, 0)
```

#### get_tile_index(terrain_type)
获取地形对应的图集索引
```gdscript
var idx = TextureAtlasGenerator.get_tile_index("mountain")  # => 1
```

#### generate_blend_atlas(tile_generator, seed_val=0)
生成带 alpha 的混合图集（用于地形过渡）
```gdscript
var blend_atlas = TextureAtlasGenerator.generate_blend_atlas(tile_gen, 12345)
```

---

## 5. 程序化材质 (ProceduralTerrainMaterial)

### 5.1 位置
`scripts/world/procedural_terrain_material.gd`

### 5.2 类定义
```gdscript
class_name ProceduralTerrainMaterial
extends Resource
```

### 5.3 核心方法

#### from_terrain_type(terrain_type)
从地形类型创建材质
```gdscript
var mat = ProceduralTerrainMaterial.from_terrain_type("forest")
```

#### blend(mat_a, mat_b, t)
混合两种材质
```gdscript
var mat_a = ProceduralTerrainMaterial.from_terrain_type("forest")
var mat_b = ProceduralTerrainMaterial.from_terrain_type("mountain")
var blended = ProceduralTerrainMaterial.blend(mat_a, mat_b, 0.5)  # t=0.5 等量混合
```

#### to_material_3d()
转换为 Godot StandardMaterial3D
```gdscript
var mat_3d = mat.to_material_3d()
```

#### get_color_at_uv(uv, noise_gen)
获取 UV 位置的颜色
```gdscript
var color = mat.get_color_at_uv(Vector2(0.5, 0.5), noise_gen)
```

---

## 6. 地形可视化器 (TerrainVisualizer)

### 6.1 位置
`scripts/world/terrain_visualizer.gd`

### 6.2 场景
`scenes/world/terrain_visualizer.tscn`

### 6.3 节点类型
```gdscript
class_name TerrainVisualizer
extends Node2D
```

### 6.4 导出属性
| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `cell_size` | int | 32 | 区域像素大小 |
| `show_grid` | bool | false | 显示网格 |
| `show_paths` | bool | true | 显示路径 |
| `show_landmarks` | bool | true | 显示地标 |
| `highlight_region_id` | String | "" | 高亮区域ID |

### 6.5 信号
```gdscript
region_clicked(region_id: String)      # 区域被点击
region_hovered(region_id: String)       # 区域悬停
```

### 6.6 核心方法

#### initialize(world: WorldData)
初始化可视化
```gdscript
var world = WorldGenerator.generate(20260327)
$TerrainVisualizer.initialize(world)
```

#### get_region_at_position(pos: Vector2) -> RegionData
获取点击位置的区域
```gdscript
func _on_terrain_visualizer_region_clicked(region_id):
    print("Clicked: ", region_id)
```

#### set_highlight(region_id: String)
高亮指定区域
```gdscript
$TerrainVisualizer.set_highlight("region_forest_xxx")
```

#### clear_highlight()
清除高亮
```gdscript
$TerrainVisualizer.clear_highlight()
```

#### export_region_texture(region, size=128) -> Image
导出区域纹理
```gdscript
var region_tex = $TerrainVisualizer.export_region_texture(region, 128)
```

#### get_terrain_details_at(world_x, world_y) -> Dictionary
获取地形详情
```gdscript
var details = $TerrainVisualizer.get_terrain_details_at(100, 200)
# details = {
#   "terrain_type": "forest",
#   "region_id": "xxx",
#   "noise_value": 0.x,
#   "color": Color,
#   "difficulty": 1-3,
#   "name": "翠林岗",
#   "landmark": "古庙遗址"
# }
```

---

## 7. 世界地图导出器 (WorldMapExporter)

### 7.1 位置
`scripts/world/world_map_exporter.gd`

### 7.2 类定义
```gdscript
class_name WorldMapExporter
extends Node
```

### 7.3 核心方法

#### export_world_map(world, world_width=256, world_height=256) -> Image
导出完整世界地图
```gdscript
var exporter = WorldMapExporter.new()
var world_map = exporter.export_world_map(world, 512, 256)
world_map.save_png("res://assets/textures/world_map.png")
```

#### save_world_map(world, path, width=512, height=256) -> bool
保存世界地图到文件
```gdscript
exporter.save_world_map(world, "res://assets/textures/world_map.png", 512, 256)
```

#### generate_thumbnail(world, size=128) -> Image
生成缩略图
```gdscript
var thumb = exporter.generate_thumbnail(world, 128)
```

---

## 8. Shader (terrain_noise.gdshader)

### 8.1 位置
`assets/shaders/terrain_noise.gdshader`

### 8.2 Uniforms
| Uniform | 类型 | 默认值 | 说明 |
|---------|------|--------|------|
| `time` | float | 0.0 | 时间（动画用） |
| `noise_scale` | float | 0.02 | 噪声缩放 |
| `terrain_color_base` | vec3 | (0.3,0.5,0.2) | 基础色 |
| `terrain_color_high` | vec3 | (0.5,0.7,0.3) | 高位色 |
| `terrain_color_low` | vec3 | (0.15,0.25,0.1) | 低位色 |
| `height_scale` | float | 0.5 | 高度缩放 |
| `noise_octaves` | int | 4 | 噪声倍频数 |
| `noise_persistence` | float | 0.5 | 持续性 |
| `noise_lacunarity` | float | 2.0 | 间隙度 |

### 8.3 使用方式
```gdscript
var shader_material = load("res://assets/shaders/terrain_noise.gdshader")
$Sprite2D.material = shader_material
```

---

## 9. 验证场景 (verify_textures.gd)

### 9.1 位置
`scenes/verification/verify_textures.gd`

### 9.2 使用
```gdscript
# 在场景中添加节点
var verifier = preload("res://scenes/verification/verify_textures.gd").new()
add_child(verifier)
verifier.generate_all_textures()
```

### 9.3 验证内容
- 噪声生成
- 材质生成
- 纹理生成
- 世界地图导出

---

## 10. 使用示例

### 10.1 生成世界纹理资源
```gdscript
# 创建生成器
var tile_gen = TerrainTileGenerator.new()
var noise_gen = NoiseGenerator.new(20260327)
tile_gen._noise_gen = noise_gen

# 生成所有瓦片
var textures = tile_gen.generate_all_tiles(20260327)

# 生成图集
var atlas = TextureAtlasGenerator.generate_atlas(tile_gen, 20260327)
TextureAtlasGenerator.save_atlas(atlas, "res://assets/textures/terrain_atlas.png")

# 生成世界地图
var world = WorldGenerator.generate(20260327)
var exporter = WorldMapExporter.new()
exporter.save_world_map(world, "res://assets/textures/world_map.png")
```

### 10.2 在场景中渲染世界地图
```gdscript
# 在场景中加载可视化器
var viz_scene = preload("res://scenes/world/terrain_visualizer.tscn")
var viz = viz_scene.instantiate()
add_child(viz)

# 初始化
var world = WorldGenerator.generate(seed)
viz.initialize(world)

# 连接信号
viz.region_clicked.connect(_on_region_clicked)

func _on_region_clicked(region_id):
    print("Clicked region: ", region_id)
```

### 10.3 动态地形演变
```gdscript
var noise_gen = NoiseGenerator.new()

# 获取地形值
var terrain_val = noise_gen.get_terrain_value(world_x, world_y, "forest")

# 混合地形
var blended = noise_gen.blend_terrains(0.5, "forest", "mountain", world_x, world_y)

# 使用材质
var mat = ProceduralTerrainMaterial.blend(
    ProceduralTerrainMaterial.from_terrain_type("forest"),
    ProceduralTerrainMaterial.from_terrain_type("mountain"),
    blended["blend_factor"]
)
```

---

## 11. 注意事项

1. **Autoload 约束**: `TerrainTileGenerator` 是 Node 类型，不是 Autoload，可正常继承 `class_name`
2. **噪声种子**: 相同种子生成相同纹理，用于存档/重放
3. **纹理尺寸**: 默认 64x64 瓦片，512x512 图集，可按需调整
4. **Godot 版本**: 使用 Godot 4.6 的 `FastNoiseLite`
5. **输出目录**: 纹理默认保存到 `res://assets/textures/`，需确保目录存在
