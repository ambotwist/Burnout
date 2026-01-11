class_name ArchiveEffect
extends EffectStrategy

## Effect that archives target card(s): discards them AND generates their productivity immediately.
## Uses the Command Chain Pattern for flexible, composable behavior.
## Animates the ACTUAL card (not a copy) from its current location -> preview -> discard pile.
## The card is removed from its original pile before animation.
##
## Archive = Discard + Generate Productivity + Track for future bonuses (e.g., DOSSIER_PERSISTANT)

@export var target_strategy: TargetStrategy

## Whether to show a visual preview of the archived card
@export var show_preview: bool = false

## Where to show the preview (if show_preview is true)
@export var preview_position: GameEnums.PreviewPosition = GameEnums.PreviewPosition.SCHEDULE_CENTER

## Custom position (only used if preview_position = CUSTOM)
@export var preview_custom_position: Vector2 = Vector2.ZERO

## How long to show the preview (seconds)
@export var preview_duration: float = 0.5

## Whether to animate the card to the discard pile
@export var animate_to_pile: bool = true

## Animation duration (seconds)
@export var animation_duration: float = 0.3


func apply_effect(context: GameContext) -> void:
	if not target_strategy:
		push_error("ArchiveEffect: target_strategy is not set")
		return

	var targets = target_strategy.select_targets(context)

	if targets.is_empty():
		print("  -> No targets found to archive")
		return

	for target in targets:
		_build_command_chain(target, context)


func _build_command_chain(target: CardData, context: GameContext) -> void:
	if not target or not target.strategy:
		push_error("ArchiveEffect: Invalid target CardData")
		return

	# Build command chain from back to front (so each command knows its next)
	# IMPORTANT: Create a shared data dictionary that ALL commands in the chain will use
	var chain_shared_data: Dictionary = {}

	# Store the target card data in shared_data so commands can access it
	chain_shared_data["card_data"] = target

	# Final command: Archive the card (discard + productivity + track)
	var archive_cmd = ArchiveCardCommand.new()
	archive_cmd.shared_data = chain_shared_data

	var current_command = archive_cmd

	# If animating, add animation command to discard pile
	if animate_to_pile and show_preview:
		var pile_position = _get_pile_position(context)
		var pile_scale = _get_pile_scale(context)

		# AnimateCardCommand determines fade/flip behavior based on pile type
		var animate_cmd = AnimateCardCommand.new(
			GameEnums.PileType.DISCARD,
			pile_position,
			pile_scale
		)
		animate_cmd.shared_data = chain_shared_data
		animate_cmd.set_next_command(current_command)
		current_command = animate_cmd

	# If showing preview, add wait command before animation/adding
	if show_preview:
		var wait_cmd = WaitCommand.new(preview_duration)
		wait_cmd.shared_data = chain_shared_data
		wait_cmd.set_next_command(current_command)
		current_command = wait_cmd

		# Animate card to preview position (stay visible at 1.0 opacity)
		var preview_pos = context.get_preview_position(preview_position, preview_custom_position)
		var hand_scale = context.hand.cards_scale if context.hand else 0.7
		var animate_to_preview_cmd = AnimateCardCommand.new(
			GameEnums.PileType.HAND,  # Use HAND pile behavior (visible, no flip/fade)
			preview_pos,
			hand_scale
		)
		animate_to_preview_cmd.shared_data = chain_shared_data
		animate_to_preview_cmd.set_next_command(current_command)
		current_command = animate_to_preview_cmd

		# Reparent card to CardManager (so it can animate in global space)
		var reparent_cmd = ReparentCardCommand.new()
		reparent_cmd.shared_data = chain_shared_data
		reparent_cmd.set_next_command(current_command)
		current_command = reparent_cmd

		# Remove card from its current pile (so it doesn't stay in hand)
		var remove_cmd = RemoveCardFromPileCommand.new()
		remove_cmd.shared_data = chain_shared_data
		remove_cmd.set_next_command(current_command)
		current_command = remove_cmd

	# First command: Find the actual card node
	var find_node_cmd = FindCardNodeCommand.new()
	find_node_cmd.shared_data = chain_shared_data
	find_node_cmd.set_next_command(current_command)

	# Queue the first command - the chain will execute automatically
	context.command_queue.append(find_node_cmd)

	print("  -> Card archive chain queued: ", target.strategy.card_id)


## Helper to get the position of the discard pile for animation target
func _get_pile_position(context: GameContext) -> Vector2:
	return context.discard_pile.global_position if context.discard_pile else Vector2.ZERO


## Helper to get the scale of the discard pile (for consistent card sizing)
func _get_pile_scale(context: GameContext) -> float:
	return context.discard_pile.cards_scale if context.discard_pile else 0.5
