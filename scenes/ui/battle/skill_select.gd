class_name SkillSelect
extends Control

signal closed()

var battle_manager: BattleManager
var selected_skill_index: int = -1
var selected_target_index: int = 0

func _ready():
	$Panel/VBox/CloseBtn.pressed.connect(_on_close)
	$Panel.gui_input.connect(_on_panel_input)

func initialize(bm: BattleManager):
	battle_manager = bm
	_refresh_skill_list()

func _refresh_skill_list():
	var skill_list = $Panel/VBox/SkillList
	var title = $Panel/VBox/Title
	title.text = "选择技能"

	# 清空现有列表
	for child in skill_list.get_children():
		child.queue_free()

	var player = battle_manager.get_player()
	if not player:
		return

	for i in player.skills.size():
		var skill = player.skills[i]
		var cooldown = player.get_skill_cooldown(skill.skill_id)
		var can_use = player.current_qi >= skill.qi_cost and cooldown <= 0

		var skill_btn = Button.new()
		skill_btn.custom_minimum_size = Vector2(300, 50)

		var text = "%s | 消耗: %d气 | 伤害: %d | 冷却: %s" % [
			skill.name, skill.qi_cost, skill.damage, skill.get_cooldown_text()]

		if not can_use:
			if cooldown > 0:
				text += " [冷却中]"
			elif player.current_qi < skill.qi_cost:
				text += " [气不足]"
			skill_btn.add_theme_color_override("font_color", Color.GRAY)
			skill_btn.disabled = true

		skill_btn.text = text
		skill_btn.pressed.connect(_on_skill_clicked.bind(i))
		skill_list.add_child(skill_btn)

func _on_skill_clicked(index: int):
	selected_skill_index = index
	var skill = battle_manager.get_player().skills[index]

	if skill.target_type == SkillData.TargetType.SINGLE_ENEMY:
		# 需要选择目标，显示目标选择
		_show_target_selection(index)
	else:
		# 直接执行（不需要目标）
		battle_manager.execute_player_skill(index, 0)
		queue_free()

func _show_target_selection(skill_index: int):
	var skill_list = $Panel/VBox/SkillList
	var title = $Panel/VBox/Title
	title.text = "选择目标"

	# 清空技能列表，显示敌人选择
	for child in skill_list.get_children():
		child.queue_free()

	var enemies = battle_manager.get_enemies()
	for i in enemies.size():
		var enemy = enemies[i]
		var target_btn = Button.new()
		target_btn.custom_minimum_size = Vector2(300, 40)

		var text = "%s | HP: %d/%d" % [
			enemy.name, enemy.current_health, enemy.get_max_health_with_realm()]

		if not enemy.is_alive:
			text += " [已死亡]"
			target_btn.disabled = true
			target_btn.add_theme_color_override("font_color", Color.GRAY)

		target_btn.text = text
		target_btn.pressed.connect(_on_target_selected.bind(skill_index, i))
		skill_list.add_child(target_btn)

	# 添加返回按钮
	var back_btn = Button.new()
	back_btn.text = "返回"
	back_btn.pressed.connect(_on_back_to_skills)
	skill_list.add_child(back_btn)

func _on_target_selected(skill_index: int, target_index: int):
	battle_manager.execute_player_skill(skill_index, target_index)
	queue_free()

func _on_back_to_skills():
	_refresh_skill_list()

func _on_close():
	closed.emit()
	queue_free()

func _on_panel_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_on_close()
