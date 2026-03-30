# MVP 世界生成系统 - 实现文档

> 本文档描述 MVP 阶段世界生成系统的实现计划。

---

## 一、现状分析

### 1.1 当前实现
| 组件 | 状态 | 说明 |
|------|------|------|
| WorldGenerator | 已实现 | Kruskal MST 路径生成，5-10 区域 |
| TerrainVisualizer | 基础 | 矩形色块渲染，无 TileMap |
| TerrainTileGenerator | 已实现 | 64x64 瓦片生成 |
| NoiseGenerator | 已实现 | Perlin/Simplex/Worley/FBM |
| NPC 区域移动 | **未实现** | NPC 无法跨区域移动 |

### 1.2 差距
- 无 TileMap 渲染
- 无季节视觉变化
- 无区域过渡效果
- 无难度奖励系统
- NPC 不使用路径网络

---

## 二、目标

MVP 阶段需要实现：
1. **TileMap 渲染** - 真实瓦片贴图，非色块
2. **季节系统** - 四季影响地形色调
3. **区域过渡** - 玩家跨区域有动画+提示
4. **难度奖励** - 区域难度影响战斗奖励
5. **NPC 路径移动** - NPC 沿路径网络移动

---

## 三、系统设计

### 3.1 WorldRenderer（新建）

**文件**: `scripts/world/world_renderer.gd`

**架构**:
- 使用 Godot 4 TileMap 替代 Node2D + _draw
- 双层 TileMap：底层 terrain + 顶层 path
- 从 TextureAtlasGenerator 生成 atlas，创建 TileSet
- 不使用 `class_name`（Autoload 约束）

**季节色调映射**:

| 季节 | 森林 | 山地 | 城镇 | 地牢 | 道路 |
|------|------|------|------|------|------|
| 春 | (0.15,0.45,0.15) | (0.45,0.4,0.35) | (0.6,0.55,0.45) | (0.25,0.22,0.28) | (0.55,0.5,0.4) |
| 夏 | (0.2,0.5,0.1) | (0.5,0.45,0.35) | (0.65,0.6,0.45) | (0.3,0.25,0.32) | (0.6,0.55,0.4) |
| 秋 | (0.4,0.35,0.1) | (0.5,0.42,0.3) | (0.6,0.52,0.4) | (0.28,0.24,0.3) | (0.58,0.52,0.38) |
| 冬 | (0.12,0.35,0.2) | (0.5,0.48,0.45) | (0.55,0.5,0.42) | (0.22,0.2,0.25) | (0.5,0.45,0.35) |

**关键方法**:
```gdscript
initialize(world: WorldData)           # 初始化 TileMap
apply_season_overlay(season: String)   # 应用季节色调
set_highlight(region_id: String)       # 高亮区域
get_region_at_position(pos: Vector2)   # 获取区域
```

### 3.2 SeasonEffectSystem（新建）

**文件**: `scripts/world/season_effect_system.gd`

**职责**:
- 监听 `TimeManager.season_changed`
- 更新 WorldRenderer 季节色调
- 可选：环境光照调整

**信号连接**:
```gdscript
TimeManager.season_changed.connect(_on_season_changed)

func _on_season_changed(season: String):
    world_renderer.apply_season_overlay(season)
```

### 3.3 RegionTransition（新建）

**文件**: `scripts/world/region_transition.gd`

**职责**:
- 监测玩家位置，判断是否跨区域
- 触发过渡动画
- 发射 `SignalBus.region_entered`

**过渡动画时序**:
1. 0.3s 黑色淡入（CanvasModulate 或 ColorRect）
2. 0.5s 显示区域名称（大字居中）
3. 0.3s 淡出

**核心逻辑**:
```gdscript
func _process(delta):
    var player = get_player()
    var new_region = world_renderer.get_region_at_position(player.position)
    if new_region != null and new_region.id != _current_region_id:
        _trigger_transition(new_region)
        SignalBus.region_entered.emit(new_region.id)
```

### 3.4 RegionDifficultyConfig（新建）

**文件**: `scripts/world/region_difficulty_config.gd`

**难度配置**:

| 难度 | 敌人等级倍率 | 推荐境界 | 奖励 exp | 奖励 gold |
|------|-------------|----------|---------|----------|
| 1 | 1.0x | 后天/先天气 | 50 | 20 |
| 2 | 1.5x | 筑基 | 100 | 50 |
| 3 | 2.0x | 金丹+ | 200 | 100 |

**使用方式**:
```gdscript
var rewards = RegionDifficultyConfig.get_rewards(region.difficulty)
BattleManager.apply_rewards(rewards)
```

### 3.5 NPC 路径移动（扩展）

**文件**: `scripts/world/world_generator.gd`（修改）

**新增方法**:
```gdscript
func get_connected_regions(region_id: String) -> Array[String]:
    # 遍历 GameState.world_data.paths
    # 返回与 region_id 直接相连的所有 region_id

func find_path_between(from_id: String, to_id: String) -> Array[String]:
    # BFS 查找最短路径
    # 返回 Array[region_id]
```

**文件**: `scripts/world/npc_agent.gd`（修改）

**改动**:
- NPC 选择目标时，优先选择相邻区域的 POI
- NPC 移动时沿路径网络移动，而非直线

---

## 四、文件清单

### 新建文件

| 文件 | 说明 |
|------|------|
| `scripts/world/world_renderer_config.gd` | 渲染常量、季节色调映射 |
| `scripts/world/world_renderer.gd` | TileMap 渲染器 |
| `scripts/world/season_effect_system.gd` | 季节影响系统 |
| `scripts/world/region_transition.gd` | 区域过渡组件 |
| `scripts/world/region_difficulty_config.gd` | 难度配置 |
| `scenes/world/world_renderer.tscn` | WorldRenderer 场景 |
| `scenes/world/region_transition.tscn` | RegionTransition 场景 |

### 修改文件

| 文件 | 改动 |
|------|------|
| `scripts/world/world_generator.gd` | 添加路径查询方法 |
| `scripts/world/npc_agent.gd` | 添加区域间移动逻辑 |
| `scripts/core/signal_bus.gd` | 确认 `region_entered` 信号存在 |
| `scenes/main.tscn` | 集成 WorldRenderer |

---

## 五、实现顺序

### Phase 1: 基础 TileMap 渲染
1. 创建 `world_renderer_config.gd` - 常量定义
2. 创建 `world_renderer.gd` - TileMap 初始化
3. 创建 `scenes/world/world_renderer.tscn`
4. 验证纹理生成和 TileSet 创建

### Phase 2: 季节系统
5. 创建 `season_effect_system.gd`
6. 在 WorldRenderer 添加季节色调映射
7. 连接 TimeManager.season_changed

### Phase 3: 区域过渡
8. 创建 `region_transition.gd`
9. 实现过渡动画
10. 连接 SignalBus.region_entered

### Phase 4: 难度奖励
11. 创建 `region_difficulty_config.gd`
12. 在 BattleManager 集成奖励计算

### Phase 5: NPC 路径移动
13. WorldGenerator 添加路径查询
14. NPCAgent 区域间移动实现

---

## 六、验证清单

| 测试项 | 验证方法 |
|--------|----------|
| TileMap 渲染 | 观察各地形瓦片颜色是否符合 terrain_type |
| 季节切换 | 等待 30 天或手动设置季节，观察色调变化 |
| 区域过渡 | 玩家移动到不同区域，观察淡入淡出和区域名称 |
| 难度奖励 | 进入不同难度区域战斗，检查奖励是否按倍率变化 |
| NPC 路径移动 | 观察 NPC 是否沿道路连接移动 |
| 现有验证场景 | `verify_world_gen.tscn` 仍然通过 |
| 存档/重放 | 相同 seed 生成相同的 TileMap 布局 |

---

## 七、技术约束

1. **Autoload 脚本禁止 class_name** - WorldRenderer 等组件不使用 class_name
2. **AI 类型用 int** - NPC AI 类型使用 0-5
3. **整数除法** - 使用 `as float`
4. **Godot 4.6** - 使用 FastNoiseLite

---

## 八、依赖关系

```
TimeManager.season_changed
    ↓
SeasonEffectSystem._on_season_changed
    ↓
WorldRenderer.apply_season_overlay
    ↓
TileMap 色调更新

Player移动
    ↓
RegionTransition 检测
    ↓
淡入淡出动画
    ↓
SignalBus.region_entered.emit
    ↓
NPCManager/NPCAgent 更新

BattleManager 结算
    ↓
RegionDifficultyConfig.get_rewards
    ↓
奖励应用
```
