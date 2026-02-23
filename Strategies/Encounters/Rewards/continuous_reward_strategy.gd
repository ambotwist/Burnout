class_name ContinuousRewardStrategy
extends Resource

## Base class for per-play rewards that trigger on each card play during a mission.
## Override on_card_played() in subclasses. Return description text if triggered, empty string if not.

func on_card_played(card_data: CardData, mission_data, game_manager) -> String:
	return ""
