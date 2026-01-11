class_name AddSelectedCardsToPileCommand
extends GameCommand

## Command to move selected cards to a destination pile
## Supports HAND (add to hand) or SCHEDULE (play immediately)
## Reads cards from shared_data["selected_cards"]

var destination_pile_type: GameEnums.PileType


func _init(destination: GameEnums.PileType) -> void:
	destination_pile_type = destination


func can_execute(game_manager: GameManager) -> bool:
	return game_manager != null and game_manager.card_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("AddSelectedCardsToPileCommand: Cannot execute - missing game_manager")
		return

	var selected_cards: Array = get_shared_data("selected_cards", [])

	if selected_cards.is_empty():
		print("  -> No selected cards to add")
		return

	match destination_pile_type:
		GameEnums.PileType.HAND:
			await _add_cards_to_hand(game_manager, selected_cards)
		GameEnums.PileType.SCHEDULE:
			await _play_cards_to_schedule(game_manager, selected_cards)
		_:
			push_error("AddSelectedCardsToPileCommand: Unsupported destination: ", destination_pile_type)


func _add_cards_to_hand(game_manager: GameManager, cards: Array) -> void:
	var hand = game_manager.card_manager.hand

	for card in cards:
		if not card or not is_instance_valid(card):
			continue

		# Check if hand is full
		if hand.is_full():
			print("  -> Hand is full, cannot add more cards")
			# Add remaining cards back to draw pile
			game_manager.card_manager.draw_pile.add_card(card.card_data)
			card.queue_free()
			continue

		# Reparent card from selection UI container to CardManager first
		if card.get_parent() != game_manager.card_manager:
			var global_pos = card.global_position
			card.reparent(game_manager.card_manager)
			card.global_position = global_pos

		# Re-enable card interaction
		card.add_to_group("interactable")
		if card.has_node("Node2D/Area2D/CollisionShape2D"):
			card.get_node("Node2D/Area2D/CollisionShape2D").disabled = false

		# Reparent from CardManager to Hand
		var current_global_pos = card.global_position
		card.reparent(hand)
		card.global_position = current_global_pos

		# Add to hand's card array
		hand.add_card(card)

	# Update all hand positions to arrange in arc
	game_manager.card_manager.update_cards_hand_positions()

	print("  -> Added ", cards.size(), " cards to hand")


func _play_cards_to_schedule(game_manager: GameManager, cards: Array) -> void:
	# Play each card to schedule (triggers full play flow)
	for card in cards:
		if not card or not is_instance_valid(card):
			continue

		# Reparent to CardManager for consistent animation
		if card.get_parent() != game_manager.card_manager:
			var global_pos = card.global_position
			card.reparent(game_manager.card_manager)
			card.global_position = global_pos

		# Check if card can be played (play prerequisites)
		if not game_manager.can_play_card(card):
			print("  -> Card cannot be played (prerequisites not met), adding to hand instead")
			await _add_single_card_to_hand(game_manager, card)
			continue

		# Trigger BEFORE_PLAY effects
		game_manager.trigger_card_effects(card, GameEnums.EffectTrigger.BEFORE_PLAY)

		# Apply focus reduction if active
		game_manager.apply_focus_reduction(card)

		# Get slot position and animate to schedule
		var slot_position = game_manager.schedule.get_slot_position(card.card_data.duration)
		await game_manager.card_manager.add_to_schedule(card, slot_position)

		# Fill schedule slot with color
		var slot_color = game_manager.schedule.get_card_color(card.card_data)
		game_manager.schedule.fill_slot(slot_color, card.card_data.duration)

		# Update scheduled cards
		game_manager.scheduled_cards.append(card.card_data)

		# Trigger ON_PLAY effects
		game_manager.trigger_card_effects(card, GameEnums.EffectTrigger.ON_PLAY)

		# Add productivity
		game_manager.total_productivity += card.card_data.productivity
		game_manager.update_productivity_label()

		# Update previous card
		game_manager.previous_card = card.card_data

		print("  -> Played card to schedule: ", card.card_data.strategy.card_id)

	# Emit game state changed
	Events.game_state_changed.emit(game_manager._build_game_state())


func _add_single_card_to_hand(game_manager: GameManager, card: Card) -> void:
	var hand = game_manager.card_manager.hand

	if hand.is_full():
		# Hand is full, add to draw pile instead
		game_manager.card_manager.draw_pile.add_card(card.card_data)
		card.queue_free()
		return

	# Re-enable interaction
	card.add_to_group("interactable")
	if card.has_node("Node2D/Area2D/CollisionShape2D"):
		card.get_node("Node2D/Area2D/CollisionShape2D").disabled = false

	# Reparent to hand
	var current_global_pos = card.global_position
	card.reparent(hand)
	card.global_position = current_global_pos

	# Add to hand
	hand.add_card(card)
	game_manager.card_manager.update_cards_hand_positions()
