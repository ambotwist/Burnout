class_name OnArchiveBoostEffect
extends EffectStrategy

## Effect that boosts this card's productivity each time any card is archived.
## Used by CENTRE_ARCHIVE: while in hand, gains +1 productivity per archived card.
##
## This effect uses the ON_ARCHIVE trigger which is handled specially by the Card node.
## When a card_archived event is emitted, cards in hand check for ON_ARCHIVE effects
## and apply them to themselves.

## How much productivity to add per archive event
@export var productivity_per_archive: int = 1


func apply_effect(context: GameContext) -> void:
	# This effect modifies the card that has this effect (self_card)
	if not context.self_card:
		push_error("OnArchiveBoostEffect: No self_card in context")
		return

	context.self_card.productivity += productivity_per_archive
	print("  -> CENTRE_ARCHIVE boosted: +", productivity_per_archive, " productivity (now ", context.self_card.productivity, ")")
