extends Control

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var deck_counter_label: Label = $MarginContainer/VBoxContainer/DeckInfo/DeckCounter
@onready var ready_button: Button = $MarginContainer/VBoxContainer/ReadyButton

var card_scene = preload("res://lib/nodes/card.tscn")
var selected_cards: Dictionary = {}  # Track card counts: {card_key: count}
var max_deck_size: int = 30  # Maximum cards allowed in a deck
var card_counters: Dictionary = {}  # Track counter labels: {card_key: Label}


func _ready() -> void:
	# Adjust grid columns based on viewport width
	var viewport_width = get_viewport().get_visible_rect().size.x
	var columns = int(viewport_width / (GameConstants.CARD_SCALED_WIDTH + 20))  # 20 for padding
	grid_container.columns = max(2, columns)  # At least 2 columns

	# Setup ready button
	ready_button.disabled = true
	ready_button.pressed.connect(_on_ready_button_pressed)

	load_all_cards()


func load_all_cards() -> void:
	# Clear any existing cards
	for child in grid_container.get_children():
		child.queue_free()

	# Load all cards from the database
	for card_key in CardDatabase.CARDS:
		create_card_display(card_key)


func create_card_display(card_key: String) -> void:
	# Create a vertical container for the card and counter
	var vertical_container = VBoxContainer.new()
	vertical_container.custom_minimum_size = Vector2(GameConstants.CARD_SCALED_WIDTH, GameConstants.CARD_SCALED_HEIGHT + 30)
	vertical_container.alignment = BoxContainer.ALIGNMENT_CENTER

	# Create a container for the card to handle scaling properly
	var card_container = Control.new()
	var container_width = GameConstants.CARD_SCALED_WIDTH
	var container_height = GameConstants.CARD_SCALED_HEIGHT
	card_container.custom_minimum_size = Vector2(container_width, container_height)
	card_container.mouse_filter = Control.MOUSE_FILTER_STOP
	card_container.pivot_offset = card_container.custom_minimum_size / 2

	# Instantiate the card
	var card_instance = card_scene.instantiate()
	card_instance.assign_data(CardData.create_card_data_from_type(card_key))

	# Scale down the card for grid display (scale factor, not pixel dimensions)
	var scale_factor = GameConstants.CARD_SCALED_WIDTH / (GameConstants.CARD_WIDTH * GameConstants.CARD_EDITOR_SCALE)
	card_instance.scale = Vector2(scale_factor, scale_factor)

	# Center the card in its container
	card_instance.position = card_container.custom_minimum_size / 2

	# Disable card interactions for display purposes
	if card_instance.has_node("Area2D"):
		card_instance.get_node("Area2D").input_pickable = false

	# Add card to container
	card_container.add_child(card_instance)

	# Create horizontal container for counter controls
	var counter_container = HBoxContainer.new()
	counter_container.alignment = BoxContainer.ALIGNMENT_CENTER

	# Create minus button
	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(40, 40)
	minus_button.add_theme_font_size_override("font_size", 24)
	minus_button.pressed.connect(_on_decrease_card.bind(card_key))

	# Create counter label
	var counter_label = Label.new()
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_label.text = "0"
	counter_label.modulate = Color(0.7, 0.7, 0.7)
	counter_label.custom_minimum_size = Vector2(60, 40)
	counter_label.add_theme_font_size_override("font_size", 32)
	card_counters[card_key] = counter_label

	# Create plus button
	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(40, 40)
	plus_button.add_theme_font_size_override("font_size", 24)
	plus_button.pressed.connect(_on_increase_card.bind(card_key))

	# Add controls to counter container
	counter_container.add_child(minus_button)
	counter_container.add_child(counter_label)
	counter_container.add_child(plus_button)

	# Add card and counter to vertical container
	vertical_container.add_child(card_container)
	vertical_container.add_child(counter_container)

	# Add vertical container to grid
	grid_container.add_child(vertical_container)

	# Add click handling for deck building (press effect)
	card_container.gui_input.connect(_on_card_clicked.bind(card_key, card_container))


func _on_card_clicked(event: InputEvent, card_key: String, container: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Press down effect
			var press_tween = create_tween()
			press_tween.tween_property(container, "scale", Vector2(0.95, 0.95), 0.1)
		else:
			# Release effect and increment
			var release_tween = create_tween()
			release_tween.tween_property(container, "scale", Vector2.ONE, 0.1)
			_on_increase_card(card_key)


func _on_increase_card(card_key: String) -> void:
	# Get current count for this card
	var current_count = selected_cards.get(card_key, 0)

	# Calculate total cards in deck
	var total_cards = 0
	for count in selected_cards.values():
		total_cards += count

	# Check if we can add more cards
	if total_cards >= max_deck_size:
		print("Deck is at maximum capacity!")
		return

	# Increment the count
	selected_cards[card_key] = current_count + 1

	# Update the counter label
	if card_counters.has(card_key):
		var counter_label = card_counters[card_key]
		counter_label.text = str(selected_cards[card_key])
		counter_label.modulate = Color.WHITE

	# Update deck counter
	update_deck_counter()


func _on_decrease_card(card_key: String) -> void:
	# Get current count for this card
	var current_count = selected_cards.get(card_key, 0)

	# Don't go below 0
	if current_count <= 0:
		return

	# Decrement the count
	selected_cards[card_key] = current_count - 1

	# Update the counter label
	if card_counters.has(card_key):
		var counter_label = card_counters[card_key]
		counter_label.text = str(selected_cards[card_key])

		# Gray out if count is 0
		if selected_cards[card_key] == 0:
			counter_label.modulate = Color(0.7, 0.7, 0.7)
		else:
			counter_label.modulate = Color.WHITE

	# Update deck counter
	update_deck_counter()


func update_deck_counter() -> void:
	# Calculate total cards
	var total_cards = 0
	for count in selected_cards.values():
		total_cards += count

	deck_counter_label.text = "Cards in deck: %d/%d" % [total_cards, max_deck_size]

	# Change color based on deck status
	if total_cards == 0:
		deck_counter_label.modulate = Color(0.7, 0.7, 0.7)
		ready_button.disabled = true
	elif total_cards >= max_deck_size:
		deck_counter_label.modulate = Color(1.0, 0.5, 0.5)
		ready_button.disabled = false
	else:
		deck_counter_label.modulate = Color.WHITE
		ready_button.disabled = false




# Returns the selected deck as an array of card data
func get_selected_deck() -> Array:
	var deck_data = []
	for card_key in selected_cards:
		if CardDatabase.CARDS.has(card_key):
			var count = selected_cards[card_key]
			# Add each card the number of times it was selected
			for i in range(count):
				var card_data = CardData.create_card_data_from_type(card_key)
				deck_data.append(card_data)	
	return deck_data


func _on_ready_button_pressed() -> void:
	var deck_data = get_selected_deck()

	# Store the deck in the DeckManager singleton
	DeckManager.set_deck(deck_data)

	# Change to the game scene
	get_tree().change_scene_to_file("res://lib/screens/game.tscn")
