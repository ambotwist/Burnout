class_name Hand
extends Pile

var card_positions: Dictionary = {}

@export var max_cards: int = 3
func _ready() -> void:
	super._ready()

	# Connect to game state change signal to update card displays
	Events.game_state_changed.connect(_on_game_state_changed)

func is_full() -> bool:
	return cards.size() >= max_cards


func calculate_card_position(card: Card) -> Vector2:
	var card_count = cards.size()
	if card_count == 1:
		return Vector2(0, 0)

	# Adjust overlap based on card scale
	var card_overlap = Card.card_width * cards_scale * 0.7
	var total_width = (card_count - 1) * card_overlap
	var start_x = 0 - total_width / 2
	var x_position = start_x + card_positions.get(card) * card_overlap

	# Create upward curve using a parabola
	var curve_height = 30
	var normalized_pos = (card_positions.get(card) - (card_count - 1) / 2.0) / max(1, (card_count - 1) / 2.0)
	var y_offset = -curve_height * (1 - normalized_pos * normalized_pos)
	var y_position = y_offset  # Cards are children of Hand, so use local coordinates

	return Vector2(x_position, y_position)


# Calculates the rotation of the card at the given index
func calculate_card_rotation(card: Card) -> float:
	var card_count = cards.size()
	if card_count == 1:
		return 0
	
	var max_rotation = deg_to_rad(7)
	var normalized_position = (card_positions.get(card) - (card_count - 1) / 2.0) / max(1, (card_count - 1) / 2.0)
	return normalized_position * max_rotation


func get_card_z_index(card: Card) -> int:
	if card_positions.has(card):
		return card_positions.get(card) + 1
	return 1


## Called when game state changes - updates all card displays with simulated values
func _on_game_state_changed(game_state: Dictionary) -> void:
	# Simulate and update each card in hand
	for card in cards:
		if not card is Card or not card.card_data:
			continue

		# Get base values from strategy
		var base_productivity = card.card_data.strategy.productivity
		var base_duration = card.card_data.strategy.duration
		var base_sanity_toll = card.card_data.strategy.sanity_toll

		# Simulate what values the card would have if played now
		var simulated = EffectSimulator.simulate_card_play(card.card_data, game_state)

		# Update the card's display with color coding
		card.update_display_with_preview(
			base_productivity,
			simulated.productivity,
			base_duration,
			simulated.duration,
			base_sanity_toll,
			simulated.sanity_toll
		)
