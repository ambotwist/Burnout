class_name CardData
extends Resource

var id: int
var type: String
var duration: int
var productivity: int
var deck: String
var title: String
var description: String
var prerequisite: Callable = func() -> bool: return true
var effect_trigger: Effect.Trigger
var effect_types: Array


static func create_card_data_from_type(card_type: String) -> CardData:
	var card_data = CardData.new()
	var card_db_data = CardDatabase.CARDS[card_type]
	card_data.id = preload("res://lib/core/game_state.gd").generate_unique_card_id()
	card_data.type = card_type
	card_data.duration = card_db_data[0]
	card_data.productivity = card_db_data[1]
	card_data.deck = card_db_data[2]
	card_data.title = card_db_data[3]
	card_data.description = card_db_data[4]
	card_data.prerequisite = card_db_data[5]
	card_data.effect_trigger = card_db_data[6]
	card_data.effect_types = card_db_data[7]
	return card_data
