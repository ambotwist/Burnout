class_name DrawCardsEffect
extends EffectStrategy

## Effect that draws N cards from draw pile directly to hand

@export var amount: int = 1


func apply_effect(context: GameContext) -> void:
	if amount <= 0:
		return

	var draw_cmd = DrawCardsToHandCommand.new(amount)
	context.command_queue.append(draw_cmd)

	print("  -> DrawCardsEffect: Queued draw ", amount, " card(s)")
