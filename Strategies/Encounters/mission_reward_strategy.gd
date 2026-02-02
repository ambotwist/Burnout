class_name MissionRewardStrategy
extends Resource


func apply_reward(mission_data, game_manager) -> String:
	push_error("Must be implemented in subclass")
	return ""


func get_reward_description(mission_data) -> String:
	push_error("Must be implemented in subclass")
	return ""
