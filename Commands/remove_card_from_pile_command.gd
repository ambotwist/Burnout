class_name RemoveCardFromPileCommand
extends GameCommand

## Command to remove a card from its current pile
## This is used before animating a card to a new location
## The card node stays alive, but is removed from the pile's cards array

func can_execute(game_manager: GameManager) -> bool:
	var card_node = get_shared_data("card_node")
	return card_node != null and is_instance_valid(card_node) and game_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("RemoveCardFromPileCommand: Cannot remove - missing card_node or game_manager")
		return

	var card_node: Card = get_shared_data("card_node")

	# Check which pile the card is in and remove it
	if _remove_from_pile(game_manager.card_manager.hand, card_node):
		print("  → Card removed from hand")
		# Update hand positions after removal
		game_manager.card_manager.update_cards_hand_positions()
	elif _remove_from_pile(game_manager.card_manager.draw_pile, card_node):
		print("  → Card removed from draw pile")
	elif _remove_from_pile(game_manager.discard_pile, card_node):
		print("  → Card removed from discard pile")
	else:
		push_warning("RemoveCardFromPileCommand: Card not found in any pile")


## Helper to remove a card from a pile's cards array
func _remove_from_pile(pile: Pile, card_node: Card) -> bool:
	if not pile or not pile.cards:
		return false

	var index = pile.cards.find(card_node)
	if index >= 0:
		pile.cards.remove_at(index)
		return true

	return false
