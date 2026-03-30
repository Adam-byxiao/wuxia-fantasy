# 区域过渡组件
# 监测玩家位置变化，触发区域过渡动画

extends Node

# 预加载配置类
const _Config = preload("res://scripts/world/world_renderer_config.gd")

# ============ 导出配置 ============
@export var transition_duration: float = 1.1  # 总过渡时间
@export var check_interval: float = 0.1        # 检测间隔

# ============ 内部变量 ============
var _current_region_id: String = ""
var _player_path: NodePath = NodePath("/root/Main/Player")
var _world_renderer_path: NodePath = NodePath("../WorldRenderer")
var _player: Node2D = null
var _world_renderer: Node2D = null
var _transitioning: bool = false
var _transition_timer: float = 0.0

# ============ 过渡阶段 ============
enum TransitionPhase {
	NONE,
	FADE_IN,
	DISPLAY_TEXT,
	FADE_OUT
}

var _current_phase: TransitionPhase = TransitionPhase.NONE
var _transition_progress: float = 0.0
var _display_region_name: String = ""

# ============ Canvas 节点 ============
var _overlay: ColorRect = null
var _label: Label = null

# ============ 生命周期 ============
func _ready() -> void:
	_setup_transition_ui()
	_get_nodes()

	# 连接信号
	SignalBus.region_entered.connect(_on_region_entered)

	print("[RegionTransition] 初始化完成")

func _setup_transition_ui() -> void:
	# 创建全屏黑色遮罩
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	# 创建区域名称标签
	_label = Label.new()
	_label.text = ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 48)
	_label.modulate = Color(1, 1, 1, 0)
	add_child(_label)

func _get_nodes() -> void:
	_player = get_node_or_null(_player_path)
	_world_renderer = get_node_or_null(_world_renderer_path)

# ============ 进程处理 ============
func _process(delta: float) -> void:
	if _transitioning:
		_update_transition(delta)
	else:
		_check_region_change(delta)

# ============ 检测区域变化 ============
var _check_timer: float = 0.0

func _check_region_change(delta: float) -> void:
	_check_timer += delta
	if _check_timer < check_interval:
		return
	_check_timer = 0.0

	if _player == null:
		_player = get_node_or_null(_player_path)

	if _player == null or _world_renderer == null:
		return

	# 获取玩家当前所在区域
	var player_pos = _player.global_position
	var region = _world_renderer.get_region_at_position(player_pos)

	if region != null and region.id != _current_region_id:
		_trigger_transition(region)

# ============ 触发过渡 ============
func _trigger_transition(region: RegionData) -> void:
	var previous_region_id = _current_region_id
	_current_region_id = region.id
	_display_region_name = region.name

	print("[RegionTransition] 区域过渡: ", previous_region_id, " -> ", region.id)

	# 开始过渡动画
	_transitioning = true
	_current_phase = TransitionPhase.FADE_IN
	_transition_progress = 0.0

	# 发射信号
	SignalBus.region_entered.emit(region.id)

	# 更新 GameState
	GameState.current_region_id = region.id
	GameState.current_region = region.name

# ============ 更新过渡动画 ============
func _update_transition(delta: float) -> void:
	_transition_progress += delta

	match _current_phase:
		TransitionPhase.FADE_IN:
			var t = _transition_progress / _Config.TRANSITION_FADE_IN_DURATION
			if t >= 1.0:
				t = 1.0
				_current_phase = TransitionPhase.DISPLAY_TEXT
				_transition_progress = 0.0
			_overlay.color = Color(0, 0, 0, t)
			_label.modulate = Color(1, 1, 1, t)

		TransitionPhase.DISPLAY_TEXT:
			var t = _transition_progress / _Config.TRANSITION_TEXT_DURATION
			if t >= 1.0:
				_current_phase = TransitionPhase.FADE_OUT
				_transition_progress = 0.0
			_overlay.color = Color(0, 0, 0, 1.0)
			_label.modulate = Color(1, 1, 1, 1.0)

		TransitionPhase.FADE_OUT:
			var t = _transition_progress / _Config.TRANSITION_FADE_OUT_DURATION
			if t >= 1.0:
				t = 1.0
				_end_transition()
			_overlay.color = Color(0, 0, 0, 1.0 - t)
			_label.modulate = Color(1, 1, 1, 1.0 - t)

# ============ 结束过渡 ============
func _end_transition() -> void:
	_transitioning = false
	_current_phase = TransitionPhase.NONE
	_transition_progress = 0.0
	_overlay.color = Color(0, 0, 0, 0)
	_label.modulate = Color(1, 1, 1, 0)
	_label.text = ""

# ============ 信号处理 ============
func _on_region_entered(region_id: String) -> void:
	print("[RegionTransition] 收到区域进入信号: ", region_id)

# ============ 公共方法 ============
func set_player_path(path: NodePath) -> void:
	_player_path = path
	_player = get_node_or_null(_player_path)

func force_trigger_region(region_id: String) -> void:
	if _world_renderer != null and _world_renderer.has_method("get_region_at_position"):
		# 手动触发，需要传入 region 对象
		pass

func skip_transition() -> void:
	_end_transition()
