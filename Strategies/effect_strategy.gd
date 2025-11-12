class_name EffectStrategy
extends Resource

@export var trigger: GameEnums.EffectTrigger
@export var prerequisites: Array[PrerequisiteStrategy]

# ABSTRACT FUNCTIONS
func apply_effect(context: GameContext) -> void:
	push_error("Function must be implemented in subclass")
