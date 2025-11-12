class_name NonEmptyHandPrerequisite
extends PrerequisiteStrategy

## Checks if the hand is not empty
## Can be used for both card play validation and effect activation

func is_satisfied(context: GameContext) -> bool:
	return context.hand.size() > 0