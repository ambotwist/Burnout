extends Node2D
class_name GameManager

# Card interaction signals
signal card_drawn(card)
signal card_played(card)
signal card_discarded(card)

var input_manager
var card_manager
var deck
var hand
var schedule

# Schedule logic variables
var current_slot = 0


func _ready():
	input_manager = $"../InputManager"
	card_manager = $"../CardManager"
	deck = $"../Deck"
	hand = $"../Hand"
	schedule = $"../ControlParent/Schedule"

	setup_signal_connections()
	deal_cards()


func setup_signal_connections():
	# Connect to InputManager signals
	input_manager.left_mouse_button_pressed.connect(on_left_mouse_button_pressed)
	input_manager.left_mouse_button_released.connect(on_left_mouse_button_released)
	card_manager.card_used.connect(on_card_used)


func on_left_mouse_button_pressed(raycast_result):
	if raycast_result is Card:
		card_manager.hold_card(raycast_result)


func on_left_mouse_button_released():
	card_manager.release_card()


func deal_cards():
	# wait 1 second before dealing cards
	await get_tree().create_timer(1.0).timeout
	for i in range(5):
		deck.draw_card()
		await get_tree().create_timer(0.1).timeout


func on_card_used(card):
	hand.remove_card_from_hand(card)

	# Random slot size (1-4) and color
	var random_size = randi_range(1, 4)
	var colors = ["red", "yellow", "blue"]
	var random_color = colors[randi() % colors.size()]

	schedule.fill_slot(random_color, random_size)
	current_slot += 1
	deck.draw_card()
