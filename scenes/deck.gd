extends Node2D
class_name Deck

const CARD_SCENE_PATH = "res://scenes/card.tscn"

var hand
var deck = ["archive", "archive", "archive", "archive", "archive", "archive", "archive", "archive"]
@export var hand_size = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hand = $"../Hand"
	scale = Vector2(GameConstants.CARD_SCALE, GameConstants.CARD_SCALE)


func draw_card():
	if deck.size() <= 0:
		return
	
	var card_drawn = deck[0]
	deck.erase(card_drawn)
		
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card: Card = card_scene.instantiate()
	new_card.name = "Card"
	new_card.position = position
	$"../CardManager".add_child(new_card)
	hand.add_card_to_hand(new_card)

	# If the deck is empty, disable the collision shape and hide the sprite
	if deck.size() <= 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
