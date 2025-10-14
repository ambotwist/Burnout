extends Node2D
class_name effects_manager

var effects_queue: Array[Effect] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass


# Processes the effects queue.
func process_effects_queue() -> void:
    for effect in effects_queue:
        if effect.can_play():
            effect.apply()
            effects_queue.erase(effect)