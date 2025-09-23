extends Node2D
class_name Hand

var center_screen_x
var hand = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2


# Adds given card to the hand
func add_card_to_hand(card):
	hand.insert(0, card)
	update_hand_positions()


# Snaps back given card back to hand
func snap_card_to_hand(card):
	var card_pos = calculate_card_position(card.hand_position)
	var card_rotation = calculate_card_rotation(card.hand_position)
	# Restore proper z-index based on hand position
	card.z_index = hand.size() - card.hand_position
	animate_card_to_position_and_rotation(card, card_pos, card_rotation)


# Removes given card from the hand
func remove_card_from_hand(card):
	if card in hand:
		hand.erase(card)
		update_hand_positions()


# Updates the positions of all cards in the hand
func update_hand_positions():
	for i in hand.size():
		var card_pos = calculate_card_position(i)
		var card_rotation = calculate_card_rotation(i)
		var card = hand[i]
		card.hand_position = i
		# Set z-index: leftmost card (index 0) has highest z-index
		card.z_index = hand.size() - i
		animate_card_to_position_and_rotation(card, card_pos, card_rotation)


# Calculates the position of the card at the given index
func calculate_card_position(index):
	var card_count = hand.size()
	if card_count == 1:
		return Vector2(center_screen_x, GameConstants.HAND_Y_POSITION)

	# Calculate the position of the card at the given index
	var card_overlap = GameConstants.CARD_SCALED_WIDTH * 0.7
	var total_width = (card_count - 1) * card_overlap
	var start_x = center_screen_x - total_width / 2
	var x_position = start_x + index * card_overlap

	# Create upward curve using a parabola
	var curve_height = 30
	var normalized_pos = (index - (card_count - 1) / 2.0) / max(1, (card_count - 1) / 2.0)
	var y_offset = -curve_height * (1 - normalized_pos * normalized_pos)
	var y_position = GameConstants.HAND_Y_POSITION + y_offset

	return Vector2(x_position, y_position)


# Calculates the rotation of the card at the given index
func calculate_card_rotation(index):
	var card_count = hand.size()
	if card_count == 1:
		return 0

	var max_rotation = deg_to_rad(7) 
	var normalized_pos = (index - (card_count - 1) / 2.0) / max(1, (card_count - 1) / 2.0)
	return normalized_pos * max_rotation


# Animates the card to the given position and rotation
func animate_card_to_position_and_rotation(card, card_position, card_rotation):
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(card, "position", card_position, 0.1)
	tween.parallel().tween_property(card, "rotation", card_rotation, 0.1)
	# When the animation finishes, set the card as interactable
	tween.finished.connect(func():
		card.collision_shape.disabled = false)
