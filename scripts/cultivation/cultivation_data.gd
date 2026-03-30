class_name CultivationData
extends Resource

const REALMS = ["后天", "先天气", "筑基", "金丹", "元婴", "化神", "渡劫", "大乘", "飞升"]

@export var level: int = 1
@export var exp: int = 0
@export var exp_to_next: int = 100

@export var realm: String = "后天"
@export var realm_progress: float = 0.0  # 0.0 ~ 1.0

@export var free_attribute_points: int = 0

@export var attributes: Dictionary = {
    "strength": 5,       #力道 - 影响攻击力
    "agility": 5,         #身法 - 影响速度/闪避
    "constitution": 5,    #体质 - 影响生命上限
    "qi_capacity": 5,     #气量 - 影响内力上限
    "wisdom": 5           #悟性 - 影响技能学习效率
}

@export var learned_skill_ids: Array[String]
@export var equipped_skill_ids: Array[String]

func _init():
    learned_skill_ids = []
    equipped_skill_ids = []

func can_level_up() -> bool:
    return exp >= exp_to_next

func level_up() -> bool:
    if exp >= exp_to_next:
        exp -= exp_to_next
        level += 1
        exp_to_next = _calc_exp_for_level(level)
        free_attribute_points += 5
        return true
    return false

func _calc_exp_for_level(lv: int) -> int:
    return int(100 * pow(1.5, lv - 1))

func add_attribute(point: String, amount: int = 1):
    if free_attribute_points >= amount and attributes.has(point):
        attributes[point] += amount
        free_attribute_points -= amount

func learn_skill(skill_id: String):
    if not skill_id in learned_skill_ids:
        learned_skill_ids.append(skill_id)

func to_dict() -> Dictionary:
    return {
        "level": level,
        "exp": exp,
        "realm": realm,
        "realm_progress": realm_progress,
        "free_points": free_attribute_points,
        "attributes": attributes,
        "learned_skills": learned_skill_ids,
        "equipped_skills": equipped_skill_ids
    }
