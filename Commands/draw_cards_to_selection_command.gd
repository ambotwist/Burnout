class_name DrawCardsToSelectionCommand
extends GameCommand

## Command to draw N cards from draw pile and create visuals for selection
## Cards are removed from draw pile and positioned at draw pile location
## Stores drawn cards in shared_data["drawn_cards"] for subsequent commands

var num_cards: int


func _init(n: int) -> void:
	num_cards = n


func can_execute(game_manager: GameManager) -> bool:
	return game_manager != null and game_manager.card_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("DrawCardsToSelectionCommand: Cannot execute - missing game_manager or card_manager")
		return

	var drawn_cards: Array[Card] = []
	var draw_pile = game_manager.card_manager.draw_pile

	# Draw up to num_cards (or however many are available)
	var actual_count = min(num_cards, draw_pile.size())

	if actual_count == 0:
		print("  -> No cards available to draw for selection")
		set_shared_data("drawn_cards", drawn_cards)
		return

	var selection_ui = get_shared_data("selection_ui")
	var card_scale = selection_ui.card_scale if selection_ui else 0.8

	for i in range(actual_count):
		var card_data = draw_pile.remove_top_card()

		# Assign unique game ID
		card_data.game_id = game_manager.card_id_counter
		game_manager.card_id_counter += 1

		# Create visual card node
		var card_node = game_manager.card_manager.create_card(card_data, card_scale)

		# Add as child of CardManager (global coordinates)
		game_manager.card_manager.add_child(card_node)

		# Position at draw pile initially
		card_node.global_position = draw_pile.global_position
		card_node.apply_card_data()

		# Keep card in interactable group for selection UI click detection
		# (selection UI will handle its own click logic)

		drawn_cards.append(card_node)

	# Store drawn cards for next command
	set_shared_data("drawn_cards", drawn_cards)

	print("  -> Drew ", actual_count, " cards for selection")
