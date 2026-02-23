class_name TagPlayCountGoal
extends MissionGoalStrategy

@export var required_tag: String = "ARCHIVE"


func get_progress(mission_data) -> int:
	return mission_data.tag_plays.get(required_tag, 0)


func get_progress_text(mission_data) -> String:
	# Maximize objective — show count only, no denominator
	return str(get_progress(mission_data))
