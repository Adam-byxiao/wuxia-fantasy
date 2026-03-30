class_name Skill
extends Resource

@export var skill_id: String
@export var name: String
@export var description: String
@export var damage: int = 0
@export var heal_amount: int = 0
@export var qi_cost: int = 0
@export var cooldown_max: int = 0
@export var cooldown_current: int = 0

var _owner: CombatUnit

func can_use() -> bool:
    return cooldown_current == 0 and (_owner.current_qi >= qi_cost if qi_cost > 0 else true)

func execute(target: CombatUnit) -> Dictionary:
    var result = {"success": false, "damage": 0, "heal": 0, "message": ""}

    if not can_use():
        result["message"] = "无法使用该技能"
        return result

    if qi_cost > 0:
        _owner.use_qi(qi_cost)

    cooldown_current = cooldown_max

    if damage > 0:
        result["damage"] = target.take_damage(damage)
        result["success"] = true
        result["message"] = "%s 使用了 %s，造成 %d 点伤害" % [_owner.name, name, result["damage"]]
    elif heal_amount > 0:
        _owner.heal(heal_amount)
        result["heal"] = heal_amount
        result["success"] = true
        result["message"] = "%s 使用了 %s，恢复 %d 点生命" % [_owner.name, name, heal_amount]

    return result

func reset_cooldown():
    cooldown_current = 0
