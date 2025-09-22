extends Node2D
class_name Hand

var center_screen_x
var hand = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2


func add_card_to_hand(card):
	hand.insert(0, card)
	update_hand_positions()


# Snaps back given card back to hand
func snap_card_to_hand(card):
	animate_card_to_position(
		card,
		Vector2(calculate_card_x_position(card.hand_position), GameConstants.HAND_Y_POSITION))


func remove_card_from_hand(card):
	if card in hand:
		hand.erase(card)
		update_hand_positions()


func update_hand_positions():
	for i in hand.size():
		var new_position = Vector2(calculate_card_x_position(i), GameConstants.HAND_Y_POSITION)
		var card = hand[i]
		card.hand_position = i
		animate_card_to_position(card, new_position)


func calculate_card_x_position(index):
	var x_offset = (hand.size() - 1) * GameConstants.CARD_SCALED_WIDTH
	@warning_ignore("integer_division")
	var x_position =  center_screen_x + index * GameConstants.CARD_SCALED_WIDTH - x_offset / 2
	return x_position


func animate_card_to_position(card, card_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", card_position, 0.1)
	# When the animation finishes, set the card as interactable
	tween.finished.connect(func():
		card.collision_shape.disabled = false)
