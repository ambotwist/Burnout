class_name AnimateCardCommand
extends GameCommand

## Command to animate a card node to a target pile position
## Uses CardManager's move_card_to for consistent animation behavior
## Animation behavior (fade, flip, etc.) is determined by the destination pile type

var target_pile_type: GameEnums.PileType
var target_global_position: Vector2
var target_scale: float

# These are determined by pile type
var target_rotation: float
var target_fade: float
var play_flip_animation: bool

func _init(pile_type: GameEnums.PileType, pos: Vector2, scale: float) -> void:
	target_pile_type = pile_type
	target_global_position = pos
	target_scale = scale

	# Determine animation behavior based on destination pile
	_set_pile_specific_behavior(pile_type)


## Set animation parameters based on pile type
func _set_pile_specific_behavior(pile_type: GameEnums.PileType) -> void:
	match pile_type:
		GameEnums.PileType.HAND:
			# Hand: cards stay visible, face-up, no flip
			target_rotation = 0.0
			target_fade = 1.0  # Fully visible
			play_flip_animation = false

		GameEnums.PileType.SCHEDULE:
			# Schedule: cards fade into colored slots, no flip
			target_rotation = 0.0
			target_fade = 0.0  # Fade to invisible (becomes colored slot)
			play_flip_animation = false

		GameEnums.PileType.DISCARD:
			# Discard: cards fade out, flip face-down
			target_rotation = 0.0
			target_fade = 0.0  # Fade to invisible
			play_flip_animation = true

		GameEnums.PileType.DRAW:
			# Draw: cards fade out, flip face-down
			target_rotation = 0.0
			target_fade = 0.0  # Fade to invisible
			play_flip_animation = true

		_:
			# Default: visible, no flip
			target_rotation = 0.0
			target_fade = 1.0
			play_flip_animation = false


func can_execute(game_manager: GameManager) -> bool:
	var card_node = get_shared_data("card_node")
	return card_node != null and is_instance_valid(card_node) and game_manager != null and game_manager.card_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("AnimateCardCommand: Cannot animate - missing or invalid card_node or card_manager")
		return

	var card_node = get_shared_data("card_node")

	print("  → Animating card to ", _get_pile_name(target_pile_type), " pile")

	# Convert global position to local position (relative to CardManager)
	var local_position = game_manager.card_manager.to_local(target_global_position)

	# Play flip animation if needed (for cards going to discard/draw piles)
	if play_flip_animation and card_node.has_node("AnimationPlayer"):
		var anim_player = card_node.get_node("AnimationPlayer")
		if anim_player.has_animation("flip"):
			anim_player.play("flip")

	# Use CardManager's move_card_to for consistent animation
	var tween = game_manager.card_manager.move_card_to(
		card_node,
		local_position,
		target_rotation,
		target_scale,
		target_fade
	)

	# Wait for movement animation to complete
	if tween:
		await tween.finished


## Helper for logging
func _get_pile_name(pile_type: GameEnums.PileType) -> String:
	match pile_type:
		GameEnums.PileType.HAND: return "HAND"
		GameEnums.PileType.DRAW: return "DRAW"
		GameEnums.PileType.DISCARD: return "DISCARD"
		GameEnums.PileType.SCHEDULE: return "SCHEDULE"
		_: return "UNKNOWN"
