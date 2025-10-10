extends Node2D
class_name Deck

const CARD_SCENE_PATH = "res://scenes/card.tscn"
var card_scene

var hand
var deck = []
@export var hand_size = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hand = $"../Hand"
	card_scene = preload(CARD_SCENE_PATH)


# Draws a card from the deck and instantiates a new card scene
func draw_card(draw_effects_buffer: Array[Effect]) -> void:
	# Return if the deck is empty
	if deck.size() <= 0:
		return
	
	# Draw and remove the top card from the deck
	var drawn_card = deck[0]
	deck.erase(drawn_card)

	var new_card: Card = card_scene.instantiate()
	new_card.assign_data(drawn_card)

	# Convert deck's global position to hand's local space
	new_card.position = hand.to_local(global_position)
	hand.add_child(new_card)

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


func insight_n_cards(n: int) -> void:
	var card_manager = $"../CardManager"

	# Calculate horizontal spacing for insight cards
	var card_spacing = GameConstants.CARD_SCALED_WIDTH * 1.2  # 20% gap between cards
	var total_width = (n - 1) * card_spacing
	var start_x = -total_width / 2

	for i in range(n):
		if i < deck.size() and deck[i] != null:
			var card_n = card_scene.instantiate()
			card_n.assign_data(deck[i])

			# Convert deck's global position to card_manager's local space
			card_n.position = card_manager.to_local(global_position)
			card_manager.add_child(card_n)

			# Calculate horizontal position for this card
			var target_x = start_x + i * card_spacing
			var target_position = Vector2(target_x, 0)

			# Play flip animation and animate to position
			card_n.get_node("AnimationPlayer").play("card_flip")
			card_manager.animate_card_to_position_and_rotation(card_n, target_position, 0)
			