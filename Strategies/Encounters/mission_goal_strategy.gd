class_name MissionGoalStrategy
extends Resource

@export var target_amount: int = 20


func get_progress(mission_data) -> int:
	push_error("Must be implemented in subclass")
	return 0


func is_completed(mission_data) -> bool:
	return get_progress(mission_data) >= target_amount


func get_progress_text(mission_data) -> String:
	return str(get_progress(mission_data)) + "/" + str(target_amount)
