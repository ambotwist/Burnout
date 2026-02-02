class_name MissionData
extends RefCounted

var strategy  # MissionStrategy (untyped to avoid circular dependency)
var week_accepted: int
var deck_cards_played: Dictionary = {}  # DeckType -> int count
var status: MissionStatus = MissionStatus.ACTIVE

enum MissionStatus {
	ACTIVE,
	COMPLETED,
	FAILED
}


static func create_from_strategy(mission, week: int) -> MissionData:
	var data = MissionData.new()
	data.strategy = mission
	data.week_accepted = week
	data.deck_cards_played = {}
	return data


func track_card_played(card_data: CardData) -> void:
	var deck = card_data.strategy.deck
	if not deck_cards_played.has(deck):
		deck_cards_played[deck] = 0
	deck_cards_played[deck] += 1
