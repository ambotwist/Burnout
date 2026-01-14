class_name ZenEffect
extends EffectStrategy

## ZEN Effect: Creates a time window where cards played get reduced sanity toll
## - Sanity toll reduced by 1 for cards with negative sanity_toll (draining cards)
## - No reduction for cards with sanity_toll >= 0 (neutral or restoring cards)
## - Applies to any card that STARTS within the zen window

@export var zen_duration: float = 1.0

func apply_effect(context: GameContext) -> void:
	# Set the zen window starting from current time
	context.zen_start_time = context.current_time

	# Round zen duration to the nearest 0.5 hours
	var rounded_zen_duration = round(zen_duration * 2) / 2.0
	context.zen_end_time = context.current_time + rounded_zen_duration

	# Clamp to end of day (16:00)
	if context.schedule:
		var end_of_day = context.schedule.end_of_day
		if context.zen_end_time > end_of_day:
			context.zen_end_time = end_of_day

	print("  ZEN activated: ", context.zen_start_time, ":00 to ", context.zen_end_time, ":00")

	# Update schedule's zen window for visual overlay
	if context.schedule:
		context.schedule.zen_start_time = context.zen_start_time
		context.schedule.zen_end_time = context.zen_end_time
		context.schedule.queue_redraw()
