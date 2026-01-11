class_name WaitForSelectionCommand
extends GameCommand

## Command that pauses execution until player completes card selection
## Disables normal game interactions during selection
## Stores results in shared_data["selected_cards"] and shared_data["unselected_cards"]

var num_to_select: int


func _init(n: int) -> void:
	num_to_select = n


func can_execute(game_manager: GameManager) -> bool:
	var drawn_cards = get_shared_data("drawn_cards", [])
	var selection_ui = get_shared_data("selection_ui")
	return drawn_cards.size() > 0 and selection_ui != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		print("  -> Cannot wait for selection - no cards or selection UI")
		set_shared_data("selected_cards", [])
		set_shared_data("unselected_cards", [])
		return

	var drawn_cards: Array = get_shared_data("drawn_cards", [])
	var selection_ui: CardSelectionUI = get_shared_data("selection_ui")

	# Disable normal game interactions during selection
	InputManager.interactions_enabled = false

	# Setup selection UI with cards
	# Clamp num_to_select to available cards
	var actual_select_count = min(num_to_select, drawn_cards.size())
	selection_ui.setup(drawn_cards, actual_select_count)

	# Wait for player to complete selection
	var result = await selection_ui.selection_completed
	var selected_cards: Array = result[0]
	var unselected_cards: Array = result[1]

	# Re-enable game interactions
	InputManager.interactions_enabled = true

	# Store results for next commands
	set_shared_data("selected_cards", selected_cards)
	set_shared_data("unselected_cards", unselected_cards)

	print("  -> Selection complete: ", selected_cards.size(), " selected, ", unselected_cards.size(), " unselected")
