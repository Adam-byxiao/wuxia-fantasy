extends Control

@onready var tab_attributes: Button = $Margin/VBox/TabBar/TabAttributes
@onready var tab_relations: Button = $Margin/VBox/TabBar/TabRelations
@onready var tab_skills: Button = $Margin/VBox/TabBar/TabSkills
@onready var tab_meridians: Button = $Margin/VBox/TabBar/TabMeridians
@onready var close_btn: Button = $Margin/VBox/TitleBar/CloseBtn
@onready var content_area: VBoxContainer = $Margin/VBox/ContentArea

var _tab_buttons: Array[Button] = []
var _current_tab: String = "attributes"

# 预加载子面板
var _attr_panel: Control
var _rel_panel: Control
var _skill_panel: Control
var _mer_panel: Control

func _ready():
	_setup_tabs()
	_setup_buttons()
	_show_tab("attributes")

func _setup_tabs():
	# 创建子面板实例
	_attr_panel = preload("res://scenes/ui/personal/attributes_panel.tscn").instantiate()
	_rel_panel = preload("res://scenes/ui/personal/relations_panel.tscn").instantiate()
	_skill_panel = preload("res://scenes/ui/personal/skills_panel.tscn").instantiate()
	_mer_panel = preload("res://scenes/ui/personal/meridians_panel.tscn").instantiate()

	# 初始全部隐藏
	for panel in [_attr_panel, _rel_panel, _skill_panel, _mer_panel]:
		panel.visible = false
		content_area.add_child(panel)

func _setup_buttons():
	_tab_buttons = [tab_attributes, tab_relations, tab_skills, tab_meridians]
	tab_attributes.pressed.connect(func(): _show_tab("attributes"))
	tab_relations.pressed.connect(func(): _show_tab("relations"))
	tab_skills.pressed.connect(func(): _show_tab("skills"))
	tab_meridians.pressed.connect(func(): _show_tab("meridians"))
	close_btn.pressed.connect(_on_close)

func _show_tab(tab_name: String):
	_current_tab = tab_name

	# 隐藏所有面板
	for panel in [_attr_panel, _rel_panel, _skill_panel, _mer_panel]:
		panel.visible = false

	# 高亮当前tab按钮
	for btn in _tab_buttons:
		btn.add_theme_color_override("font_color", Color.WHITE)
	match tab_name:
		"attributes":
			tab_attributes.add_theme_color_override("font_color", Color.YELLOW)
			_attr_panel.visible = true
			_update_attributes()
		"relations":
			tab_relations.add_theme_color_override("font_color", Color.YELLOW)
			_rel_panel.visible = true
			_update_relations()
		"skills":
			tab_skills.add_theme_color_override("font_color", Color.YELLOW)
			_skill_panel.visible = true
			_update_skills()
		"meridians":
			tab_meridians.add_theme_color_override("font_color", Color.YELLOW)
			_mer_panel.visible = true
			_update_meridians()

func _update_attributes():
	var cult = CultivationSystem.data
	var inv = GameState.player_inventory
	var stats = CultivationSystem.get_combat_stats()

	# 基础信息
	var level_label = _attr_panel.get_node_or_null("BasicInfo/LeftInfo/LevelLabel")
	if level_label:
		level_label.text = "等级: %d" % cult.level

	var exp_label = _attr_panel.get_node_or_null("BasicInfo/LeftInfo/ExpLabel")
	if exp_label:
		exp_label.text = "经验: %d / %d" % [cult.exp, cult.exp_to_next]

	var realm_label = _attr_panel.get_node_or_null("BasicInfo/LeftInfo/RealmLabel")
	if realm_label:
		realm_label.text = "境界: %s" % cult.realm

	# 金币
	var gold_label = _attr_panel.get_node_or_null("BasicInfo/RightInfo/GoldLabel")
	if gold_label:
		gold_label.text = "金币: %d" % inv.gold

	# 战斗属性
	var hp_label = _attr_panel.get_node_or_null("CombatAttrs/LeftAttrs/HP")
	if hp_label:
		hp_label.text = "生命: %d / %d" % [stats["max_health"], stats["max_health"]]

	var qi_label = _attr_panel.get_node_or_null("CombatAttrs/LeftAttrs/Qi")
	if qi_label:
		qi_label.text = "内力: %d / %d" % [stats["max_qi"], stats["max_qi"]]

	var atk_label = _attr_panel.get_node_or_null("CombatAttrs/LeftAttrs/ATK")
	if atk_label:
		atk_label.text = "攻击: %d" % stats["attack"]

	var def_label = _attr_panel.get_node_or_null("CombatAttrs/LeftAttrs/DEF")
	if def_label:
		def_label.text = "防御: %d" % stats["defense"]

	var spd_label = _attr_panel.get_node_or_null("CombatAttrs/LeftAttrs/SPD")
	if spd_label:
		spd_label.text = "速度: %d" % stats["speed"]

	var cri_label = _attr_panel.get_node_or_null("CombatAttrs/LeftAttrs/CRI")
	if cri_label:
		cri_label.text = "暴击: %.0f%%" % (stats["crit_rate"] * 100)

	# 六维属性
	var str_label = _attr_panel.get_node_or_null("CombatAttrs/RightAttrs/Str")
	if str_label:
		str_label.text = "力道: %d" % cult.attributes["strength"]

	var agi_label = _attr_panel.get_node_or_null("CombatAttrs/RightAttrs/Agi")
	if agi_label:
		agi_label.text = "身法: %d" % cult.attributes["agility"]

	var con_label = _attr_panel.get_node_or_null("CombatAttrs/RightAttrs/Con")
	if con_label:
		con_label.text = "体质: %d" % cult.attributes["constitution"]

	var qicap_label = _attr_panel.get_node_or_null("CombatAttrs/RightAttrs/QiCap")
	if qicap_label:
		qicap_label.text = "气量: %d" % cult.attributes["qi_capacity"]

	var wis_label = _attr_panel.get_node_or_null("CombatAttrs/RightAttrs/Wis")
	if wis_label:
		wis_label.text = "悟性: %d" % cult.attributes["wisdom"]

	# 装备栏 - 获取已装备物品
	var equipped_items = inv.get_equipped_items()
	var weapon_name = _attr_panel.get_node_or_null("EquipSection/WeaponSlot/VBox/WeaponName")
	var weapon_stat = _attr_panel.get_node_or_null("EquipSection/WeaponSlot/VBox/WeaponStat")
	var armor_name = _attr_panel.get_node_or_null("EquipSection/ArmorSlot/VBox/ArmorName")
	var armor_stat = _attr_panel.get_node_or_null("EquipSection/ArmorSlot/VBox/ArmorStat")
	var accessory_name = _attr_panel.get_node_or_null("EquipSection/AccessorySlot/VBox/AccessoryName")
	var accessory_stat = _attr_panel.get_node_or_null("EquipSection/AccessorySlot/VBox/AccessoryStat")

	# 重置装备显示
	if weapon_name:
		weapon_name.text = "武器"
	if weapon_stat:
		weapon_stat.text = "无"
	if armor_name:
		armor_name.text = "防具"
	if armor_stat:
		armor_stat.text = "无"
	if accessory_name:
		accessory_name.text = "饰品"
	if accessory_stat:
		accessory_stat.text = "无"

	# 遍历已装备物品并更新显示
	for entry in equipped_items:
		var item = entry["item"]
		if item.equip_slot == "weapon":
			if weapon_name:
				weapon_name.text = item.name
			if weapon_stat:
				weapon_stat.text = "+%d攻击" % item.value
		elif item.equip_slot == "armor":
			if armor_name:
				armor_name.text = item.name
			if armor_stat:
				armor_stat.text = "+%d防御" % item.value
		elif item.equip_slot == "accessory":
			if accessory_name:
				accessory_name.text = item.name
			if accessory_stat:
				accessory_stat.text = "+%d属性" % item.value

func _update_relations():
	pass

func _update_skills():
	pass

func _update_meridians():
	pass

func _on_close():
	queue_free()
