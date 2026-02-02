class_name DeckTypeGoal
extends MissionGoalStrategy

@export var deck_type: GameEnums.DeckType = GameEnums.DeckType.ADMIN


func get_progress(mission_data) -> int:
	return mission_data.deck_cards_played.get(deck_type, 0)
