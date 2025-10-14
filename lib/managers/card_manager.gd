extends Node2D
class_name CardManager

signal card_released(card)

var card_scene

# Class references
var input_manager: InputManager
var draw_pile: DrawPile
var hand: Hand
var discard_pile: Pile
var play_pile: PlayPile


# Card database
var card_db

# Card logic
var held_card: Card = null


### --- INITIALIZATION --- ###

func _ready() -> void:
	card_scene = preload("res://lib/nodes/card.tscn")
	_setup_references()
	_setup_signal_connections()
	_init_draw_pile()


func _setup_references():
	input_manager = $"../InputManager"
	draw_pile = $"DrawPile"
	hand = $"Hand"
	play_pile = $"PlayPile"


func _setup_signal_connections() -> void:
	input_manager.left_mouse_button_pressed.connect(on_left_mouse_button_pressed)
	input_manager.left_mouse_button_released.connect(on_left_mouse_button_released)

func _init_draw_pile() -> void:
	for card_data in DeckManager.get_deck():
		draw_pile.add_card(card_data)
	draw_pile.shuffle()


### --- CARD LOGIC --- ###

# - Draw pile functions -

func draw_card() -> void:
	var card_data = draw_pile.remove_top_card()
	var card = card_scene.instantiate()
	card.position = draw_pile.position
	add_child(card)
	card.assign_data(card_data)
	add_card_to_hand(card)
	if draw_pile.cards.is_empty():
		draw_pile.visible = false


func insight_n_cards(n: int) -> void:
	var insight_cards = draw_pile.peek_top_n_items(n)
	

# - Hand functions - 
func play_card(card: Card) -> void:
	pass


func discard_card(card: Card) -> void:
	if card.parent != null:
		card.parent.remove_from_pile(card)
	move_card_to(card, discard_pile.position, 0, true)
	fade_out_card(card)
	discard_pile.add_to_pile(card)


# - Move card functions -
func add_card_to_overlay_zone(card: Card) -> void:
	pass


func add_card_to_hand(card: Card) -> void:
	card.parent = hand
	hand.cards.append(card)
	hand.update_cards_hand_positions()
	card.animation_player.play("card_flip")
	

### --- CARD HANDLING --- ###

func _process(delta: float) -> void:
	if held_card:
		drag_card(held_card)


func hold_card(card: Card) -> void:
	held_card = card
	#play_pile.fade_in()


func release_card() -> void:
	if held_card:
		card_released.emit(held_card)
		held_card = null


func drag_card(card: Card) -> void:
	var mouse_position = get_global_mouse_position()
	card.global_position = Vector2(
		clamp(mouse_position.x, 0, get_viewport().size.x),
		clamp(mouse_position.y, 0, get_viewport().size.y)
	)


func highlight_card(card: Card) -> void:
	card.z_index = 5
	scale_card(card, Vector2(GameConstants.CARD_SCALED_WIDTH, GameConstants.CARD_SCALED_HEIGHT))

	if card.parent is Hand:
		move_card_to(card, Vector2(card.position.x, card.position.y - 30), 0, false)


func dehighlight_card(card: Card) -> void:
	scale_card(card, Vector2(GameConstants.CARD_WIDTH_SCALE, GameConstants.CARD_HEIGHT_SCALE))

	if card.parent is Hand:
		move_card_to(card, Vector2(card.position.x, card.position.y - 30), 0, false)


### --- CARD ANIMATION --- ###

func move_card_to(card: Card, destination: Vector2, rotation: float, flip: bool):
	if flip:
		card.animation_player.play("card_flip")
	card.collision_shape.disabled = true 
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(card, "position", destination, 0.1)
	tween.parallel().tween_property(card, "rotation", rotation, 0.1)
	tween.finished.connect(func():
		card.collision_shape.disabled = false)


func fade_out_card(card: Card) -> void:
	card.collision_shape.disabled = true
	var tween = get_tree().create_tween()
	tween.tween_property(card, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func():
		card.collision_shape.disabled = false)



func scale_card(card: Card, card_scale: Vector2) -> void:
	card.collision_shape.disabled = true
	var tween = get_tree().create_tween()
	tween.tween_property(card, "scale", card_scale.x, card_scale.y) 
	tween.finished.connect(func():
		card.collision_shape.disabled = false)


### --- SIGNAL PROCESSING --- ###

func on_card_played(card: Card) -> void:
	pass

func on_left_mouse_button_pressed(raycast_result) -> void:
	if raycast_result is Card:
		hold_card(raycast_result)


func on_left_mouse_button_released() -> void:
	release_card()


func _on_mouse_entered_card(card: Card) -> void:
	if not held_card:
		highlight_card(card)


func _on_mouse_exited_card(card: Card) -> void:
	if card != held_card:
		dehighlight_card(card)
