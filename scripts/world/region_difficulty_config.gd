# 区域难度配置
# 定义不同难度区域的敌人强度和奖励倍率

extends Node

# ============ 难度等级定义 ============
enum Difficulty {
	EASY = 1,
	MEDIUM = 2,
	HARD = 3
}

# ============ 难度配置 ============
const DIFFICULTY_CONFIG: Dictionary = {
	1: {
		"name": "简单",
		"enemy_level_multiplier": 1.0,
		"recommended_realm": "后天/先天气",
		"rewards": {
			"exp": 50,
			"gold": 20
		},
		"enemy_spawn_rate": 0.3,
		"treasure_chance": 0.1
	},
	2: {
		"name": "中等",
		"enemy_level_multiplier": 1.5,
		"recommended_realm": "筑基",
		"rewards": {
			"exp": 100,
			"gold": 50
		},
		"enemy_spawn_rate": 0.5,
		"treasure_chance": 0.2
	},
	3: {
		"name": "困难",
		"enemy_level_multiplier": 2.0,
		"recommended_realm": "金丹+",
		"rewards": {
			"exp": 200,
			"gold": 100
		},
		"enemy_spawn_rate": 0.7,
		"treasure_chance": 0.35
	}
}

# ============ 地形难度加成 ============
const TERRAIN_DIFFICULTY_BONUS: Dictionary = {
	"forest": 0,      # 森林：标准难度
	"mountain": 1,     # 山脉：+1 难度
	"town": -1,       # 城镇：-1 难度（更安全）
	"dungeon": 2,      # 地城：+2 难度
	"road": 0,         # 道路：标准难度
	"special": 1       # 特殊：+1 难度
}

# ============ 公共方法 ============

# 获取难度配置
static func get_config(difficulty: int) -> Dictionary:
	return DIFFICULTY_CONFIG.get(difficulty, DIFFICULTY_CONFIG[1])

# 获取奖励
static func get_rewards(difficulty: int) -> Dictionary:
	var config = get_config(difficulty)
	return config["rewards"].duplicate()

# 获取敌人等级倍率
static func get_enemy_multiplier(difficulty: int) -> float:
	var config = get_config(difficulty)
	return config["enemy_level_multiplier"]

# 计算实际难度（考虑地形）
static func calculate_effective_difficulty(base_difficulty: int, terrain_type: String) -> int:
	var bonus = TERRAIN_DIFFICULTY_BONUS.get(terrain_type, 0)
	var effective = base_difficulty + bonus
	return clampi(effective, 1, 3)

# 获取难度名称
static func get_difficulty_name(difficulty: int) -> String:
	var config = get_config(difficulty)
	return config["name"]

# 获取推荐境界
static func get_recommended_realm(difficulty: int) -> String:
	var config = get_config(difficulty)
	return config["recommended_realm"]

# 获取敌人生成率
static func get_enemy_spawn_rate(difficulty: int) -> float:
	var config = get_config(difficulty)
	return config["enemy_spawn_rate"]

# 获取宝藏几率
static func get_treasure_chance(difficulty: int) -> float:
	var config = get_config(difficulty)
	return config["treasure_chance"]

# 获取区域探索奖励
static func get_exploration_bonus(region: RegionData) -> Dictionary:
	var difficulty = region.difficulty
	var terrain = region.terrain_type
	var effective_diff = calculate_effective_difficulty(difficulty, terrain)

	var base_rewards = get_rewards(effective_diff)

	# 地城额外奖励
	if terrain == "dungeon":
		base_rewards["exp"] = int(base_rewards["exp"] * 1.5)
		base_rewards["gold"] = int(base_rewards["gold"] * 1.3)

	# 特殊区域额外奖励
	if terrain == "special":
		base_rewards["exp"] = int(base_rewards["exp"] * 1.2)
		base_rewards["gold"] = int(base_rewards["gold"] * 1.5)

	return base_rewards
