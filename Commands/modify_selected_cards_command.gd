class_name ModifySelectedCardsCommand
extends GameCommand

## Command to apply productivity/duration modifiers to selected cards
## Reads cards from shared_data["selected_cards"]
## Reusable for any effect that needs to modify cards after selection

var productivity_modifier: int
var duration_modifier: int


func _init(productivity_mod: int = 0, duration_mod: int = 0) -> void:
	productivity_modifier = productivity_mod
	duration_modifier = duration_mod


func can_execute(game_manager: GameManager) -> bool:
	return game_manager != null


func execute(game_manager: GameManager) -> void:
	var selected_cards: Array = get_shared_data("selected_cards", [])

	if selected_cards.is_empty():
		print("  -> No selected cards to modify")
		return

	for card in selected_cards:
		if not card or not is_instance_valid(card):
			continue

		if not card.card_data:
			continue

		# Store base values before modification (from strategy)
		var base_productivity = card.card_data.strategy.productivity
		var base_duration = card.card_data.strategy.duration
		var base_sanity_toll = card.card_data.strategy.sanity_toll

		# Apply productivity modifier
		if productivity_modifier != 0:
			var old_productivity = card.card_data.productivity
			card.card_data.productivity += productivity_modifier
			print("  -> Modified card productivity: ", old_productivity, " -> ", card.card_data.productivity)

		# Apply duration modifier
		if duration_modifier != 0:
			var old_duration = card.card_data.duration
			card.card_data.duration = max(1, card.card_data.duration + duration_modifier)
			print("  -> Modified card duration: ", old_duration, " -> ", card.card_data.duration)

		# Update the card's visual display with color coding (green for buff, red for debuff)
		# Sanity toll is unchanged by this command, so base and predicted are the same
		card.update_display_with_preview(
			base_productivity,
			card.card_data.productivity,
			base_duration,
			card.card_data.duration,
			base_sanity_toll,
			base_sanity_toll
		)

	print("  -> Modified ", selected_cards.size(), " selected card(s)")
