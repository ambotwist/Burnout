class_name FindCardNodeCommand
extends GameCommand

## Command to find the Card node (visual) that corresponds to a CardData
## Searches through piles to find the visual representation
## Stores the found card_node in shared_data["card_node"]

func can_execute(game_manager: GameManager) -> bool:
	var card_data = get_shared_data("card_data")
	return card_data != null and game_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("FindCardNodeCommand: Cannot find card - missing card_data or game_manager")
		return

	var card_data: CardData = get_shared_data("card_data")
	var card_node: Card = null

	# Search through hand
	if game_manager.card_manager.hand:
		card_node = _find_card_in_pile(game_manager.card_manager.hand, card_data)

	# If not found in hand, search draw pile
	if not card_node and game_manager.card_manager.draw_pile:
		card_node = _find_card_in_pile(game_manager.card_manager.draw_pile, card_data)

	# If not found in draw pile, search discard pile
	if not card_node and game_manager.discard_pile:
		card_node = _find_card_in_pile(game_manager.discard_pile, card_data)

	if card_node:
		# Store the found card node in shared_data
		set_shared_data("card_node", card_node)
		print("  → Found card node: ", card_data.strategy.card_id, " (game_id: ", card_data.game_id, ")")
	else:
		push_warning("FindCardNodeCommand: Could not find card node for CardData (game_id: ", card_data.game_id, ")")


## Helper to search for a Card node in a pile's cards array
func _find_card_in_pile(pile: Pile, target_data: CardData) -> Card:
	if not pile or not pile.cards:
		return null

	for card in pile.cards:
		if card is Card and card.card_data == target_data:
			return card

	return null
