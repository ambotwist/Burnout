class_name PlanningEffect
extends EffectStrategy

## Effect that draws cards from draw pile, shows them for player selection,
## and moves selected cards to destination while shuffling the rest back
##
## Uses modular commands that can be reused for similar effects (Scry, Mulligan, etc.)

## Number of cards to draw for selection
@export var cards_to_draw: int = 3

## Number of cards player must select
@export var cards_to_select: int = 1

## Whether to shuffle unselected cards back into draw pile
@export var shuffle_remainder: bool = true

## Where selected cards go (HAND or SCHEDULE)
@export var destination: GameEnums.PileType = GameEnums.PileType.HAND

## Optional: Modify selected cards' productivity (0 = no change)
@export var selected_card_productivity_modifier: int = 0

## Optional: Modify selected cards' duration (0 = no change)
@export var selected_card_duration_modifier: int = 0

## Preload selection UI scene
var selection_ui_scene: PackedScene = preload("res://Objects/UI/card_selection_ui.tscn")


func apply_effect(context: GameContext) -> void:
	# Validate we have cards to draw
	if context.draw_pile.is_empty():
		print("  -> PlanningEffect: No cards in draw pile")
		return

	# Create selection UI instance
	var selection_ui = selection_ui_scene.instantiate()

	# Add to the scene tree (as child of CardManager for consistent layering)
	if context.hand and context.hand.get_parent():
		var card_manager = context.hand.get_parent()
		card_manager.add_child(selection_ui)
	else:
		push_error("PlanningEffect: Could not find CardManager to add selection UI")
		return

	# Build command chain from back to front
	# All commands share the same shared_data dictionary
	var chain_shared_data: Dictionary = {}
	chain_shared_data["selection_ui"] = selection_ui

	# Final: Cleanup selection UI
	var cleanup_cmd = CleanupSelectionUICommand.new()
	cleanup_cmd.shared_data = chain_shared_data

	# Add selected cards to destination pile
	var add_to_pile_cmd = AddSelectedCardsToPileCommand.new(destination)
	add_to_pile_cmd.shared_data = chain_shared_data
	add_to_pile_cmd.set_next_command(cleanup_cmd)

	var current_cmd = add_to_pile_cmd

	# If modifiers are set, insert ModifySelectedCardsCommand before adding to pile
	if selected_card_productivity_modifier != 0 or selected_card_duration_modifier != 0:
		var modify_cmd = ModifySelectedCardsCommand.new(
			selected_card_productivity_modifier,
			selected_card_duration_modifier
		)
		modify_cmd.shared_data = chain_shared_data
		modify_cmd.set_next_command(current_cmd)
		current_cmd = modify_cmd

	# Return unselected cards to draw pile
	var return_cmd = ReturnCardsToDrawPileCommand.new(shuffle_remainder)
	return_cmd.shared_data = chain_shared_data
	return_cmd.set_next_command(current_cmd)

	# Wait for player selection
	var wait_cmd = WaitForSelectionCommand.new(cards_to_select)
	wait_cmd.shared_data = chain_shared_data
	wait_cmd.set_next_command(return_cmd)

	# Animate cards to selection positions
	var animate_cmd = AnimateCardsToSelectionCommand.new()
	animate_cmd.shared_data = chain_shared_data
	animate_cmd.set_next_command(wait_cmd)

	# Draw cards from draw pile (first command in chain)
	var draw_cmd = DrawCardsToSelectionCommand.new(cards_to_draw)
	draw_cmd.shared_data = chain_shared_data
	draw_cmd.set_next_command(animate_cmd)

	# Queue the first command - the chain will execute automatically
	context.command_queue.append(draw_cmd)

	print("  -> Planning effect queued: draw ", cards_to_draw, ", select ", cards_to_select, " -> ", _get_destination_name())


func _get_destination_name() -> String:
	match destination:
		GameEnums.PileType.HAND: return "HAND"
		GameEnums.PileType.SCHEDULE: return "SCHEDULE"
		_: return "UNKNOWN"
