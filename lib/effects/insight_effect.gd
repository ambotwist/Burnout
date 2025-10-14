class_name InsightEffect
extends Effect

var deck
var insight_count: int = 0

func init() -> void:
	effect_type = Effect.Type.VOID

func apply() -> void:
	deck.insight_n_cards(insight_count)
