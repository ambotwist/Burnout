class_name ApplyUrgencyToNextDrawnEffect
extends EffectStrategy

## Makes the next card drawn become urgent
## - When this card is played, the next card drawn will have urgency applied
## - That card's productivity doubles if played immediately, otherwise auto-discards
## Trigger: ON_PLAY

func apply_effect(context: GameContext) -> void:
	# Queue command to set urgency flag on next drawn card
	var command = SetNextCardUrgentCommand.new()
	context.command_queue.append(command)
