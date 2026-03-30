class_name RealmConfig
extends Resource

@export var realm_name: String = "后天"
@export var display_name: String = "后天境"
@export var required_level: int = 1
@export var stat_bonuses: Dictionary = {}  # {"attack": 10, "defense": 5}
@export var unlock_skills: Array[String] = []

static func get_realm_index(realm: String) -> int:
    return CultivationData.REALMS.find(realm)
