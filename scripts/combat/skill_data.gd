class_name SkillData
extends Resource

# 目标类型
enum TargetType {
    SINGLE_ENEMY = 0,   # 敌方单体
    ALL_ENEMIES = 1,    # 敌方全体
    SINGLE_ALLY = 2,    # 我方单体(暂不支持)
    ALL_ALLIES = 3      # 我方全体(暂不支持)
}

var skill_id: String = ""
var name: String = ""
var description: String = ""
var damage: int = 0           # 技能伤害，0表示无伤害
var heal_amount: int = 0     # 治疗量，0表示无治疗
var qi_cost: int = 0          # 内力消耗
var cooldown_max: int = 0     # 冷却回合数
var target_type: TargetType = TargetType.SINGLE_ENEMY

func _init(
    p_id: String = "",
    p_name: String = "",
    p_desc: String = "",
    p_damage: int = 0,
    p_heal: int = 0,
    p_qi_cost: int = 0,
    p_cooldown: int = 0,
    p_target: TargetType = TargetType.SINGLE_ENEMY
):
    skill_id = p_id
    name = p_name
    description = p_desc
    damage = p_damage
    heal_amount = p_heal
    qi_cost = p_qi_cost
    cooldown_max = p_cooldown
    target_type = p_target

func can_use(current_qi: int, current_cooldown: int) -> bool:
    return current_qi >= qi_cost and current_cooldown <= 0

# 获取冷却描述
func get_cooldown_text() -> String:
    if cooldown_max == 0:
        return "无冷却"
    return "%d回合" % cooldown_max

# 获取目标描述
func get_target_text() -> String:
    match target_type:
        TargetType.SINGLE_ENEMY: return "敌方单体"
        TargetType.ALL_ENEMIES: return "敌方全体"
        TargetType.SINGLE_ALLY: return "我方单体"
        TargetType.ALL_ALLIES: return "我方全体"
    return "未知"

# 静态方法：创建预设技能
static func create_palm_strike() -> SkillData:
    return SkillData.new(
        "palm_strike",
        "掌心雷",
        "先天气境界基础技能，聚气发出的一道雷击",
        35, 0, 20, 1,
        TargetType.SINGLE_ENEMY
    )

static func create_sword_qi() -> SkillData:
    return SkillData.new(
        "sword_qi",
        "剑气术",
        "以剑气伤敌，筑基期以上可用",
        50, 0, 30, 2,
        TargetType.SINGLE_ENEMY
    )

static func create_dragon_claw() -> SkillData:
    return SkillData.new(
        "dragon_claw",
        "龙爪手",
        "刚猛武学，金丹期以上可用",
        80, 0, 50, 3,
        TargetType.SINGLE_ENEMY
    )

static func create_heal_wind() -> SkillData:
    return SkillData.new(
        "heal_wind",
        "治愈术",
        "以内力治愈伤口",
        0, 30, 25, 2,
        TargetType.SINGLE_ENEMY
    )

# 获取玩家初始技能
static func get_player_starting_skills() -> Array[SkillData]:
    return [
        create_palm_strike(),
    ]

# 获取所有预设技能
static func get_all_preset_skills() -> Array[SkillData]:
    return [
        create_palm_strike(),
        create_sword_qi(),
        create_dragon_claw(),
        create_heal_wind(),
    ]
