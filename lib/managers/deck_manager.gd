extends Node

# Singleton to manage deck data between scenes
var selected_deck: Array = []

func set_deck(deck_data: Array) -> void:
	selected_deck = deck_data.duplicate()
	print("DeckManager: Stored %d cards" % selected_deck.size())

func get_deck() -> Array:
	return selected_deck

func clear_deck() -> void:
	selected_deck.clear()