extends Node2D

@onready var world_layer: Node2D = $WorldLayer
@onready var ui_layer: CanvasLayer = $UILayer

func get_world_layer() -> Node2D:
	return world_layer

func get_ui_layer() -> CanvasLayer:
	return ui_layer
