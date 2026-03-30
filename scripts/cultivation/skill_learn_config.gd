class_name SkillLearnConfig
extends Resource

@export var skill_id: String
@export var name: String
@export var required_level: int = 1
@export var required_realm: String = "后天"
@export var required_stats: Dictionary = {}  # {"strength": 10}
@export var teacher_npc_id: String = ""
@export var purchase_cost: int = 0

func can_learn(data: CultivationData) -> bool:
    if data.level < required_level:
        return false
    var realm_index = CultivationData.REALMS.find(data.realm)
    var required_index = CultivationData.REALMS.find(required_realm)
    if realm_index < required_index:
        return false
    for stat in required_stats:
        if data.attributes.get(stat, 0) < required_stats[stat]:
            return false
    return true
