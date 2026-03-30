class_name CombatUnit
extends RefCounted

var unit_id: String
var name: String
var max_health: int
var current_health: int
var attack: int
var defense: int
var speed: int
var max_qi: int
var current_qi: int
var skills: Array[SkillData]  # 技能列表
var skill_cooldowns: Dictionary  # skill_id -> 剩余冷却回合
var is_player: bool = false
var is_alive: bool = true
var realm: String = "后天"  # 境界

# 暴击属性
var crit_rate: float = 0.05   # 暴击率 5%
var crit_damage: float = 1.5    # 暴击伤害 150%

# 境界加成表
const REALM_BONUS = {
    "后天": {"atk": 1.0, "def": 1.0, "hp": 1.0},
    "先天气": {"atk": 1.1, "def": 1.05, "hp": 1.2},
    "筑基": {"atk": 1.2, "def": 1.1, "hp": 1.5},
    "金丹": {"atk": 1.3, "def": 1.15, "hp": 2.0},
    "元婴": {"atk": 1.4, "def": 1.2, "hp": 2.5},
    "化神": {"atk": 1.5, "def": 1.25, "hp": 3.0}
}

func _init(
    p_name: String = "单位",
    p_max_hp: int = 100,
    p_atk: int = 10,
    p_def: int = 5,
    p_speed: int = 10,
    p_max_qi: int = 50
):
    name = p_name
    max_health = p_max_hp
    current_health = p_max_hp
    attack = p_atk
    defense = p_def
    speed = p_speed
    max_qi = p_max_qi
    current_qi = p_max_qi
    is_alive = true
    skills = []
    skill_cooldowns = {}

# 获取实际攻击力（含境界加成）
func get_attack_with_realm() -> int:
    var bonus = REALM_BONUS.get(realm, REALM_BONUS["后天"])
    return int(attack * bonus["atk"])

# 获取实际防御力（含境界加成）
func get_defense_with_realm() -> int:
    var bonus = REALM_BONUS.get(realm, REALM_BONUS["后天"])
    return int(defense * bonus["def"])

# 获取实际最大生命（含境界加成）
func get_max_health_with_realm() -> int:
    var bonus = REALM_BONUS.get(realm, REALM_BONUS["后天"])
    return int(max_health * bonus["hp"])

func take_damage(dmg: int) -> int:
    var actual = max(1, dmg - get_defense_with_realm())
    current_health = max(0, current_health - actual)
    if current_health <= 0:
        is_alive = false
    return actual

func heal(amount: int):
    current_health = min(max_health, current_health + amount)

func use_qi(amount: int) -> bool:
    if current_qi >= amount:
        current_qi -= amount
        return true
    return false

func restore_qi(amount: int):
    current_qi = min(max_qi, current_qi + amount)

# 判断是否暴击
func is_crit() -> bool:
    return randf() < crit_rate

# 计算暴击伤害
func calc_crit_damage(base_damage: int) -> int:
    if is_crit():
        return int(base_damage * crit_damage)
    return base_damage

# 添加技能
func add_skill(skill: SkillData):
    skills.append(skill)
    skill_cooldowns[skill.skill_id] = 0

# 获取技能冷却
func get_skill_cooldown(skill_id: String) -> int:
    return skill_cooldowns.get(skill_id, 0)

# 使用技能后减少冷却
func use_skill(skill: SkillData):
    if skill.cooldown_max > 0:
        skill_cooldowns[skill.skill_id] = skill.cooldown_max

# 每回合减少所有技能冷却
func reduce_cooldowns():
    for skill_id in skill_cooldowns:
        if skill_cooldowns[skill_id] > 0:
            skill_cooldowns[skill_id] -= 1
