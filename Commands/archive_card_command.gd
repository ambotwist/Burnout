class_name ArchiveCardCommand
extends GameCommand

## Archives a card: adds to discard pile, generates productivity immediately, and tracks as archived.
## Archive = Discard + Generate Productivity + Track for future bonuses (e.g., DOSSIER_PERSISTANT)


func can_execute(game_manager: GameManager) -> bool:
	var card_data = get_shared_data("card_data")
	return card_data != null and game_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("ArchiveCardCommand: Cannot execute - missing card_data or game_manager")
		return

	var card_data: CardData = get_shared_data("card_data")
	var card_node: Card = get_shared_data("card_node")

	# 1. Add to discard pile
	game_manager.discard_pile.add_card(card_data)

	# 2. Generate productivity immediately
	game_manager.total_productivity += card_data.productivity
	game_manager.update_productivity_label()

	# 3. Spawn floating text showing archived productivity
	if game_manager.floating_text_scene and game_manager.floating_text_spawn_point:
		var floating_text = game_manager.floating_text_scene.instantiate()
		game_manager.get_tree().current_scene.add_child(floating_text)
		floating_text.setup(card_data.productivity, game_manager.floating_text_spawn_point.global_position)

	# 4. Track as archived (for DOSSIER_PERSISTANT and future archive bonuses)
	if not game_manager.archived_cards.has(card_data):
		game_manager.archived_cards.append(card_data)

	# 5. Emit archive event (for CENTRE_ARCHIVE to react while in hand)
	Events.card_archived.emit(card_data)

	# 6. Clean up visual node
	if card_node and is_instance_valid(card_node):
		card_node.queue_free()

	print("  -> Card archived: ", card_data.strategy.card_id, " (+", card_data.productivity, " productivity)")
