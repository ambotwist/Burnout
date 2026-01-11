class_name AnimateCardsToSelectionCommand
extends GameCommand

## Command to animate drawn cards from draw pile to selection UI positions
## Reads cards from shared_data["drawn_cards"] and selection_ui from shared_data["selection_ui"]
## Plays flip animation and animates all cards in parallel


func can_execute(game_manager: GameManager) -> bool:
	var drawn_cards = get_shared_data("drawn_cards", [])
	var selection_ui = get_shared_data("selection_ui")
	return drawn_cards.size() > 0 and selection_ui != null and game_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		print("  -> No cards to animate to selection")
		return

	var drawn_cards: Array = get_shared_data("drawn_cards", [])
	var selection_ui: CardSelectionUI = get_shared_data("selection_ui")

	# Calculate target positions from selection UI
	var positions = selection_ui.calculate_positions(drawn_cards.size())

	# Animate each card to its position in parallel
	var tweens: Array[Tween] = []
	for i in range(drawn_cards.size()):
		var card: Card = drawn_cards[i]
		var target_pos = positions[i]

		# Play flip animation
		if card.animation_player:
			card.animation_player.play("flip")

		# Convert global position to local position relative to CardManager
		var local_pos = game_manager.card_manager.to_local(target_pos)

		# Animate to position with selection UI scale
		var tween = game_manager.card_manager.move_card_to(
			card,
			local_pos,
			0.0,  # rotation
			selection_ui.card_scale,
			1.0   # full opacity
		)
		tweens.append(tween)

	# Wait for all animations to complete
	for tween in tweens:
		if tween:
			await tween.finished

	print("  -> Cards animated to selection positions")
