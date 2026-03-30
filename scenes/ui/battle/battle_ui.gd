class_name BattleUI
extends Control

# 引用 BattleManager
var battle_manager: BattleManager

# 节点引用
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var enemy_count_label: Label = $TopBar/EnemyCountLabel
@onready var player_info_panel: PanelContainer = $PlayerInfo
@onready var battle_log: RichTextLabel = $BattleLog
@onready var skill_grid: GridContainer = $BottomPanel/Margin/SkillGrid
@onready var enemy_list: VBoxContainer = $EnemyList

# 玩家信息节点
@onready var player_name_label: Label = $PlayerInfo/VBox/Name
@onready var player_hp_label: Label = $PlayerInfo/VBox/HP
@onready var player_hp_bar: ProgressBar = $PlayerInfo/VBox/HPBar
@onready var player_qi_label: Label = $PlayerInfo/VBox/Qi
@onready var player_qi_bar: ProgressBar = $PlayerInfo/VBox/QiBar
@onready var player_realm_label: Label = $PlayerInfo/VBox/Realm

# 操作按钮
@onready var normal_attack_btn: Button = $BottomPanel/Margin/SkillGrid/NormalAttack
@onready var defend_btn: Button = $BottomPanel/Margin/SkillGrid/Defend
@onready var items_btn: Button = $BottomPanel/Margin/SkillGrid/Items
@onready var escape_btn: Button = $BottomPanel/Margin/SkillGrid/Escape

# 技能按钮
var skill_buttons: Array[Button] = []

# 当前选中的目标
var selected_target_index: int = 0
var selected_skill_index: int = -1

# 是否处于选择目标状态
var selecting_target_for_skill: bool = false
var selecting_target_for_item: bool = false

# UI 场景引用
var skill_select_scene: PackedScene = preload("res://scenes/ui/battle/skill_select.tscn")
var item_select_scene: PackedScene = preload("res://scenes/ui/battle/item_select.tscn")
var battle_result_scene: PackedScene = preload("res://scenes/ui/battle/battle_result.tscn")

func _ready():
	_setup_buttons()
	visible = false

func _setup_buttons():
	# 收集技能按钮（跳过前4个非技能按钮）
	for i in range(4):
		var btn = skill_grid.get_child(i)
		if btn is Button:
			skill_buttons.append(btn)

	# 普通攻击
	normal_attack_btn.pressed.connect(_on_normal_attack)

	# 防御（暂时用普攻代替）
	defend_btn.pressed.connect(_on_defend)

	# 物品
	items_btn.pressed.connect(_on_items)

	# 逃跑
	escape_btn.pressed.connect(_on_escape)

	# 初始化技能按钮显示
	for i in range(skill_buttons.size()):
		skill_buttons[i].pressed.connect(_on_skill_selected.bind(i))

func initialize(bm: BattleManager):
	battle_manager = bm
	_setup_signals()
	visible = true
	_refresh_ui()

func _setup_signals():
	if battle_manager:
		battle_manager.battle_started.connect(_on_battle_started)
		battle_manager.battle_ended.connect(_on_battle_ended)
		battle_manager.turn_started.connect(_on_turn_started)
		battle_manager.action_executed.connect(_on_action_executed)
		battle_manager.battle_log_updated.connect(_on_battle_log_updated)
		battle_manager.escape_attempt.connect(_on_escape_attempt)

func _on_battle_started():
	_log("=== 战斗开始 ===")
	_update_enemy_list()
	_update_player_info()
	_set_buttons_enabled(true)

func _on_turn_started(is_player_turn: bool):
	if is_player_turn:
		turn_label.text = "玩家回合"
		turn_label.add_theme_color_override("font_color", Color.GREEN)
		_set_buttons_enabled(true)
		# 重置目标选择
		selected_target_index = 0
		_update_enemy_selection()
	else:
		turn_label.text = "敌人回合"
		turn_label.add_theme_color_override("font_color", Color.RED)
		_set_buttons_enabled(false)

func _on_action_executed(actor_name: String, result: Dictionary):
	if result.get("success"):
		var msg = result.get("message", "")
		_log("%s: %s" % [actor_name, msg])

		# 如果是玩家行动后，更新敌人HP显示
		if actor_name == battle_manager.get_player().name:
			_update_enemy_list()

		# 如果是敌人行动后，更新玩家HP显示
		if not result.get("is_player_action", true):
			_update_player_info()
	else:
		_log("操作失败: %s" % result.get("message", ""))

func _on_battle_ended(victory: bool, rewards: Dictionary):
	_set_buttons_enabled(false)

	# 显示结算界面
	var result_ui = battle_result_scene.instantiate()
	get_parent().add_child(result_ui)
	result_ui.show_result(victory, rewards)

	turn_label.text = "战斗结束"
	if victory:
		turn_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		turn_label.add_theme_color_override("font_color", Color.GRAY)

func _on_battle_log_updated(message: String):
	_log(message)

func _on_escape_attempt(escaped: bool):
	if escaped:
		_log("你成功逃跑了！")

		# 延迟关闭UI
		await get_tree().create_timer(1.5).timeout
		visible = false
	else:
		_log("逃跑失败！")

# ============ 玩家操作 ============

func _on_normal_attack():
	if battle_manager.get_state() != BattleManager.BattleState.PLAYER_TURN:
		return

	# 如果没有活着的敌人，不执行
	var enemies = battle_manager.get_enemies()
	if enemies.is_empty() or not enemies[selected_target_index].is_alive:
		# 自动选择下一个活着的敌人
		selected_target_index = _get_first_alive_enemy_index()
		if selected_target_index < 0:
			return

	var result = battle_manager.execute_player_attack(selected_target_index)
	if result.get("success"):
		_update_player_info()
		_update_enemy_list()

func _on_defend():
	_log("你进入防御姿态！")
	# 防御逻辑暂时用跳过回合代替
	# TODO: 实现防御增加防御力
	_start_enemy_turn()

func _on_skill_selected(skill_index: int):
	if battle_manager.get_state() != BattleManager.BattleState.PLAYER_TURN:
		return

	var player = battle_manager.get_player()
	if skill_index >= player.skills.size():
		return

	var skill = player.skills[skill_index]
	var cooldown = player.get_skill_cooldown(skill.skill_id)

	# 检查冷却
	if cooldown > 0:
		_log("%s 还在冷却中 (%d回合)" % [skill.name, cooldown])
		return

	# 检查内力
	if not player.use_qi(skill.qi_cost):
		_log("内力不足，需要 %d 点" % skill.qi_cost)
		return

	# 检查目标类型
	if skill.target_type == SkillData.TargetType.SINGLE_ENEMY:
		# 需要选择目标
		selecting_target_for_skill = true
		selected_skill_index = skill_index
		_update_enemy_selection()
		_log("选择目标使用 %s" % skill.name)
	else:
		# 直接执行
		var result = battle_manager.execute_player_skill(skill_index, selected_target_index)
		if result.get("success"):
			_update_player_info()
			_update_enemy_list()

func _on_skill_confirmed(target_index: int):
	if selected_skill_index < 0:
		return

	var result = battle_manager.execute_player_skill(selected_skill_index, target_index)
	if result.get("success"):
		_update_player_info()
		_update_enemy_list()

	selecting_target_for_skill = false
	selected_skill_index = -1
	_update_enemy_selection()

func _on_items():
	if battle_manager.get_state() != BattleManager.BattleState.PLAYER_TURN:
		return

	# 弹出物品选择界面
	var item_ui = item_select_scene.instantiate()
	get_parent().add_child(item_ui)
	item_ui.initialize(battle_manager)

func _on_escape():
	if battle_manager.get_state() != BattleManager.BattleState.PLAYER_TURN:
		return

	var result = battle_manager.try_escape()
	# 结果通过 escape_attempt 信号处理

func _start_enemy_turn():
	#敌人回合逻辑由 BattleManager 自动处理
	pass

# ============ UI 更新 ============

func _refresh_ui():
	_update_player_info()
	_update_enemy_list()
	_update_skill_buttons()
	_update_turn_label()

func _update_player_info():
	if not battle_manager:
		return

	var player = battle_manager.get_player()
	if not player:
		return

	player_name_label.text = player.name
	player_hp_label.text = "HP: %d/%d" % [player.current_health, player.get_max_health_with_realm()]
	player_hp_bar.max_value = player.get_max_health_with_realm()
	player_hp_bar.value = player.current_health

	player_qi_label.text = "气: %d/%d" % [player.current_qi, player.max_qi]
	player_qi_bar.max_value = player.max_qi
	player_qi_bar.value = player.current_qi

	player_realm_label.text = "境界: %s" % player.realm

func _update_enemy_list():
	if not battle_manager:
		return

	var enemies = battle_manager.get_enemies()
	enemy_count_label.text = "敌人: %d" % enemies.filter(func(e): return e.is_alive).size()

	# 清空现有列表
	for child in enemy_list.get_children():
		child.queue_free()

	# 创建敌人条目
	for i in enemies.size():
		var enemy = enemies[i]
		var entry = _create_enemy_entry(enemy, i)
		enemy_list.add_child(entry)

	_update_enemy_selection()

func _create_enemy_entry(enemy: CombatUnit, index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 60)

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var info = VBoxContainer.new()
	hbox.add_child(info)

	var name_label = Label.new()
	name_label.text = "%s [%s]" % [enemy.name, "存活" if enemy.is_alive else "死亡"]
	if not enemy.is_alive:
		name_label.add_theme_color_override("font_color", Color.GRAY)
	info.add_child(name_label)

	var hp_label = Label.new()
	hp_label.text = "HP: %d/%d" % [enemy.current_health, enemy.get_max_health_with_realm()]
	if not enemy.is_alive:
		hp_label.add_theme_color_override("font_color", Color.GRAY)
	info.add_child(hp_label)

	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100, 10)
	hp_bar.max_value = enemy.get_max_health_with_realm()
	hp_bar.value = enemy.current_health if enemy.is_alive else 0
	if not enemy.is_alive:
		hp_bar.add_theme_color_override("fill_color", Color.GRAY)
	info.add_child(hp_bar)

	# 选择按钮
	var select_btn = Button.new()
	select_btn.name = "SelectButton"
	select_btn.text = "选择"
	select_btn.disabled = not enemy.is_alive
	select_btn.pressed.connect(_on_enemy_selected.bind(index))
	hbox.add_child(select_btn)

	return panel

func _on_enemy_selected(index: int):
	selected_target_index = index
	_update_enemy_selection()

	# 如果正在选择技能目标，执行技能
	if selecting_target_for_skill:
		_on_skill_confirmed(index)
	elif selecting_target_for_item:
		# TODO: 处理物品目标选择
		pass

func _update_enemy_selection():
	for i in enemy_list.get_children().size():
		var entry = enemy_list.get_child(i)
		var select_btn = entry.get_node_or_null("HBoxContainer/SelectButton") as Button
		if select_btn:
			var enemy = battle_manager.get_enemies()[i]
			select_btn.button_pressed = (i == selected_target_index and enemy.is_alive)

func _update_skill_buttons():
	if not battle_manager:
		return

	var player = battle_manager.get_player()
	if not player:
		return

	# 更新技能按钮
	for i in range(min(skill_buttons.size(), player.skills.size())):
		var skill = player.skills[i]
		var btn = skill_buttons[i]
		btn.text = skill.name
		btn.disabled = false

		var cooldown = player.get_skill_cooldown(skill.skill_id)
		var can_use = player.current_qi >= skill.qi_cost and cooldown <= 0

		if cooldown > 0:
			btn.text = "%s (%d)" % [skill.name, cooldown]
			btn.add_theme_color_override("font_color", Color.GRAY)
		elif not can_use:
			btn.add_theme_color_override("font_color", Color.GRAY)
		else:
			btn.remove_theme_color_override("font_color")

func _update_turn_label():
	if not battle_manager:
		return

	match battle_manager.get_state():
		BattleManager.BattleState.IDLE:
			turn_label.text = "等待开始"
		BattleManager.BattleState.PLAYER_TURN:
			turn_label.text = "玩家回合"
		BattleManager.BattleState.ENEMY_TURN:
			turn_label.text = "敌人回合"
		BattleManager.BattleState.ANIMATING:
			turn_label.text = "动画中..."
		BattleManager.BattleState.ENDED:
			turn_label.text = "战斗结束"

func _set_buttons_enabled(enabled: bool):
	normal_attack_btn.disabled = not enabled
	defend_btn.disabled = not enabled
	items_btn.disabled = not enabled
	escape_btn.disabled = not enabled

	for btn in skill_buttons:
		btn.disabled = not enabled

func _get_first_alive_enemy_index() -> int:
	var enemies = battle_manager.get_enemies()
	for i in enemies.size():
		if enemies[i].is_alive:
			return i
	return -1

func _log(message: String):
	battle_log.append_text(message + "\n")
	# 自动滚动到底部
	battle_log.scroll_to_line(battle_log.get_line_count() - 1)
