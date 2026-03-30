class_name TerrainConfig
extends Resource

@export var terrain_weights: Dictionary = {
    "forest": 30,
    "mountain": 25,
    "town": 20,
    "dungeon": 15,
    "special": 10
}

@export var terrain_names: Dictionary = {
    "forest": ["林", "岗", "谷", "寨"],
    "mountain": ["峰", "岭", "崖", "寨"],
    "town": ["镇", "城", "集", "铺"],
    "dungeon": ["洞", "窟", "墓", "府"],
    "road": ["道", "路", "径"],
    "special": ["渊", "潭", "崖", "顶"]
}

@export var terrain_landmarks: Dictionary = {
    "forest": ["古庙遗址", "山洞入口", "溪流源头", "废弃营地"],
    "mountain": ["古栈道", "悬崖吊桥", "飞来峰", "古塔遗迹"],
    "town": ["醉仙楼", "万宝阁", "武馆", "客栈"],
    "dungeon": ["秘室", "古墓入口", "妖兽巢穴", "藏宝洞"],
    "road": ["茶摊", "凉亭", "岔路口", "驿站"],
    "special": ["瀑布后洞", "深渊入口", "密林空地", "古战场"]
}

func pick_random_terrain(rng: RandomNumberGenerator) -> String:
    var total = 0
    for v in terrain_weights.values():
        total += v
    var roll = rng.randi() % total
    var current = 0
    for t in terrain_weights:
        current += terrain_weights[t]
        if roll < current:
            return t
    return "forest"

func generate_region_name(terrain: String, rng: RandomNumberGenerator) -> String:
    var prefixes = ["", "苍", "青", "碧", "翠", "寒", "云", "落", "孤", "断"]
    var suffixes = terrain_names.get(terrain, ["岗"])
    var prefix = prefixes[rng.randi() % prefixes.size()] if rng.randi() % 2 == 0 else ""
    var suffix = suffixes[rng.randi() % suffixes.size()]
    return prefix + suffix
