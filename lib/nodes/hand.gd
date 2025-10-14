extends Pile
class_name Hand

var card_positions: Dictionary = {} # Dictionary to keep track of card positions in hand


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

# Updates the positions and layout of the cards in hand
func update_cards_hand_positions() -> void:
	card_positions.clear()
	for i in cards.size():
		var card = cards.get(i)
		card_positions.set(card, i)
		var card_position = calculate_card_position(card)
		var card_rotation = calculate_card_rotation(card)
		card.z_index = i + 1
		card_manager.move_card_to(card, card_position, card_rotation, false)


# Calculates the position of the given card inside the hand
func calculate_card_position(card: Card) -> Vector2:
	var card_count = cards.size()
	if card_count == 1:
		Vector2(0, 0)
	
	# Calculate the position of the card at the given index
	var card_overlap = GameConstants.CARD_SCALED_WIDTH * 0.7
	var total_width = (card_count - 1) * card_overlap
	var start_x = 0 - total_width / 2
	var x_position = start_x + card_positions.get(card) * card_overlap

	# Create upward curve using a parabola
	var curve_height = 30
	var normalized_pos = (card_positions.get(card) - (card_count - 1) / 2.0) / max(1, (card_count - 1) / 2.0)
	var y_offset = -curve_height * (1 - normalized_pos * normalized_pos)
	var y_position = y_offset + position.y

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
