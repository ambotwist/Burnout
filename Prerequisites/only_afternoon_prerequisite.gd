class_name OnlyAfternoonPrerequisite
extends PrerequisiteStrategy

## Checks if current time is afternoon (>= 12:00)
## Can be used for both card play validation and effect activation

func is_satisfied(context: GameContext) -> bool:
	return context.current_time >= 12.0
