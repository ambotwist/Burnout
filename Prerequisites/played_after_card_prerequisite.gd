class_name PlayedAfterCardPrerequisite
extends PrerequisiteStrategy

## Checks if the previous card matches the target strategy filters
## Can be used for both card play validation and effect activation

@export var prerequisite_card: TargetStrategy

func is_satisfied(context: GameContext) -> bool:
	# Check if there is a previous card
	if not context.previous_card:
		return false

	# If no target strategy specified, any previous card satisfies
	if not prerequisite_card:
		return true

	# Check if previous card matches the target strategy filters
	# Check deck filter
	if prerequisite_card.target_deck != GameEnums.DeckType.ANY:
		if context.previous_card.strategy.deck != prerequisite_card.target_deck:
			return false

	# Check specific card ID filter
	if prerequisite_card.target_card != GameEnums.CardID.ANY and prerequisite_card.target_card != GameEnums.CardID.SELF:
		var card_id_string = GameEnums.CardID.keys()[prerequisite_card.target_card]
		if context.previous_card.strategy.card_id != card_id_string:
			return false

	# All filters passed
	return true
