class_name FoilSummaryReward
extends MissionRewardStrategy

## Week-end reward for the Quarterly Archiving mission.
## No additional mechanical reward — the Foil gains during the week ARE the reward.
## This just returns descriptive summary text.


func apply_reward(mission_data, _game_manager) -> String:
	var archive_plays = mission_data.tag_plays.get("ARCHIVE", 0)
	return "Archived %d times this week. Any foiled cards keep their bonus!" % archive_plays


func get_reward_description(_mission_data) -> String:
	return "Cards foiled during the week keep their doubled productivity."
