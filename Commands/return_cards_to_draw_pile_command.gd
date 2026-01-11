class_name ReturnCardsToDrawPileCommand
extends GameCommand

## Command to animate unselected cards back to draw pile and optionally shuffle
## Reads cards from shared_data["unselected_cards"]
## Cards are added back to draw pile and their visual nodes are freed

var should_shuffle: bool


func _init(shuffle: bool = true) -> void:
	should_shuffle = shuffle


func can_execute(game_manager: GameManager) -> bool:
	return game_manager != null and game_manager.card_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("ReturnCardsToDrawPileCommand: Cannot execute - missing game_manager")
		return

	var unselected_cards: Array = get_shared_data("unselected_cards", [])
	var draw_pile = game_manager.card_manager.draw_pile

	if unselected_cards.is_empty():
		print("  -> No unselected cards to return")
		return

	# Animate each card back to draw pile
	for card in unselected_cards:
		if not card or not is_instance_valid(card):
			continue

		# Reparent to CardManager if needed for consistent animation
		if card.get_parent() != game_manager.card_manager:
			var global_pos = card.global_position
			card.reparent(game_manager.card_manager)
			card.global_position = global_pos

		# Play flip animation (face down)
		if card.animation_player:
			card.animation_player.play("flip")

		# Animate to draw pile (fade out)
		var local_pos = game_manager.card_manager.to_local(draw_pile.global_position)
		var tween = game_manager.card_manager.move_card_to(
			card,
			local_pos,
			0.0,  # rotation
			draw_pile.cards_scale,
			0.0   # fade out
		)

		await tween.finished

		# Add card_data back to draw pile
		draw_pile.add_card(card.card_data)

		# Free the visual node
		card.queue_free()

	# Shuffle draw pile if requested
	if should_shuffle:
		draw_pile.shuffle()
		print("  -> Draw pile shuffled")

	print("  -> Returned ", unselected_cards.size(), " cards to draw pile")
