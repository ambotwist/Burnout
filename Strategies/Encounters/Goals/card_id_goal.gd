class_name CardIdGoal
extends MissionGoalStrategy

@export var target_card_id: String = ""


func get_progress(mission_data) -> int:
	return mission_data.card_id_plays.get(target_card_id, 0)
