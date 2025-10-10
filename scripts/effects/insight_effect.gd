class_name InsightEffect
extends Effect

var deck
var insight_count: int = 0

func init() -> void:
	effect_type = Effect.Effect_Type.DRAW_EFFECT

func apply() -> void:
	deck.insight_n_cards(insight_count)
