class_name CardCopyEffect
extends EffectStrategy

## Effect that copies target card(s) and optionally shows them before adding to a pile
## Uses the Command Chain Pattern for flexible, composable behavior
## Supports: copying, previewing, animating, and adding to any pile

@export var target_strategy: TargetStrategy

## Destination pile for the copied card
@export var destination_pile: GameEnums.PileType = GameEnums.PileType.HAND

## Whether to show a visual preview of the copied card
@export var show_preview: bool = false

## Where to show the preview (if show_preview is true)
@export var preview_position: GameEnums.PreviewPosition = GameEnums.PreviewPosition.SCHEDULE_CENTER

## Custom position (only used if preview_position = CUSTOM)
@export var preview_custom_position: Vector2 = Vector2.ZERO

## How long to show the preview (seconds)
@export var preview_duration: float = 1.0

## Whether to animate the card to the destination pile
@export var animate_to_pile: bool = true

## Animation duration (seconds)
@export var animation_duration: float = 0.3

func apply_effect(context: GameContext) -> void:
	if not target_strategy:
		push_error("CardCopyEffect: target_strategy is not set")
		return

	var targets = target_strategy.select_targets(context)

	if targets.is_empty():
		print("  → No targets found to copy")
		return

	for target in targets:
		_build_command_chain(target, context)


func _build_command_chain(target: CardData, context: GameContext) -> void:
	if not target or not target.strategy:
		push_error("CardCopyEffect: Invalid target CardData")
		return

	# Build command chain from back to front (so each command knows its next)
	# IMPORTANT: Create a shared data dictionary that ALL commands in the chain will use
	var chain_shared_data: Dictionary = {}

	# Final command: Add to destination pile
	var add_to_pile_cmd = AddCardToPileCommand.new(destination_pile)
	add_to_pile_cmd.shared_data = chain_shared_data

	var current_command = add_to_pile_cmd

	# If animating, add animation command before adding to pile
	if animate_to_pile and show_preview:
		var pile_position = _get_pile_position(context, destination_pile, target)
		var pile_scale = _get_pile_scale(context, destination_pile)

		# AnimateCardCommand determines fade/flip behavior based on pile type
		var animate_cmd = AnimateCardCommand.new(
			destination_pile,
			pile_position,
			pile_scale
		)
		animate_cmd.shared_data = chain_shared_data  # Use same dictionary
		animate_cmd.set_next_command(current_command)
		current_command = animate_cmd

	# If showing preview, add wait command before animation/adding
	if show_preview:
		var wait_cmd = WaitCommand.new(preview_duration)
		wait_cmd.shared_data = chain_shared_data  # Use same dictionary
		wait_cmd.set_next_command(current_command)
		current_command = wait_cmd

		# Add visual creation command before wait
		var preview_pos = context.get_preview_position(preview_position, preview_custom_position)
		var hand_scale = context.hand.cards_scale if context.hand else 0.7
		var create_visual_cmd = CreateCardVisualCommand.new(preview_pos, hand_scale)
		create_visual_cmd.shared_data = chain_shared_data  # Use same dictionary
		create_visual_cmd.set_next_command(current_command)
		current_command = create_visual_cmd

	# First command: Copy the card data
	var copy_cmd = CopyCardCommand.new(target)
	copy_cmd.shared_data = chain_shared_data  # Use same dictionary
	copy_cmd.set_next_command(current_command)

	# Queue the first command - the chain will execute automatically
	context.command_queue.append(copy_cmd)

	print("  → Card copy chain queued: ", target.strategy.card_id)


## Helper to get the position of a pile for animation target
func _get_pile_position(context: GameContext, pile_type: GameEnums.PileType, card_data: CardData = null) -> Vector2:
	match pile_type:
		GameEnums.PileType.HAND:
			return context.hand.global_position if context.hand else Vector2.ZERO
		GameEnums.PileType.DRAW:
			return context.draw_pile.global_position if context.draw_pile else Vector2.ZERO
		GameEnums.PileType.DISCARD:
			return context.discard_pile.global_position if context.discard_pile else Vector2.ZERO
		GameEnums.PileType.SCHEDULE:
			# Schedule position depends on card duration - get next available slot
			if context.schedule and card_data:
				return context.schedule.get_slot_position(card_data.duration)
			return Vector2.ZERO
		_:
			return Vector2.ZERO


## Helper to get the scale of a pile (for consistent card sizing)
func _get_pile_scale(context: GameContext, pile_type: GameEnums.PileType) -> float:
	match pile_type:
		GameEnums.PileType.HAND:
			return context.hand.cards_scale if context.hand else 0.7
		GameEnums.PileType.DRAW:
			return context.draw_pile.cards_scale if context.draw_pile else 0.5
		GameEnums.PileType.DISCARD:
			return context.discard_pile.cards_scale if context.discard_pile else 0.5
		GameEnums.PileType.SCHEDULE:
			# Schedule cards are small (they become colored slots)
			return 0.5
		_:
			return 1.0
