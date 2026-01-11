class_name ArchiveBonusEffect
extends EffectStrategy

## Effect used by DOSSIER_PERSISTANT: adds permanent productivity bonus
## to each card that has been archived this game.
##
## The bonus is applied directly to CardData.productivity, making it
## permanent for the rest of the run (persists through reshuffles).

@export var productivity_bonus: int = 1


func apply_effect(context: GameContext) -> void:
	if context.archived_cards.is_empty():
		print("  -> No archived cards to buff")
		return

	for card_data in context.archived_cards:
		if card_data:
			card_data.productivity += productivity_bonus
			print("  -> Buffed archived card: ", card_data.strategy.card_id)

	print("  -> Applied +", productivity_bonus, " to ", context.archived_cards.size(), " archived card(s)")
