extends Node2D
class_name Deck

const CARD_SCENE_PATH = "res://scenes/card.tscn"

var card_db
var hand
var deck = []
@export var hand_size = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(7):
		deck.append("Archive")
	deck.shuffle()
	card_db = preload("res://scripts/card_database.gd")
	hand = $"../Hand"
	scale = Vector2(GameConstants.CARD_SCALE, GameConstants.CARD_SCALE)


func draw_card():
	if deck.size() <= 0:
		return
	
	var card_drawn = deck[0]
	deck.erase(card_drawn)
		
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card: Card = card_scene.instantiate()
	new_card.get_node("Cost").text = str(card_db.CARDS[card_drawn][0])
	new_card.get_node("Value").text =str(card_db.CARDS[card_drawn][1])
	new_card.name = "Card"
	new_card.position = position
	$"../CardManager".add_child(new_card)
	hand.add_card_to_hand(new_card)
	
	new_card.get_node("AnimationPlayer").play("card_flip")

	# If the deck is empty, disable the collision shape and hide the sprite
	if deck.size() <= 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
