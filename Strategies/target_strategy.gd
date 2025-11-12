@tool
class_name TargetStrategy
extends Resource

@export var target_card: GameEnums.CardID = GameEnums.CardID.ANY:
	set(value):
		target_card = value
		notify_property_list_changed()
@export var target_deck: GameEnums.DeckType = GameEnums.DeckType.ANY
@export var target_pile: GameEnums.PileType = GameEnums.PileType.ANY

# Hide deck/pile fields when SELF is selected
func _validate_property(property: Dictionary) -> void:
	if target_card == GameEnums.CardID.SELF:
		if property.name in ["target_deck", "target_pile"]:
			property.usage = PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_STORAGE

# Default implementation - can be overridden in child classes
func select_targets(context: GameContext) -> Array[CardData]:
	# Handle SELF targeting
	if target_card == GameEnums.CardID.SELF:
		if context.self_card:
			return [context.self_card]
		return []

	# Get candidates based on pile filter
	var candidates: Array[CardData] = []
	if target_pile == GameEnums.PileType.ANY:
		candidates = context.get_all_cards()
	else:
		candidates = context.get_cards_in_pile(target_pile)

	var results: Array[CardData] = []

	# Apply filters
	for card in candidates:
		if _matches_filters(card, context):
			results.append(card)

	# Handle RANDOM
	if target_card == GameEnums.CardID.RANDOM and results.size() > 0:
		return [results.pick_random()]

	return results


func _matches_filters(card: CardData, context: GameContext) -> bool:
	# Check deck filter
	if target_deck != GameEnums.DeckType.ANY and target_deck != GameEnums.DeckType.RANDOM:
		if card.strategy.deck != target_deck:
			return false

	# Check specific card ID filter
	if target_card != GameEnums.CardID.ANY and target_card != GameEnums.CardID.RANDOM and target_card != GameEnums.CardID.SELF:
		# Match by card_id string from strategy
		var card_id_string = GameEnums.CardID.keys()[target_card]
		if card.strategy.card_id != card_id_string:
			return false

	return true
