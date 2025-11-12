class_name GameContext
extends RefCounted

## The game context holds all state information needed for effects to make decisions
## This is passed to effects via dependency injection

# ========================================
# CARD REFERENCES
# ========================================

## The card that triggered this effect (CardData)
var self_card: CardData = null

## The Card node (visual representation) that triggered this effect
var self_card_node: Card = null

# ========================================
# PILE REFERENCES
# ========================================

## Reference to the hand pile
var hand: Hand = null

## Reference to the draw pile
var draw_pile: Pile = null

## Reference to the discard pile
var discard_pile: Pile = null

# ========================================
# SCHEDULE REFERENCES
# ========================================

## Reference to the schedule
var schedule: Schedule = null

## Current time in the schedule
var current_time: float = 0.0

## Time left in the schedule
var time_left: int = 0

## Cards currently placed in the schedule (Array[CardData])
var scheduled_cards: Array[CardData] = []

## Previous card played (CardData) - useful for "if played after X" effects
var previous_card: CardData = null

# ========================================
# FOCUS WINDOW
# ========================================

## Focus effect start time (in schedule hours, e.g., 9.5)
var focus_start_time: float = -1.0

## Focus effect end time (in schedule hours, e.g., 11.5)
var focus_end_time: float = -1.0

# ========================================
# COMMAND QUEUE
# ========================================

## Queue of commands to be executed after effects are applied
## Effects add commands here instead of directly modifying game state
var command_queue: Array[GameCommand] = []

# ========================================
# HELPER METHODS
# ========================================

## Get all cards across all piles as CardData
func get_all_cards() -> Array[CardData]:
	var all_cards: Array[CardData] = []

	# Add cards from hand
	if hand:
		for card in hand.cards:
			if card is Card and card.card_data:
				all_cards.append(card.card_data)

	# Add cards from draw pile
	if draw_pile:
		for card in draw_pile.cards:
			if card is Card and card.card_data:
				all_cards.append(card.card_data)

	# Add cards from discard pile
	if discard_pile:
		for card in discard_pile.cards:
			if card is Card and card.card_data:
				all_cards.append(card.card_data)

	# Add scheduled cards
	all_cards.append_array(scheduled_cards)

	return all_cards


## Get cards from a specific pile
func get_cards_in_pile(pile_type: GameEnums.PileType) -> Array[CardData]:
	match pile_type:
		GameEnums.PileType.HAND:
			return _get_card_data_from_pile(hand)
		GameEnums.PileType.DRAW:
			return _get_card_data_from_pile(draw_pile)
		GameEnums.PileType.DISCARD:
			return _get_card_data_from_pile(discard_pile)
		GameEnums.PileType.SCHEDULE:
			return scheduled_cards.duplicate()
		_:
			return []


## Helper to extract CardData from a Pile
func _get_card_data_from_pile(pile: Pile) -> Array[CardData]:
	var card_data_array: Array[CardData] = []
	if pile:
		for card in pile.cards:
			if card is Card and card.card_data:
				card_data_array.append(card.card_data)
	return card_data_array


## Get a preview position for visual effects based on position type
func get_preview_position(position_type: GameEnums.PreviewPosition, custom_pos: Vector2 = Vector2.ZERO) -> Vector2:
	match position_type:
		GameEnums.PreviewPosition.SCHEDULE_CENTER:
			if schedule:
				return schedule.get_global_rect().get_center()
			return Vector2.ZERO

		GameEnums.PreviewPosition.HAND_CENTER:
			if hand:
				return hand.get_global_rect().get_center()
			return Vector2.ZERO

		GameEnums.PreviewPosition.DRAW_PILE:
			if draw_pile:
				return draw_pile.global_position
			return Vector2.ZERO

		GameEnums.PreviewPosition.DISCARD_PILE:
			if discard_pile:
				return discard_pile.global_position
			return Vector2.ZERO

		GameEnums.PreviewPosition.CUSTOM:
			return custom_pos

		_:
			push_warning("Unknown PreviewPosition type: ", position_type)
			return Vector2.ZERO


## Create a context for when a specific card triggers an effect
static func create_for_card(card_node: Card, game_state: Dictionary = {}) -> GameContext:
	var context = GameContext.new()
	context.self_card = card_node.card_data if card_node else null
	context.self_card_node = card_node

	# Fill in game state from provided dictionary
	context.hand = game_state.get("hand")
	context.draw_pile = game_state.get("draw_pile")
	context.discard_pile = game_state.get("discard_pile")
	context.schedule = game_state.get("schedule")
	context.current_time = game_state.get("current_time", 0.0)
	context.time_left = game_state.get("time_left", 0)
	context.scheduled_cards = game_state.get("scheduled_cards", [])
	context.previous_card = game_state.get("previous_card")
	context.focus_start_time = game_state.get("focus_start_time", -1.0)
	context.focus_end_time = game_state.get("focus_end_time", -1.0)

	return context
