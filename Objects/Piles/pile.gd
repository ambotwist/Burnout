class_name Pile
extends Node2D

@onready var card_scene = preload("res://Objects/Cards/card.tscn")
var cards: Array = []

signal cards_scale_changed

@export var cards_scale: float = 1.0:
	set(value):
		cards_scale = value
		_update_all_card_scales()


func _ready() -> void:
	pass


func add_card(card) -> void:
	cards.append(card)


func remove_card(card) -> void:
	cards.erase(card)


func remove_top_card():
	return cards.pop_front()


func peek_top_card():
	return cards.front()


func peek_top_n_cards(n: int) -> Array:
	var result: Array= []
	for i in range(n):
		if i < cards.size():
			result.append(cards[i])
	return result


func get_random_card():
	if cards.is_empty():
		return null
	return cards.pick_random()


func remove_random_card():
	var random_card = get_random_card()
	if random_card:
		cards.erase(random_card)
	return random_card


func is_empty() -> bool:
	return cards.is_empty()


func size() -> int:
	return cards.size()


func shuffle() -> void:
	cards.shuffle()


func _update_all_card_scales() -> void:
	cards_scale_changed.emit()
