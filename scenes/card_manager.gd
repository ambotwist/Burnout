extends Node2D
class_name CardManager


### --- FIELDS --- ###

# Signals
signal card_used(card)

# UI variables
var screen_size

# Class references
var hand: Hand

# Card logic variables
var held_card
var highlighted_card: Card = null
var in_drop_zone = false

# Exportable variables
@export var highlight_scale: float = 1.3 + 0.3



### --- INITIALIZATION --- ####

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	highlight_scale = GameConstants.CARD_SCALE + 0.3
	hand = $"../Hand"


# Connects signals emitted from the cards
func connect_card_signals(card):
	card.mouse_entered_card.connect(on_mouse_entered_card)
	card.mouse_exited_card.connect(on_mouse_exited_card)


### --- PROCESSING --- ###

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# Update the held card's position 
	if held_card:
		drag_card(held_card)


func hold_card(card):
	held_card = card


func release_card():
	if held_card:
		if in_drop_zone:
			card_used.emit(held_card)
			hand.remove_card_from_hand(held_card)
			held_card.queue_free()
		else:
			hand.snap_card_to_hand(held_card)
		held_card = null


# --- CARD FUNCTIONS ---

# Drags given card with the mouse cursor
func drag_card(card):
	var mouse_position = get_global_mouse_position()
	card.position = Vector2(
		clamp(mouse_position.x, 0, screen_size.x), 
		clamp(mouse_position.y, 0, screen_size.y))


# Defines card behavior when the cursor hovers over it
func on_mouse_entered_card(card):
	# Highlight card under cursor if no card is being held
	if not held_card:
		highlight_card(card)	


# Defines behavior when the cursor exits the card area
func on_mouse_exited_card(card):
	# Dehighlight card if it was highlighted
	if card == highlighted_card:
		dehighlight_card(card)


# --- DECK FUNCTIONS ---


# --- DROP ZONE FUNCTIONS ----

# Detects if mouse is over the drop zone
func _on_drop_zone_mouse_entered() -> void:
	in_drop_zone = true


# Detects if mouse exited the drop zone
func _on_drop_zone_mouse_exited() -> void:
	in_drop_zone = false


### ANIMATIONS

# Highlights given card
func highlight_card(card: Card):
	# Dehighlight previous card first
	if highlighted_card and highlighted_card != card:
		dehighlight_card(highlighted_card)
		
	# Set as new highlighted card
	highlighted_card = card
	highlighted_card.z_index = 2
	
	# Grow card
	highlighted_card.scale = Vector2(highlight_scale, highlight_scale)
	
	# Move up card
	hand.animate_card_to_position(highlighted_card, 
		Vector2(
			hand.calculate_card_x_position(highlighted_card.hand_position),
			GameConstants.HAND_Y_POSITION - 30))


# De-highlights given card
func dehighlight_card(card: Card):
	if highlighted_card == card:
		card.z_index = 1
		card.scale = Vector2(GameConstants.CARD_SCALE, GameConstants.CARD_SCALE)
		hand.snap_card_to_hand(card)
		highlighted_card = null
	## Check if we hovered straight from one card to another
	#var new_card = raycast()
	#if new_card is Card and new_card != card:
		#highlight_card(new_card)
