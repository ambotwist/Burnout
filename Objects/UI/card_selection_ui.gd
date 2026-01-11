class_name CardSelectionUI
extends Node2D

## Reusable UI component for displaying cards and capturing player selection
## Used by PlanningEffect and can be reused for Scry, Mulligan, Tutor effects
## Handles its own input independently of InputManager.interactions_enabled

signal selection_completed(selected_cards: Array, unselected_cards: Array)

## Visual parameters
@export var card_spacing: float = 220.0
@export var card_scale: float = 0.8
@export var selection_offset_y: float = -40.0

## Internal state
var displayed_cards: Array[Card] = []
var selected_cards: Array[Card] = []
var cards_to_select: int = 1
var selection_active: bool = false

@onready var background: ColorRect = $Background
@onready var cards_container: Node2D = $CardsContainer
@onready var instruction_label: Label = $InstructionLabel


func _ready() -> void:
	# Hide by default until setup is called
	visible = false


## Handle input directly (independent of InputManager.interactions_enabled)
func _input(event: InputEvent) -> void:
	if not selection_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_card = _get_card_at_position(get_global_mouse_position())
		if clicked_card:
			_toggle_card_selection(clicked_card)
			get_viewport().set_input_as_handled()


## Find which card (if any) is at the given position
func _get_card_at_position(pos: Vector2) -> Card:
	# Check cards in reverse order (highest z_index first)
	var cards_by_z = displayed_cards.duplicate()
	cards_by_z.sort_custom(func(a, b): return a.z_index > b.z_index)

	for card in cards_by_z:
		if not card or not is_instance_valid(card):
			continue

		# Get the card's collision shape bounds
		if card.has_node("Node2D/Area2D/CollisionShape2D"):
			var collision_shape = card.get_node("Node2D/Area2D/CollisionShape2D")
			if collision_shape.shape is RectangleShape2D:
				var rect_shape = collision_shape.shape as RectangleShape2D
				var half_size = rect_shape.size / 2 * card.scale
				var card_pos = card.global_position

				# Check if point is within card bounds
				if pos.x >= card_pos.x - half_size.x and pos.x <= card_pos.x + half_size.x:
					if pos.y >= card_pos.y - half_size.y and pos.y <= card_pos.y + half_size.y:
						return card

	return null


## Setup the selection UI with cards to display
## cards: Array of Card nodes to display
## num_to_select: How many cards the player must select
func setup(cards: Array, num_to_select: int) -> void:
	displayed_cards.clear()
	selected_cards.clear()
	cards_to_select = num_to_select
	selection_active = true

	# Store and reparent cards to our container
	for card in cards:
		if card is Card:
			displayed_cards.append(card)
			# Reparent card to our container while preserving global position
			var global_pos = card.global_position
			card.reparent(cards_container)
			card.global_position = global_pos

	# Position cards in horizontal layout
	_position_cards()

	# Update instruction label
	_update_instruction_label()

	# Show the UI
	visible = true


## Calculate positions for cards in horizontal layout centered on screen
func calculate_positions(card_count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var viewport_size = get_viewport().get_visible_rect().size
	var center_x = viewport_size.x / 2
	var center_y = viewport_size.y / 2 - 100  # Slightly above center

	# Calculate total width of all cards
	var total_width = (card_count - 1) * card_spacing
	var start_x = center_x - total_width / 2

	for i in range(card_count):
		var x = start_x + i * card_spacing
		positions.append(Vector2(x, center_y))

	return positions


func _position_cards() -> void:
	var positions = calculate_positions(displayed_cards.size())

	for i in range(displayed_cards.size()):
		var card = displayed_cards[i]
		card.global_position = positions[i]
		card.scale = Vector2(card_scale, card_scale)
		card.rotation = 0.0
		card.modulate.a = 1.0
		card.z_index = i + 1


func _toggle_card_selection(card: Card) -> void:
	if card in selected_cards:
		# Deselect card
		selected_cards.erase(card)
		_update_card_visual(card, false)
	else:
		# Check if we can select more cards
		if selected_cards.size() < cards_to_select:
			selected_cards.append(card)
			_update_card_visual(card, true)

	_update_instruction_label()

	# Check if selection is complete
	if selected_cards.size() == cards_to_select:
		_complete_selection()


func _update_card_visual(card: Card, is_selected: bool) -> void:
	if is_selected:
		# Move card up and add highlight
		card.position.y += selection_offset_y
		card.modulate = Color(1.2, 1.2, 1.0, 1.0)  # Slight yellow tint
		card.z_index += 10
	else:
		# Reset card position and appearance
		card.position.y -= selection_offset_y
		card.modulate = Color(1.0, 1.0, 1.0, 1.0)
		card.z_index -= 10


func _update_instruction_label() -> void:
	var remaining = cards_to_select - selected_cards.size()
	if remaining == 1:
		instruction_label.text = "Select 1 card"
	else:
		instruction_label.text = "Select %d cards" % remaining


func _complete_selection() -> void:
	selection_active = false

	# Build unselected cards array
	var unselected: Array = []
	for card in displayed_cards:
		if card not in selected_cards:
			unselected.append(card)

	# Convert selected_cards to regular Array for signal
	var selected_array: Array = []
	for card in selected_cards:
		selected_array.append(card)

	# Emit completion signal
	selection_completed.emit(selected_array, unselected)


## Cleanup resources when done
func cleanup() -> void:
	selection_active = false
	displayed_cards.clear()
	selected_cards.clear()
