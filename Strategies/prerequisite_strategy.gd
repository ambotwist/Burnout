class_name PrerequisiteStrategy
extends Resource

## Base class for all prerequisites (card play and effect activation)
## Subclasses implement is_satisfied() to check conditions

func is_satisfied(context: GameContext) -> bool:
	push_error("Function must be implemented in subclass")
	return false
