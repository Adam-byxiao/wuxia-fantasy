extends Node2D

const TEST_SCENES = {
	"单元测试": {
		"scene": "res://scenes/test/test_runner.tscn",
		"desc": "运行所有模块的单元测试\n- SignalBus/GameState\n- TimeManager/WorldGenerator\n- CombatUnit/Skill/BattleManager\n- CultivationSystem/ItemData\n- InventoryData/NPCManager"
	},
	"背包测试": {
		"scene": "res://scenes/test/test_inventory.tscn",
		"desc": "测试背包与物品系统\n- 装备/暗器/丹药/书籍/秘籍\n- 物品使用与详情显示\n- 人物属性面板绑定"
	},
	"世界生成(原)": {
		"scene": "res://scenes/verification/verify_world_gen.tscn",
		"desc": "测试基础世界生成\n- 验证区域数量(5-10)\n- 验证路径连接(MST)\n- 验证名称生成\n- 验证确定性(seed)"
	},
	"MVP世界生成": {
		"scene": "res://scenes/verification/verify_mvp_world_gen.tscn",
		"desc": "测试MVP世界渲染系统\n- TileMap渲染\n- 季节色调变化\n- 区域过渡动画\n- NPC路径移动\n- 难度奖励配置"
	},
	"纹理生成": {
		"scene": "res://scenes/verification/verify_textures.tscn",
		"desc": "测试程序化纹理生成\n- 噪声生成(Perlin/Simplex)\n- 地形瓦片生成\n- 纹理图集打包"
	},
	"时间系统": {
		"scene": "res://scenes/verification/verify_time.tscn",
		"desc": "测试时间推进\n- 验证日/季节变化\n- 验证时间加速/暂停\n- 验证事件触发"
	},
	"战斗系统": {
		"scene": "res://scenes/verification/verify_battle.tscn",
		"desc": "测试回合制战斗\n- 验证伤害计算\n- 验证技能效果\n- 验证逃跑机制\n- 验证胜负结算"
	},
	"养成系统": {
		"scene": "res://scenes/verification/verify_cultivation.tscn",
		"desc": "测试角色养成\n- 验证经验获取\n- 验证等级提升(公式:100*1.5^n)\n- 验证境界突破\n- 验证战斗属性计算"
	},
	"NPC AI": {
		"scene": "res://scenes/verification/verify_npc.tscn",
		"desc": "测试NPC行为系统\n- 验证6种AI类型\n- 验证目标权重评估\n- 验证沙盒每日tick\n- 验证区域间移动"
	},
	"综合沙盒": {
		"scene": "res://scenes/main.tscn",
		"desc": "综合测试所有模块\n- 玩家移动\n- 世界演化\n- NPC自动行为\n- 季节视觉变化"
	}
}

var buttons = []
var current_selection = 0

@onready var button_container: VBoxContainer = $ButtonContainer
@onready var info_text: Label = $InfoPanel/InfoBox/InfoText

func _ready():
	_build_buttons()
	_update_info()

func _build_buttons():
	for key in TEST_SCENES.keys():
		var btn = Button.new()
		btn.text = "► " + key
		btn.custom_minimum_size = Vector2(380, 48)
		btn.pressed.connect(_on_btn.bind(key))
		button_container.add_child(btn)
		buttons.append(btn)

func _input(event: InputEvent):
	if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		current_selection = (current_selection + 1) % buttons.size()
		_update_selection()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		current_selection = (current_selection - 1 + buttons.size()) % buttons.size()
		_update_selection()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_launch_selected()
	elif event.is_action_pressed("ui_cancel"):
		print("已在主菜单")

func _update_selection():
	for i in range(buttons.size()):
		buttons[i].text = "  " + TEST_SCENES.keys()[i] if i != current_selection else "► " + TEST_SCENES.keys()[i]
	_update_info()

func _update_info():
	var keys = TEST_SCENES.keys()
	if current_selection < keys.size():
		info_text.text = TEST_SCENES[keys[current_selection]]["desc"]

func _on_btn(key: String):
	var idx = TEST_SCENES.keys().find(key)
	if idx >= 0:
		current_selection = idx
		_launch_selected()

func _launch_selected():
	var keys = TEST_SCENES.keys()
	if current_selection < keys.size():
		var scene_path = TEST_SCENES[keys[current_selection]]["scene"]
		print("[菜单] 启动: ", keys[current_selection])
		get_tree().change_scene_to_file(scene_path)
