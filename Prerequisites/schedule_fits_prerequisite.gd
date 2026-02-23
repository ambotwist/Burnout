class_name ScheduleFitsPrerequisite
extends CardPrerequisiteStrategy

## Checks if there is any remaining schedule time.
## Cards that overflow the schedule are allowed (overtime) but cost double sanity.

func is_satisfied(context: GameContext) -> bool:
	if not context.self_card or not context.schedule:
		print("    → Missing context data (self_card or schedule)")
		return false

	# Allow any card as long as there's at least one slot remaining
	return context.time_left > 0
