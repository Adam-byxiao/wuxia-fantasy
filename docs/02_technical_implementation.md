# 武侠沙盒 - 技术实现文档

> 本文档记录技术验证阶段（Phase 1 MVP）的所有核心模块实现细节。

---

## 1. 项目架构

### 1.1 Autoload 清单

| 名称 | 脚本路径 | 职责 |
|------|----------|------|
| SignalBus | `scripts/core/signal_bus.gd` | 全局事件总线，所有模块通过信号通信 |
| GameState | `scripts/core/game_state.gd` | 全局状态容器 |
| TimeManager | `scripts/world/time_manager.gd` | 游戏时间驱动 |
| NPCManager | `scripts/world/npc_manager.gd` | NPC 注册/生成/查询 |
| WorldGenerator | `scripts/world/world_generator.gd` | 区域生成 + 路径网络 |
| EventManager | `scripts/world/event_manager.gd` | 世界事件管理 |
| CultivationSystem | `scripts/cultivation/cultivation_system.gd` | 经验/等级/境界 |

### 1.2 SignalBus 信号列表

```
战斗系统 → 事件
  battle_started
  battle_ended(victory: bool, rewards: Dictionary)
  exp_gained(amount: int)
  item_acquired(item_id: String, quantity: int)

世界系统 → 战斗/养成
  world_generated(world)
  region_entered(region_id: String)
  world_time_passed(days: int)

养成系统 → 战斗
  level_up(new_level: int)
  realm_broken(new_realm: String)
  skill_learned(skill_id: String)
  skill_equipped(skill_id: String)

沙盒系统
  world_event_triggered(event_id: String, event_name: String)
  sandbox_npc_tick(day: int)

UI请求
  npc_interaction_requested(npc)
  inventory_requested()
  skills_requested()
  dialog_requested(dialogue_data)

存档系统
  game_saved()
  game_loaded()
```

### 1.3 重要设计约束

- **class_name 与 Autoload 互斥**：Autoload 脚本禁止使用 `class_name`，否则报 "Class X hides an autoload singleton" 错误。
- **enum 跨文件类型限制**：GDScript 不支持将 enum 值用作跨文件的类型注解。AI 类型在所有文件中均使用 `int`（0-5），以字面量 match。
- **Integer Division**：`int / int` 会产生警告，需使用 `current_day as float / DAYS_PER_SEASON`。

---

## 2. 世界生成模块（WorldGen）

### 2.1 文件结构

- `scripts/world/world_generator.gd` — 主生成器（Autoload）
- `scripts/world/region_generator.gd` — 单个区域生成器
- `scripts/world/terrain_config.gd` — 地形配置（名称/地标词库）
- `scripts/world/region_data.gd` — 区域数据结构（class_name Resource）
- `scripts/world/world_data.gd` — 世界数据结构（class_name Resource）

### 2.2 生成算法

**输入**：`seed: int`

**步骤**：
1. 用 seed 初始化 `RandomNumberGenerator`
2. 在 8x6 网格上随机放置 5-10 个区域
3. 调用 `RegionGenerator` 为每个区域生成武侠风格名称 + 地标
4. **Kruskal MST**：将所有区域按距离排序，贪心合并不相交的集合，生成 N-1 条最小生成树路径
5. **额外路径**：再添加 1-2 条随机路径（增强连通性）
6. 组装 `WorldData`，存入 `GameState.world_data`，发射 `SignalBus.world_generated`

**输出**：`WorldData { seed, regions: Array[RegionData], paths: Array[Dictionary] }`

### 2.3 区域数据结构 `RegionData`

```
id: String           # 唯一标识 "region_forest_xxx"
name: String         # 武侠风格名称，如 "翠林岗"
tile_x, tile_y: int  # 左上角瓦片坐标
tile_w, tile_h: int  # 区域尺寸（默认32x32）
terrain_type: String # forest | mountain | town | dungeon | road | special
difficulty: int      # 1-3（影响敌人强度）
npc_spawn_count: int # 区域内NPC数量
landmark: String     # 地标描述，如 "古庙遗址"
```

### 2.4 路径数据结构

```gdscript
{"from": region_id, "to": region_id, "cost": float}
```

### 2.5 确定性保证

相同 `seed` 必生成相同的区域数量、名称列表、路径网络。可用于存档/重放。

---

## 3. 时间系统（WorldSim - Time）

### 3.1 文件

- `scripts/world/time_manager.gd`（Autoload）

### 3.2 常量

```gdscript
const SEASONS = ["春", "夏", "秋", "冬"]
const DAYS_PER_SEASON = 30
```

### 3.3 核心逻辑

**实时推进**（`_process`）：
- `time_scale` 控制加速倍率（1.0=正常，0=暂停）
- 累积 delta × time_scale，每达 `_realtime_per_day`（10秒）触发一次 `advance_day()`

**日推进**（`advance_day`）：
```
current_day += 1
GameState.current_day = current_day
day_passed.emit(current_day)

new_season = SEASONS[int(current_day as float / DAYS_PER_SEASON) % 4]
if new_season != current_season:
    current_season = new_season
    season_changed.emit(current_season)
```

**季节循环**：春→夏→秋→冬→春，每30天换季。

---

## 4. 战斗系统（BattleSys）

### 4.1 文件结构

- `scripts/combat/battle_manager.gd` — 战斗状态机（Autoload `class_name BattleManager`）
- `scripts/combat/combat_unit.gd` — 战斗单位数据（class_name RefCounted）
- `scripts/combat/skill.gd` — 技能定义
- `scripts/combat/enemy_ai.gd` — 敌方AI
- `scripts/combat/enemy_templates.gd` — 敌人模板

### 4.2 战斗状态机

```gdscript
enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, ANIMATING, ENDED }
```

**流程**：
1. `start_battle(player_unit, enemy_units)` → `PLAYER_TURN`
2. 玩家执行 `execute_player_attack()` 或 `execute_player_action(skill_index, target)`
3. 检查是否所有敌人死亡 → `ENDED`
4. 否则进入 `ENEMY_TURN`：所有存活敌人依次攻击玩家
5. 检查玩家是否死亡 → `ENDED`
6. 否则回到 `PLAYER_TURN`

### 4.3 伤害公式

```gdscript
func take_damage(dmg: int) -> int:
    var actual = max(1, dmg - defense)  # 最低伤害为1
    current_health = max(0, current_health - actual)
    if current_health <= 0:
        is_alive = false
    return actual
```

### 4.4 逃跑机制

```gdscript
func try_escape() -> bool:
    var rng = RandomNumberGenerator.new()
    return rng.randf() < 0.5  # 50%成功率
```

### 4.5 奖励

战斗胜利时发放：`{ "exp": enemies.size() * 50, "gold": enemies.size() * 20 }`

---

## 5. 养成系统（Cultivation）

### 5.1 文件结构

- `scripts/cultivation/cultivation_system.gd`（Autoload）
- `scripts/cultivation/cultivation_data.gd`（class_name Resource）
- `scripts/cultivation/realm_config.gd` — 境界配置
- `scripts/cultivation/skill_learn_config.gd` — 技能学习配置

### 5.2 经验公式

```gdscript
Lv.2 需要: 100
Lv.3 需要: 150
Lv.4 需要: 225
...
公式: exp_to_next = int(100 * pow(1.5, lv - 1))
```

### 5.3 境界列表

```
后天 → 先天气 → 筑基 → 金丹 → 元婴 → 化神 → 渡劫 → 大乘 → 飞升
```

### 5.4 属性系统

```gdscript
attributes = {
    "strength": 5,      # 力道 - 影响攻击力
    "agility": 5,        # 身法 - 影响速度/闪避
    "constitution": 5,  # 体质 - 影响生命上限
    "qi_capacity": 5,   # 气量 - 影响内力上限
    "wisdom": 5         # 悟性 - 影响技能学习效率
}
```

### 5.5 战斗属性计算

```gdscript
get_combat_stats() -> Dictionary:
    max_health = 100 + constitution * 20
    max_qi = 50 + qi_capacity * 10
    attack = 10 + strength * 3
    defense = 5 + constitution * 2
    speed = 8 + agility * 2
    crit_rate = 0.05 + wisdom * 0.01
    crit_damage = 1.5
```

### 5.6 信号连接

`CultivationSystem` 监听 `SignalBus.battle_ended`，胜利后自动调用 `add_exp(rewards["exp"])`。

---

## 6. NPC AI 系统

### 6.1 文件结构

- `scripts/world/npc_brain.gd` — 目标评估脑（class_name）
- `scripts/world/npc_agent.gd` — NPC 实体（class_name）
- `scripts/world/npc_manager.gd`（Autoload）
- `scripts/world/npc_ai_types.gd` — 性格预设
- `scripts/world/npc_action_selector.gd` — 行为选择器
- `scripts/world/npc_sandbox_controller.gd` — 沙盒 tick 控制器

### 6.2 AI 类型枚举（使用 int，0-5）

| ID | 名称 | 默认目标 | 性格倾向 |
|----|------|----------|----------|
| 0 | PATROL | wander | 巡逻守卫，低攻击性 |
| 1 | TRADER | trade | 商人，高社交性 |
| 2 | CULTIVATOR | cultivate | 修士，低社交高悟性 |
| 3 | WANDERER | wander | 游侠，高好奇心 |
| 4 | GUARD | survive | 守卫，高攻击性 |
| 5 | QUEST | quest | 任务型 |

### 6.3 目标权重系统

```gdscript
goal_weights: Dictionary = {
    "survive": 0,     # 平时0，受威胁时+20
    "trade": 3,
    "cultivate": 2,
    "socialize": 2,
    "wander": 3,
    "quest": 4,
}
```

**类型加成**：
- TRADER(1) → trade +15
- CULTIVATOR(2) → cultivate +10
- WANDERER(3) → wander +5
- PATROL(0) → wander +3
- QUEST(5) → quest +5
- GUARD(4) 初始 survive=20（默认不激活）

### 6.4 沙盒 Tick 流程

```
SignalBus.sandbox_npc_tick.emit(day)
  → NPCAgent._on_sandbox_tick(day)
      → brain.evaluate_current_goal()
      → NPCActionSelector.select_action(brain, world_state)
      → _execute_action(action)
```

### 6.5 记忆系统

```gdscript
memory: Dictionary = {
    "last_seen_player": null,
    "player_interactions": 0,
    "fought_with": [],
    "trade_with": [],
    "trust_level": 0,
}
```

---

## 7. 数据流图

```
[WorldGenerator.generate(seed)]
       ↓
   WorldData → GameState.world_data
       ↓
SignalBus.world_generated.emit()
       ↓
  [NPCManager] [Main scene] [UI]

[TimeManager._process] (real-time)
       ↓
  advance_day()
       ↓
SignalBus.day_passed.emit()
SignalBus.season_changed.emit()
SignalBus.sandbox_npc_tick.emit(day)
       ↓
[NPCAgent._on_sandbox_tick] ← 每个NPC独立评估+行动

[BattleManager.start_battle]
       ↓
  回合循环: PLAYER_TURN ↔ ENEMY_TURN
       ↓
  battle_ended.emit(victory, rewards)
       ↓
[CultivationSystem._on_battle_ended]
       ↓
  add_exp() → level_up() / realm_broken()
       ↓
SignalBus.exp_gained.emit()
SignalBus.level_up.emit()
SignalBus.realm_broken.emit()
```

---

## 8. 验证场景清单

| 场景 | 文件 | 验证内容 |
|------|------|----------|
| 世界生成 | `verify_world_gen.tscn/.gd` | 区域数量/名称/路径/MST/确定性 |
| 时间系统 | `verify_time.tscn/.gd` | 日计数/季节切换/加速暂停 |
| 战斗系统 | `verify_battle.tscn/.gd` | 伤害公式/技能/逃跑/结算 |
| 养成系统 | `verify_cultivation.tscn/.gd` | 经验/等级/属性/境界突破 |
| NPC AI | `verify_npc.tscn/.gd` | 4种AI类型/目标选择/ sandbox tick |

所有验证场景可通过主菜单 `test_menu.tscn` 进入。

---

## 9. 已修复的关键问题记录

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| `class_name X hides an autoload` | Autoload 脚本上不能有 `class_name` | 移除 TimeManager/EventManager/NPCManager/WorldGenerator/CultivationSystem 的 `class_name` |
| `Integer division` 警告 | `current_day / DAYS_PER_SEASON`（两 int） | 改为 `current_day as float / DAYS_PER_SEASON` |
| `ui_f5` action 不存在 | Godot 4 无内置 ui_f5-8 | 移除 TimeManager._input 中的 F-Key 引用 |
| NPCBrain.AIType 作为类型注解报错 | enum 值跨文件作类型注解不支持 | 所有文件改用 `int`，match 用字面量 0-5 |
| 额外 `)` 语法错误 | npc_agent.gd line 78 多一个 `)` | `))))` → `))` |
| 编码导致解析失败 | battle_manager.gd 有无效 UTF-8 字节 | 重写文件，使用纯 ASCII 消息字符串 |
| NPC AI 目标权重 bug | survive=10 导致所有类型都选生存 | survive 基础权重改为 0，类型加成仅在 GUARD 初始时设为 20 |

---

## 10. 文件清单（技术验证阶段）

```
scripts/
├── core/
│   ├── signal_bus.gd        # 全局事件总线
│   └── game_state.gd        # 全局状态
├── world/
│   ├── time_manager.gd      # 时间驱动 (Autoload)
│   ├── world_generator.gd    # 世界生成 (Autoload)
│   ├── npc_manager.gd        # NPC管理 (Autoload)
│   ├── event_manager.gd      # 事件管理 (Autoload)
│   ├── npc_brain.gd          # NPC目标评估
│   ├── npc_agent.gd         # NPC实体
│   ├── npc_ai_types.gd       # AI性格预设
│   ├── npc_action_selector.gd # 行为选择
│   ├── npc_sandbox_controller.gd
│   ├── world_data.gd         # 世界数据类
│   ├── region_data.gd        # 区域数据类
│   ├── region_generator.gd   # 区域生成器
│   ├── terrain_config.gd     # 地形配置
│   └── world_consistency.gd  # 一致性检查
├── combat/
│   ├── battle_manager.gd     # 战斗状态机 (Autoload)
│   ├── combat_unit.gd        # 战斗单位数据
│   ├── skill.gd              # 技能定义
│   ├── enemy_ai.gd           # 敌方AI
│   └── enemy_templates.gd    # 敌人模板
├── cultivation/
│   ├── cultivation_system.gd # 养成系统 (Autoload)
│   ├── cultivation_data.gd   # 养成数据类
│   ├── realm_config.gd       # 境界配置
│   └── skill_learn_config.gd # 技能学习配置
└── player/
    ├── player.gd             # 玩家实体
    ├── player_controller.gd  # 玩家控制器
    └── player_data.gd        # 玩家数据

scenes/
├── main.tscn / main.gd       # 综合沙盒主场景
├── menu/
│   └── test_menu.tscn/.gd   # 主菜单
└── verification/
    ├── verify_world_gen.tscn/.gd
    ├── verify_time.tscn/.gd
    ├── verify_battle.tscn/.gd
    ├── verify_cultivation.tscn/.gd
    └── verify_npc.tscn/.gd

docs/
├── 01_game_design_document.md   # 游戏设计文档
├── 02_technical_implementation.md # 本文档
└── verification_guide.md        # 验证指南
```
