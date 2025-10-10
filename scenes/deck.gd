extends Node2D
class_name Deck

const CARD_SCENE_PATH = "res://scenes/card.tscn"

var hand
var deck = []
@export var hand_size = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hand = $"../Hand"
	

# Draws a card from the deck and instantiates a new card scene
func draw_card(draw_effects_buffer: Array[Effect]) -> void:
	# Return if the deck is empty
	if deck.size() <= 0:
		return
	
	# Draw and remove the top card from the deck
	var drawn_card = deck[0]
	deck.erase(drawn_card)
		
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card: Card = card_scene.instantiate()
	new_card.assign_data(drawn_card)

	# Add card scene to the game scene
	new_card.position = position
	$"../CardManager".add_child(new_card)

	# Apply draw effect buffer
	for effect in draw_effects_buffer:
		effect.target = new_card
		if effect.can_play():
			await effect.apply()
			draw_effects_buffer.erase(effect)

	# Add card scene to the game scene and play animation
	hand.add_card_to_hand(new_card)
	new_card.get_node("AnimationPlayer").play("card_flip")

	# If the deck is empty, disable the collision shape and hide the sprite
	if deck.size() <= 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
