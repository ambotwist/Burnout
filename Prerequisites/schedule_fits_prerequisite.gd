class_name ScheduleFitsPrerequisite
extends CardPrerequisiteStrategy

## Checks if the card's duration fits in the remaining schedule time
## This prevents players from placing cards that don't fit

func is_satisfied(context: GameContext) -> bool:
	if not context.self_card or not context.schedule:
		print("    → Missing context data (self_card or schedule)")
		return false

	# Check if card duration fits in remaining time
	var card_duration = context.self_card.duration
	var time_left = context.time_left

	var fits = card_duration <= time_left
	if not fits:
		print("    → Card duration (", card_duration, ") > time left (", time_left, ")")

	return fits
