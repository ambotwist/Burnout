class_name DrawCardsToHandCommand
extends GameCommand

## Command to draw N cards from draw pile directly to hand
## Cards are created at draw pile position, reparented to hand, then animated into position

var num_cards: int


func _init(n: int) -> void:
	num_cards = n


func can_execute(game_manager: GameManager) -> bool:
	return game_manager != null and game_manager.card_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("DrawCardsToHandCommand: Cannot execute - missing game_manager or card_manager")
		return

	var card_manager = game_manager.card_manager
	var draw_pile = card_manager.draw_pile
	var hand = card_manager.hand

	var cards_drawn = 0
	for i in range(num_cards):
		# Check if hand is full
		if hand.is_full():
			print("  -> Cannot draw more cards - hand is full")
			break

		# Check if draw pile is empty
		if draw_pile.size() == 0:
			print("  -> Cannot draw more cards - draw pile is empty")
			break

		# Remove top card from draw pile
		var card_data = draw_pile.remove_top_card()

		# Assign unique game ID
		card_data.game_id = game_manager.card_id_counter
		game_manager.card_id_counter += 1

		# Create visual card node at draw pile scale
		var card_node = card_manager.create_card(card_data, draw_pile.cards_scale)
		hand.add_child(card_node)

		# Position at draw pile
		card_node.global_position = draw_pile.global_position

		# Add to hand
		hand.add_card(card_node)
		card_node.apply_card_data()

		# Play flip animation
		card_node.animation_player.play("flip")

		cards_drawn += 1

	# Update all hand positions to arrange cards in arc
	if cards_drawn > 0:
		card_manager.update_cards_hand_positions()
		print("  -> Drew ", cards_drawn, " card(s) to hand")
