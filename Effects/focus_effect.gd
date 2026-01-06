class_name FocusEffect
extends EffectStrategy

## FOCUS Effect: Creates a 2-hour time window where cards played get a duration reduction
## - Duration reduced by 1 slot (15 minutes) for cards with duration > 1
## - No reduction for cards with duration = 1 (already at minimum)
## - Applies to any card that STARTS within the focus window

@export var focus_duration: float = 1.0

func apply_effect(context: GameContext) -> void:
	# Set the focus window: 2 hours from current time
	context.focus_start_time = context.current_time
	
	# Round focus duration to the nearest 0.5 hours
	var rounded_focus_duration = round(focus_duration * 2) / 2.0
	context.focus_end_time = context.current_time + rounded_focus_duration

	# Clamp to end of day (16:00)
	if context.schedule:
		var end_of_day = context.schedule.end_of_day
		if context.focus_end_time > end_of_day:
			context.focus_end_time = end_of_day

	print("  FOCUS activated: ", context.focus_start_time, ":00 to ", context.focus_end_time, ":00")

	# Update schedule's focus window for visual overlay
	if context.schedule:
		context.schedule.focus_start_time = context.focus_start_time
		context.schedule.focus_end_time = context.focus_end_time
		context.schedule.queue_redraw()
