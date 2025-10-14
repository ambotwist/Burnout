extends Node2D
class_name Pile
# Pile class is type agnostic

const CARD_SCENE_PATH = "res://lib/nodes/card.tscn"
var card_scene
var card_manager: CardManager
var cards: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_scene = preload(CARD_SCENE_PATH)
	card_manager = get_parent()


func add_card(card) -> void:
	cards.append(card)

func remove_top_card():
	return cards.pop_front()


func remove_card(card) -> void:
	cards.erase(card)


func peek_top_card():
	return cards.front()


func peek_top_n_cards(n: int) -> Array:
	var result: Array = []
	for i in range(n):
		if i < cards.size():
			result.append(cards.get(i))
	return result


func is_empty() -> bool:
	return cards.is_empty()


func size() -> int:
	return cards.size()


func shuffle() -> void:
	cards.shuffle()
