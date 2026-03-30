extends Node

var data: CultivationData

func _ready():
    data = CultivationData.new()
    SignalBus.battle_ended.connect(_on_battle_ended)

func _on_battle_ended(victory: bool, rewards: Dictionary):
    if victory and rewards.has("exp"):
        add_exp(rewards["exp"])

func add_exp(amount: int):
    var old_level = data.level
    var exp_left = amount

    while exp_left > 0 and data.can_level_up():
        data.level_up()
        exp_left -= 0  # level_up 已经扣除了需要的 exp

    # 简单累计剩余经验
    if exp_left > 0:
        data.exp += exp_left

    SignalBus.exp_gained.emit(amount)

    if data.level > old_level:
        SignalBus.level_up.emit(data.level)
        print("[养成] 升级了！当前等级: ", data.level)

func gain_realm_progress(amount: float):
    data.realm_progress += amount
    if data.realm_progress >= 1.0:
        _try_breakthrough()

func _try_breakthrough() -> bool:
    var current_index = CultivationData.REALMS.find(data.realm)
    if current_index < CultivationData.REALMS.size() - 1:
        data.realm = CultivationData.REALMS[current_index + 1]
        data.realm_progress = 0.0
        SignalBus.realm_broken.emit(data.realm)
        print("[养成] 境界突破: ", data.realm)
        return true
    return false

func can_equip_skill(skill_id: String) -> bool:
    return skill_id in data.learned_skill_ids

func equip_skill(skill_id: String) -> bool:
    if can_equip_skill(skill_id):
        if not skill_id in data.equipped_skill_ids:
            data.equipped_skill_ids.append(skill_id)
        SignalBus.skill_equipped.emit(skill_id)
        return true
    return false

func unequip_skill(skill_id: String):
    data.equipped_skill_ids.erase(skill_id)

func get_combat_stats() -> Dictionary:
    return {
        "max_health": 100 + data.attributes["constitution"] * 20,
        "max_qi": 50 + data.attributes["qi_capacity"] * 10,
        "attack": 10 + data.attributes["strength"] * 3,
        "defense": 5 + data.attributes["constitution"] * 2,
        "speed": 8 + data.attributes["agility"] * 2,
        "crit_rate": 0.05 + data.attributes["wisdom"] * 0.01,
        "crit_damage": 1.5
    }
