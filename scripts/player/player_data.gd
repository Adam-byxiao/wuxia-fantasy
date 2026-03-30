class_name PlayerData
extends Resource

@export var name: String = "无名侠客"
@export var cultivation: CultivationData
@export var position: Vector2 = Vector2.ZERO
@export var current_region: String = ""
@export var gold: int = 100

func _init():
    cultivation = CultivationData.new()
