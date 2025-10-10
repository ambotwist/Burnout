extends Node2D
class_name CardManager


### --- FIELDS --- ###

# Signals
signal card_used(card)

# UI variables
var screen_size

# Class references
var hand: Hand
var input_manager: InputManager
var drop_zone: Panel

var card_db

# Card logic variables
var held_card: Card = null
var highlighted_card: Card = null
var in_drop_zone = false

# Exportable variables
@export var highlight_scale: float = 1.3 + 0.3



### --- INITIALIZATION --- ####

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_db = preload("res://scripts/card_database.gd")
	hand = $"../Hand"
	input_manager = $"../InputManager"
	drop_zone = $"../ControlParent/DropZone"
	screen_size = get_viewport_rect().size
	highlight_scale = GameConstants.CARD_SCRIPT_SCALE + 0.3


# Connects signals emitted from the cards
func connect_card_signals(card):
	card.mouse_entered_card.connect(on_mouse_entered_card)
	card.mouse_exited_card.connect(on_mouse_exited_card)


### --- CARD ACTIONS --- ###

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# Update the held card's position 
	if held_card:
		drag_card(held_card)


# Called when card starts being held
func hold_card(card):
	held_card = card
	fade_in_drop_zone()

# Called when currently held card is released
func release_card():
	if held_card:
		var released_card = held_card
		if in_drop_zone:
			# Card is being used - emit signal but don't disable yet
			# The GameManager will handle whether the card can actually be played
			card_used.emit(held_card)
			held_card = null
			fade_out_drop_zone()
			# Don't clear highlighted_card here - let it be handled naturally
			# when the card is either played or returned to hand
			return
		else:
			# Check immediately if cursor is over the released card
			var card_under_cursor = input_manager.raycast()
			if released_card == highlighted_card and card_under_cursor == released_card:
				# Card should stay highlighted, animate directly to highlighted position
				var card_pos = hand.calculate_card_position(released_card.hand_position)
				hand.animate_card_to_position_and_rotation(released_card,
					Vector2(card_pos.x, card_pos.y - 30), 0)
				# Still need delayed check in case cursor moves away after release
				get_tree().create_timer(0.12).timeout.connect(func():
					# Check if card still exists before accessing it
					if is_instance_valid(released_card):
						var delayed_card_under_cursor = input_manager.raycast()
						if released_card == highlighted_card and delayed_card_under_cursor != released_card:
							dehighlight_card(released_card)
				)
			else:
				# Normal snap back to hand
				hand.snap_card_to_hand(held_card)
				# Wait for snap animation to complete, then check if cursor moved over the card
				get_tree().create_timer(0.12).timeout.connect(func():
					# Check if card still exists before accessing it
					if is_instance_valid(released_card):
						var delayed_card_under_cursor = input_manager.raycast()
						if released_card == highlighted_card and delayed_card_under_cursor != released_card:
							dehighlight_card(released_card)
				)

		# Clean up for cards returned to hand
		held_card = null
		fade_out_drop_zone()


# --- CARD GESTURES ---

# Drags given card with the mouse cursor
func drag_card(card):
	var mouse_position = get_global_mouse_position()
	card.global_position = Vector2(
		clamp(mouse_position.x, 0, screen_size.x),
		clamp(mouse_position.y, 0, screen_size.y))


# Defines card behavior when the cursor hovers over it
func on_mouse_entered_card(card):
	# Highlight card under cursor if no card is being held
	if not held_card:
		highlight_card(card)	


# Defines behavior when the cursor exits the card area
func on_mouse_exited_card(card):
	# Dehighlight card if it was highlighted AND not currently being held
	if card == highlighted_card and card != held_card:
		dehighlight_card(card)


# --- DECK FUNCTIONS ---


# --- DROP ZONE FUNCTIONS ----

# Detects if mouse is over the drop zone
func _on_drop_zone_mouse_entered() -> void:
	in_drop_zone = true


# Detects if mouse exited the drop zone
func _on_drop_zone_mouse_exited() -> void:
	in_drop_zone = false


### --- ANIMATIONS --- ###

# Highlights given card
func highlight_card(card: Card):
	# Dehighlight previous card first
	if highlighted_card and highlighted_card != card:
		dehighlight_card(highlighted_card)

	# Set as new highlighted card
	highlighted_card = card
	highlighted_card.z_index = 100

	# Grow card
	highlighted_card.scale = Vector2(highlight_scale, highlight_scale)

	# Animate card based on whether it's in hand or standalone
	if highlighted_card.hand_position != null:
		# Hand card: straighten and move up
		var card_pos = hand.calculate_card_position(highlighted_card.hand_position)
		hand.animate_card_to_position_and_rotation(highlighted_card,
			Vector2(card_pos.x, card_pos.y - 30), 0)
	else:
		# Standalone card (like insight cards): move up from base position
		if highlighted_card.base_position == null:
			highlighted_card.base_position = highlighted_card.position
		animate_card_to_position_and_rotation(highlighted_card,
			highlighted_card.base_position + Vector2(0, -30), 0)


# De-highlights given card
func dehighlight_card(card: Card):
	if highlighted_card == card:
		card.scale = Vector2(GameConstants.CARD_SCRIPT_SCALE, GameConstants.CARD_SCRIPT_SCALE)

		# Restore card position based on whether it's in hand or standalone
		if card.hand_position != null:
			# Hand card: snap back to hand position
			hand.snap_card_to_hand(card)  # This will restore the proper z-index
		else:
			# Standalone card: move back to base position
			if card.base_position != null:
				animate_card_to_position_and_rotation(card, card.base_position, 0)
			card.z_index = 0  # Reset z-index for standalone cards

		highlighted_card = null

		# Check if we hovered straight from one card to another
		var new_card = input_manager.raycast()
		if new_card is Card and new_card != card:
			highlight_card(new_card)


# Fades in the drop zone when holding a card
func fade_in_drop_zone():
	var tween = create_tween()
	tween.tween_property(drop_zone, "modulate:a", 1.0, 0.3)


# Fades out the drop zone when releasing a card
func fade_out_drop_zone():
	var tween = create_tween()
	tween.tween_property(drop_zone, "modulate:a", 0.0, 0.3)


# Animates the card to the given position and rotation
func animate_card_to_position_and_rotation(card, card_position, card_rotation):
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(card, "position", card_position, 0.1)
	tween.parallel().tween_property(card, "rotation", card_rotation, 0.1)
	# When the animation finishes, set the card as interactable
	tween.finished.connect(func():
		# Check if card still exists (hasn't been freed)
		if is_instance_valid(card) and card.collision_shape:
			card.collision_shape.disabled = false)
