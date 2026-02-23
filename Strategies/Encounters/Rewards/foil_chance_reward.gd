class_name FoilChanceContinuousReward
extends ContinuousRewardStrategy

## Per-play reward: chance to foil a card when a tagged card is played.
## Foil doubles the card's base productivity permanently.

@export var required_tag: String = "ARCHIVE"
@export var foil_chance: float = 0.25


func on_card_played(card_data: CardData, mission_data, game_manager) -> String:
	# Only trigger for cards with the required tag
	if not card_data.strategy.has_tag(required_tag):
		return ""

	# Skip if already foil
	if card_data.is_foil:
		return ""

	# Roll for foil
	if randf() > foil_chance:
		return ""

	# Apply foil
	card_data.is_foil = true
	card_data.productivity += card_data.strategy.productivity
	print("  → FOIL: Card '", card_data.strategy.card_id, "' productivity doubled to ", card_data.productivity)
	return "FOIL! %s productivity doubled!" % card_data.strategy.get_title()
