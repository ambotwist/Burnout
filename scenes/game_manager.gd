extends Node2D
class_name GameManager


# Class references
var input_manager
var card_manager
var effect_controller
var deck
var hand
var schedule
var discard_pile

# UI variables
var mental_health_label
var productivity_label

# Card tracking
var playing_card: Card = null
var current_card_index = 0
var played_cards = []

var effect_queue: Array[Effect] = []
var draw_effects_buffer: Array[Effect] = []
var play_effects_buffer: Array[Effect] = []  # Effects waiting to modify played cards
var ticker_effects: Array[Effect] = []
var persistant_effects: Array[Effect] = []


### --- SETUP --- ####
func _ready():
	_setup_references()
	setup_signal_connections()

	# Register this GameManager instance with EffectDatabase
	EffectDatabase.set_game_manager(self)

	# Initialize GameState with default values (already set in GameState)
	# GameState starts with default values from its own initialization

	# Load the deck from DeckManager if available
	var selected_deck = DeckManager.get_deck()
	if selected_deck.size() > 0:
		set_starting_deck(selected_deck)

	update_ui()
	deal_cards()

# Sets up the references to the nodes
func _setup_references():
	input_manager = $"../InputManager"
	card_manager = $"../CardManager"
	deck = $"../Deck"
	hand = $"../Hand"
	schedule = $"../ControlParent/Schedule"
	mental_health_label = $"../ControlParent/Scores/MentalHealthScore"  
	productivity_label = $"../ControlParent/Scores/ProductivityScore" 
	discard_pile = $"../DiscardPile"

# Connects signals emitted from the input manager and card manager
func setup_signal_connections():
	input_manager.left_mouse_button_pressed.connect(on_left_mouse_button_pressed)
	input_manager.left_mouse_button_released.connect(on_left_mouse_button_released)
	card_manager.card_used.connect(play_card)


### --- DECK FUNCTIONS --- ####

func deal_cards():
	# wait 1 second before dealing cards
	await get_tree().create_timer(1.0).timeout
	for i in range(5):
		deck.draw_card(draw_effects_buffer)
		await get_tree().create_timer(0.1).timeout


# --- CARD FUNCTIONS --- ####

# Called when a card is used
func play_card(card):
	playing_card = card

	# Return if the card can't be played (prerequisites)
	if not playing_card.can_be_played():
		hand.snap_card_to_hand(playing_card)
		card_manager.dehighlight_card(playing_card)
		return

	# Apply any waiting play effects BEFORE checking schedule fit
	# This ensures duration modifiers work correctly
	var triggered_effects = []
	for effect in play_effects_buffer:
		if effect.prerequisite == null or effect.prerequisite.call():
			effect.target = playing_card
			effect.apply()  # Apply immediately to modify card stats
			triggered_effects.append(effect)
			# Check if it's a CardModifierEffect to access duration_modifier
			if effect is CardModifierEffect:
				print("Applied play effect to %s: duration modifier = %d" % [playing_card.card_name, effect.duration_modifier])

	# Remove triggered effects from buffer
	for triggered in triggered_effects:
		play_effects_buffer.erase(triggered)

	# NOW check if the card fits in the schedule (after modifiers)
	if playing_card.duration + GameState.current_time > 16:
		hand.snap_card_to_hand(playing_card)
		card_manager.dehighlight_card(playing_card)
		return
	
	# Create the card effects
	var card_effects: Array[Effect] = EffectDatabase.call(playing_card.card_name)

	# Add card effect to effect queue
	effect_queue.append_array(card_effects)

	# Card is successfully being played - disable collision and clear highlight
	playing_card.collision_shape.disabled = true
	if card_manager.highlighted_card == playing_card:
		card_manager.highlighted_card = null

	# Add hold effects to effect queue
	for hand_card in hand.hand:
		# Skip if card was freed (safety check)
		if not is_instance_valid(hand_card):
			continue
		if hand_card.effect_types.has(Effect.Effect_Type.HOLD_EFFECT):
			var hand_card_effect = EffectDatabase.call(card.card_name)
			if hand_card_effect.can_play():
				effect_queue.append(hand_card_effect)
	
	# Add ticker effects to effect queue
	for ticker_effect in ticker_effects:
		if ticker_effect.can_play():
			effect_queue.append(ticker_effect)
			ticker_effect.ticker -= 1
	
	# Add persistant effects to effect queue
	for persistant_effect in persistant_effects:
		if persistant_effect.can_play():
			effect_queue.append(persistant_effect)
	
	# Process EQ
	process_effect_queue()

	# Store card data before freeing the card object
	var card_data = playing_card.get_card_data()
	played_cards.append(card_data)
	current_card_index += 1

	# Remove the card from the hand
	hand.remove_card_from_hand(playing_card)

	# Get the position in the schedule where the card should go
	var slot_size = playing_card.duration
	var slot_color = playing_card.color if playing_card.color else "red"
	var target_position = schedule.get_slot_position(slot_size)

	# Animate the card to the schedule position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(playing_card, "global_position", target_position, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(playing_card, "scale", Vector2(0.3, 0.3), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	fade_out_card(playing_card)

	# Free the card
	playing_card.queue_free()

	# Fill the schedule with the card (only if duration > 0)
	schedule.fill_slot(slot_color, slot_size)

	# Only increment slot and time if the card has duration
	if slot_size > 0:
		GameState.current_slot += 1
		# Update GameState with the card that was just played
		GameState.on_card_played(playing_card)
	else:
		# For duration 0 cards, still update some state but not time
		GameState.last_played_card = playing_card
		GameState.last_played_card_type = playing_card.color
		GameState.cards_played_today.append(playing_card.card_name)
		GameState.productivity_total += playing_card.productivity
		print("Played duration 0 card: ", playing_card.card_name, " -> Productivity: +", playing_card.productivity)

	if slot_size > 0:
		print("Card played: ", playing_card.card_name, " -> Productivity: +", playing_card.productivity, " (Time: ", GameState.current_time, "/16)")

	# End of turn
	playing_card = null
	update_ui()
	deck.draw_card(draw_effects_buffer) 


func process_effect_queue():
	for effect in effect_queue:
		if effect.can_play():
			await effect.apply()
			effect_queue.erase(effect)


func discard_card(card: Card) -> void:
	# Remove from hand first if it's there
	hand.remove_card_from_hand(card)

	card_manager.animate_card_to_position_and_rotation(card, discard_pile.position, 0.0)
	discard_pile.pile.append(card.get_card_data())
	await fade_out_card(card)
	card.queue_free()


func add_card_to_game(card: Card) -> void:
	card.position = get_viewport().size / 2
	card_manager.add_child(card)


### --- UI FUNCTIONS --- ####

# Updates the UI
func update_ui() -> void:
	productivity_label.text = "Productivity: " + str(GameState.productivity_total)


func fade_out_card(card: Card) -> void:
	# Fade out the card
	var fade_tween = create_tween()
	fade_tween.tween_property(card, "modulate:a", 0.0, 0.2)
	await fade_tween.finished


### --- PROCESSING --- ####

# Called when the left mouse button is pressed
func on_left_mouse_button_pressed(raycast_result):
	if raycast_result is Card:
		card_manager.hold_card(raycast_result)


# Called when the left mouse button is released
func on_left_mouse_button_released():
	card_manager.release_card()


### --- HELPER FUNCTIONS --- ####

func get_last_played_card():
	if current_card_index == 0:
		return null
	if played_cards.size() > 0:
		return played_cards[current_card_index - 1]
	else:
		return null

# Gets the number of played cards
func get_played_cards_count() -> int:
	return played_cards.size()


# Gets the total duration of played cards
func get_total_duration_played() -> int:
	var total = 0
	for card in played_cards:
		total += card.duration
	return total


# Sets the starting deck from the deck composition screen
func set_starting_deck(deck_data: Array) -> void:
	print("Setting starting deck with %d cards" % deck_data.size())

	# Clear the existing deck
	deck.deck.clear()

	# Populate the deck with card names from the deck_data
	for card_info in deck_data:
		deck.deck.append(card_info.card_name)
		print("  - Added %s to deck" % card_info.card_name)

	print("Deck now has %d cards" % deck.deck.size())
