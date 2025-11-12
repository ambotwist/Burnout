class_name CreateCardVisualCommand
extends GameCommand

## Command to create a visual Card node at a specified position
## Retrieves CardData from shared_data, creates the node, and stores reference for next commands

var position: Vector2
var scale_factor: float

func _init(pos: Vector2, scale_val: float = 1.0) -> void:
	position = pos
	scale_factor = scale_val


func can_execute(game_manager: GameManager) -> bool:
	var card_data = get_shared_data("card_data")
	return card_data != null and game_manager != null and game_manager.card_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("CreateCardVisualCommand: Cannot create visual - missing card_data or card_manager")
		return

	var card_data = get_shared_data("card_data")

	# Assign unique game ID to the card
	card_data.game_id = game_manager.card_id_counter
	game_manager.card_id_counter += 1

	# Create the visual Card node
	var card_node = game_manager.card_manager.create_card(card_data, scale_factor)

	# Add as child of CardManager (so it's in global coordinate space)
	game_manager.card_manager.add_child(card_node)

	# Position the card
	card_node.global_position = position

	# Apply visual data (text, colors, etc.)
	card_node.apply_card_data()

	# Disable interaction during preview (will be freed anyway, but prevents clicking)
	card_node.remove_from_group("interactable")
	if card_node.has_node("Node2D/Area2D/CollisionShape2D"):
		card_node.get_node("Node2D/Area2D/CollisionShape2D").disabled = true

	# Store card node for next commands
	set_shared_data("card_node", card_node)

	print("  → Card visual created at position: ", position)
