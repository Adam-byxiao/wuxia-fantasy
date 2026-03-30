class_name PlayerController
extends Node

@export var player: Player

func _ready():
    if player == null and has_node("Player"):
        player = get_node("Player")

func _process(delta):
    _handle_interaction()

func _handle_interaction():
    if Input.is_action_just_pressed("interact"):
        _try_interact_with_npc()
    if Input.is_action_just_pressed("open_inventory"):
        _open_inventory()
    if Input.is_action_just_pressed("open_skills"):
        _open_skills()

func _try_interact_with_npc():
    var overlapping_bodies = player.get_overlapping_bodies()
    for body in overlapping_bodies:
        if body is NPCBrain:
            SignalBus.npc_interaction_requested.emit(body)
            return

func _open_inventory():
    SignalBus.inventory_requested.emit()

func _open_skills():
    SignalBus.skills_requested.emit()
