class_name EncounterScheduler
extends RefCounted

## Schedules random encounter times during each day.
## Ensures at least one morning and one afternoon encounter.

# Scheduled encounter times for the current day (in schedule hours 8.0-16.0)
var scheduled_times: Array[float] = []

# Times already triggered this day
var triggered_times: Array[float] = []


## Schedule 2-3 encounters for a new day
func schedule_encounters_for_day() -> void:
	scheduled_times.clear()
	triggered_times.clear()

	var num_encounters = randi_range(2, 3)

	# At least one morning encounter (8.0-12.0)
	var morning_time = randf_range(8.5, 11.5)
	scheduled_times.append(morning_time)

	# At least one afternoon encounter (12.0-16.0)
	var afternoon_time = randf_range(12.5, 15.5)
	scheduled_times.append(afternoon_time)

	# Optional third encounter with minimum spacing
	if num_encounters == 3:
		var extra_time = randf_range(9.0, 15.0)
		# Ensure at least 1 hour spacing from other encounters
		var attempts = 0
		while attempts < 20 and (abs(extra_time - morning_time) < 1.0 or abs(extra_time - afternoon_time) < 1.0):
			extra_time = randf_range(9.0, 15.0)
			attempts += 1
		if attempts < 20:
			scheduled_times.append(extra_time)

	scheduled_times.sort()
	print("EncounterScheduler: Scheduled encounters at times: ", scheduled_times)


## Check if an encounter should trigger at the current time.
## Returns true if an encounter should fire (and marks it as triggered).
func check_for_encounter(current_time: float) -> bool:
	for encounter_time in scheduled_times:
		if encounter_time in triggered_times:
			continue
		if current_time >= encounter_time:
			triggered_times.append(encounter_time)
			print("EncounterScheduler: Triggering encounter at time ", encounter_time)
			return true
	return false


## Reset for a new day
func reset() -> void:
	scheduled_times.clear()
	triggered_times.clear()
