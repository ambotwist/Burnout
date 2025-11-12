class_name AddCardToPileCommand
extends GameCommand

## Command to add a card to a specific pile
## Handles both the data structure (adding CardData to pile) and visual cleanup (freeing Card node)
## Replaces the old AddCardToHandCommand with more flexibility

var destination_pile_type: GameEnums.PileType

func _init(pile: GameEnums.PileType) -> void:
	destination_pile_type = pile


func can_execute(game_manager: GameManager) -> bool:
	var card_data = get_shared_data("card_data")
	return card_data != null and game_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("AddCardToPileCommand: Cannot add to pile - missing card_data or game_manager")
		return

	var card_data: CardData = get_shared_data("card_data")
	var card_node: Card = get_shared_data("card_node")  # May be null if no visual was created

	# Handle special cases that don't use standard piles
	if destination_pile_type == GameEnums.PileType.SCHEDULE:
		_add_to_schedule(game_manager, card_data, card_node)
		print("  → Card added to pile: ", _get_pile_name(destination_pile_type), " (ID: ", card_data.game_id, ")")
		return

	# For standard piles (Hand, Discard, Draw), get pile reference
	var pile = _get_pile_reference(game_manager, destination_pile_type)

	if not pile:
		push_error("AddCardToPileCommand: Pile not found for type: ", destination_pile_type)
		return

	# Hand requires special handling
	if destination_pile_type == GameEnums.PileType.HAND:
		_add_to_hand(game_manager, card_data, card_node, pile)
	else:
		# Other piles: add data and free the visual node
		_add_to_other_pile(card_data, card_node, pile)

	print("  → Card added to pile: ", _get_pile_name(destination_pile_type), " (ID: ", card_data.game_id, ")")


## Add card to hand - card node persists and gets positioned in hand arc
func _add_to_hand(game_manager: GameManager, card_data: CardData, card_node: Card, hand: Hand) -> void:
	if not card_node or not is_instance_valid(card_node):
		push_error("AddCardToPileCommand: Cannot add to hand - card_node is required for hand")
		return

	# Re-enable interaction (was disabled during preview)
	card_node.add_to_group("interactable")
	if card_node.has_node("Node2D/Area2D/CollisionShape2D"):
		card_node.get_node("Node2D/Area2D/CollisionShape2D").disabled = false

	# Reparent card from CardManager to Hand
	var current_global_pos = card_node.global_position
	card_node.reparent(hand)
	card_node.global_position = current_global_pos  # Preserve position during reparent

	# Add to hand's card array and data array
	hand.add_card(card_node)

	# Update all hand positions to arrange in arc
	game_manager.card_manager.update_cards_hand_positions()


## Add card to schedule - fills visual slot, adds to scheduled_cards, updates productivity
func _add_to_schedule(game_manager: GameManager, card_data: CardData, card_node: Card) -> void:
	if not game_manager.schedule:
		push_error("AddCardToPileCommand: Schedule not found in game_manager")
		return

	# 1. Get next slot position based on card duration
	var slot_position = game_manager.schedule.get_slot_position(card_data.duration)

	# 2. Fill schedule visually with colored slot
	var slot_color = game_manager.schedule.get_card_color(card_data)
	game_manager.schedule.fill_slot(slot_color, card_data.duration)

	# 3. Add CardData to GameManager's scheduled_cards array
	game_manager.scheduled_cards.append(card_data)

	# 4. Update productivity
	game_manager.total_productivity += card_data.productivity
	game_manager.update_productivity_label()

	# 5. Update previous_card (for "played after X" effects)
	game_manager.previous_card = card_data

	# 6. Free the visual card node (schedule shows colored slots, not card nodes)
	if card_node and is_instance_valid(card_node):
		card_node.queue_free()


## Add card to non-hand pile - card data added, visual node freed
func _add_to_other_pile(card_data: CardData, card_node: Card, pile: Pile) -> void:
	# Add card data to the pile's array
	pile.add_card(card_data)

	# Clean up visual node if it exists (should be faded out already)
	if card_node and is_instance_valid(card_node):
		card_node.queue_free()


## Get the actual pile reference from game manager
func _get_pile_reference(game_manager: GameManager, pile_type: GameEnums.PileType) -> Pile:
	match pile_type:
		GameEnums.PileType.HAND:
			return game_manager.card_manager.hand
		GameEnums.PileType.DRAW:
			return game_manager.card_manager.draw_pile
		GameEnums.PileType.DISCARD:
			return game_manager.discard_pile
		_:
			push_error("AddCardToPileCommand: Unsupported pile type: ", pile_type)
			return null


## Helper for logging
func _get_pile_name(pile_type: GameEnums.PileType) -> String:
	match pile_type:
		GameEnums.PileType.HAND: return "HAND"
		GameEnums.PileType.DRAW: return "DRAW"
		GameEnums.PileType.DISCARD: return "DISCARD"
		GameEnums.PileType.SCHEDULE: return "SCHEDULE"
		_: return "UNKNOWN"
