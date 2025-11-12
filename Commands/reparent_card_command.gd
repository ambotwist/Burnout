class_name ReparentCardCommand
extends GameCommand

## Command to reparent a card from its current parent to CardManager
## This is necessary before animating cards across different coordinate spaces
## Preserves the card's global position during the reparent operation

func can_execute(game_manager: GameManager) -> bool:
	var card_node = get_shared_data("card_node")
	return card_node != null and is_instance_valid(card_node) and game_manager != null and game_manager.card_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("ReparentCardCommand: Cannot reparent - missing card_node or game_manager")
		return

	var card_node: Card = get_shared_data("card_node")

	# Only reparent if not already a child of CardManager
	if card_node.get_parent() != game_manager.card_manager:
		var current_global_pos = card_node.global_position
		card_node.reparent(game_manager.card_manager)
		card_node.global_position = current_global_pos  # Preserve position during reparent
		print("  → Card reparented to CardManager")
	else:
		print("  → Card already child of CardManager")
