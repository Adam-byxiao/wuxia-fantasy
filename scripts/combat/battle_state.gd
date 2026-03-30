class_name BattleState
extends Node

# 战斗状态枚举
enum {
    IDLE,           # 等待开始
    PLAYER_TURN,   # 玩家回合
    ENEMY_TURN,    # 敌人回合
    ANIMATING,     # 动画播放中
    ENDED          # 战斗结束
}

# 目标类型
enum TargetType {
    SINGLE_ENEMY = 0,   # 敌方单体
    ALL_ENEMIES = 1,    # 敌方全体
    SINGLE_ALLY = 2,    # 我方单体
    ALL_ALLIES = 3     # 我方全体
}
