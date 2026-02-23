class_name CardRemovalAndSanityReward
extends MissionRewardStrategy

@export var sanity_gain: int = 5
@export var cards_to_remove: int = 1


func apply_reward(mission_data, game_manager) -> String:
	# Phase 1: Immediate sanity gain
	game_manager.current_sanity = clamp(
		game_manager.current_sanity + sanity_gain, 0, game_manager.max_sanity)
	# Flag for Phase 2 (async card removal handled by GameManager)
	game_manager.pending_card_removals += cards_to_remove
	return "+%d Sanity. Choose %d card(s) to remove from your deck." % [sanity_gain, cards_to_remove]


func get_reward_description(_mission_data) -> String:
	return "Remove %d card from your deck + Gain %d Sanity" % [cards_to_remove, sanity_gain]
