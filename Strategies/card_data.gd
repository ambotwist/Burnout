class_name CardData
extends Resource

var strategy: CardStrategy
var game_id: int
var duration: int
var productivity: int
var effects: Array[EffectStrategy]
var zen_sanity_bonus: int = 0  # Bonus from zen window (reduces sanity toll)
var is_urgent: bool = false  # True when card has active urgency (just drawn with urgency effect)
var is_voided: bool = false  # True when card was voided by boss surveillance


static func create_card_data_from_strategy(card_strategy: CardStrategy) -> CardData:
	var card_data = CardData.new()
	card_data.strategy = card_strategy
	card_data.game_id = -1
	card_data.duration = card_strategy.duration
	card_data.productivity = card_strategy.productivity
	card_data.effects = card_strategy.effects
	return card_data
