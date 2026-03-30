class_name EventConfig
extends Resource

@export var event_id: String
@export var name: String
@export var event_type: String  # combat, social, cultivation, discovery
@export var weight: int = 10
@export var min_day: int = 1
@export var terrain_filter: Array[String]  # 空=任意地形
