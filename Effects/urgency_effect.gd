class_name UrgencyEffect
extends EffectStrategy

## URGENCY Effect: Marks a card as urgent when drawn
## - Card productivity is doubled if played immediately after drawing
## - If not played immediately (any other card played), card is auto-discarded
## - Visual: Red pulsing overlay on the card
## Trigger: ON_DRAW

func apply_effect(context: GameContext) -> void:
	if not context.self_card:
		push_error("UrgencyEffect: No self_card in context")
		return

	# Mark the card as urgent
	context.self_card.is_urgent = true
	print("  -> URGENCY activated on card")
