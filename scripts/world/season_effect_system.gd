# 季节效果系统
# 监听季节变化，更新世界渲染器的视觉表现

extends Node

# ============ 引用 ============
@export var world_renderer_path: NodePath = NodePath("../WorldRenderer")
var _world_renderer: Node2D = null

# ============ 生命周期 ============
func _ready() -> void:
	_world_renderer = get_node_or_null(world_renderer_path)

	# 连接 TimeManager 的季节变化信号
	if TimeManager.has_signal("season_changed"):
		TimeManager.season_changed.connect(_on_season_changed)
	else:
		# 兼容：监听 day_passed 并手动检查季节
		SignalBus.day_passed.connect(_on_day_passed)

	print("[SeasonEffectSystem] 初始化完成")

# ============ 信号处理 ============
func _on_season_changed(season: String) -> void:
	print("[SeasonEffectSystem] 季节变化: ", season)
	_apply_season_visual(season)

func _on_day_passed(day: int) -> void:
	# 每 30 天检查一次季节
	if day % 30 == 0:
		var expected_season = TimeManager.current_season if "current_season" in TimeManager else "春"
		_apply_season_visual(expected_season)

# ============ 应用季节视觉 ============
func _apply_season_visual(season: String) -> void:
	if _world_renderer != null and _world_renderer.has_method("apply_season_overlay"):
		_world_renderer.apply_season_overlay(season)
	else:
		push_warning("[SeasonEffectSystem] WorldRenderer 未找到或不支持季节效果")

# ============ 公共方法 ============
func set_world_renderer(renderer: Node2D) -> void:
	_world_renderer = renderer

func force_update_season() -> void:
	if TimeManager.has_method("get_current_season"):
		var season = TimeManager.get_current_season()
		_apply_season_visual(season)
