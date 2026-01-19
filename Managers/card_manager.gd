class_name CardManager
extends Node2D

signal card_released(card: Card)

@onready var card_scene = preload("res://Objects/Cards/card.tscn")
@onready var draw_pile: Pile = $DrawPile
@onready var hand: Hand = $Hand

@export var card_animation_speed: float = 0.15

var held_card: Card = null

var draw_pile_scale: float = 0.5
var hand_scale: float = 0.7


### SETUP ###

func _ready() -> void:
	_setup_signals()


func _setup_signals() -> void:
	InputManager.left_mouse_button_pressed.connect(on_left_mouse_button_pressed)
	InputManager.left_mouse_button_released.connect(on_left_mouse_button_released)
	InputManager.hovered_over_object.connect(on_hovered_over_object)
	InputManager.dehovered_from_object.connect(on_dehovered_from_object)
	hand.cards_scale_changed.connect(_on_hand_scale_changed)
	draw_pile.cards_scale_changed.connect(_on_draw_pile_scale_changed)


func create_card(card_data: CardData, pile_scale: float) -> Card:
	var card = card_scene.instantiate()
	card.card_data = card_data
	card.scale = Vector2(pile_scale, pile_scale)
	return card


### DRAW PILE FUNCTIONS ###

func draw_card() -> void:

	if hand.is_full():
		print("Cannot draw card - hand is full")
		return

	var card_data = draw_pile.remove_top_card()
	if card_data == null:
		print("No cards to draw!")
		return

	# Create card with draw pile scale
	var drawn_card = create_card(card_data, draw_pile.cards_scale)
	hand.add_child(drawn_card)

	# Position at draw pile
	drawn_card.global_position = draw_pile.global_position

	hand.add_card(drawn_card)
	drawn_card.apply_card_data()

	# Trigger ON_DRAW effects (e.g., UrgencyEffect)
	_trigger_on_draw_effects(drawn_card)

	# Animate to hand position with hand scale
	update_cards_hand_positions()
	drawn_card.animation_player.play("flip")


func _on_draw_pile_scale_changed() -> void:
	draw_pile_scale = draw_pile.cards_scale
	draw_pile.scale = Vector2(draw_pile_scale, draw_pile_scale)


## Trigger ON_DRAW effects for a freshly drawn card (e.g., UrgencyEffect)
func _trigger_on_draw_effects(card: Card) -> void:
	if not card or not card.card_data:
		return

	for effect in card.card_data.effects:
		if effect and effect.trigger == GameEnums.EffectTrigger.ON_DRAW:
			# Create minimal context for ON_DRAW
			var context = GameContext.new()
			context.self_card = card.card_data
			context.self_card_node = card

			# Apply the effect
			print("  -> ON_DRAW effect: ", effect.get_script().resource_path.get_file())
			effect.apply_effect(context)

	# Update visual after ON_DRAW effects (shows urgency overlay if applicable)
	card.apply_card_data()


### HAND FUNCTIONS ###

func update_cards_hand_positions() -> void:
	hand.card_positions.clear()
	for i in hand.cards.size():
		var card = hand.cards.get(i)
		hand.card_positions.set(card, i)
		var card_position = hand.calculate_card_position(card)
		var card_rotation = hand.calculate_card_rotation(card)
		card.z_index = i + 1
		move_card_to(card, card_position, card_rotation, hand.cards_scale, 1.0)


func _on_hand_scale_changed() -> void:
	hand_scale = hand.cards_scale
	update_cards_hand_positions()


### SIGNAL PROCESSING ###


func on_left_mouse_button_pressed(raycast_result) -> void:
	if raycast_result is Card:
		hold_card(raycast_result)


func on_left_mouse_button_released() -> void:
	release_card()


func on_hovered_over_object(object) -> void:
	if object is Card:
		highlight_card(object)


func on_dehovered_from_object(object) -> void:
	if object is Card:
		unhighlight_card(object)


### CARD HANDLING ###

func _process(delta: float) -> void:
	if held_card:
		drag_card(held_card)


func hold_card(card: Card) -> void:
	held_card = card


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


func add_to_schedule(card: Card, schedule_slot_position: Vector2) -> void:
	hand.remove_card(card)
	update_cards_hand_positions()

	# Reparent card from Hand to CardManager to work in consistent coordinates
	var current_global_pos = card.global_position
	card.reparent(self)
	card.global_position = current_global_pos  # Preserve visual position after reparenting

	# Move card to schedule position (now in CardManager's coordinate space)
	var local_schedule_pos = to_local(schedule_slot_position)
	var move_tween = move_card_to(card, local_schedule_pos, 0, 0, 0.0)
	await move_tween.finished

	# Now safe to free the card
	if is_instance_valid(card):
		card.queue_free()


### CARD ANIMATION ###

func highlight_card(card: Card) -> void:
	card.z_index += 100

	if card.get_parent() is Hand:
		move_card_to(card, Vector2(card.position.x,  -60), 0, hand.cards_scale + 0.2, 1.0)


func unhighlight_card(card: Card) -> void:
	card.z_index = hand.get_card_z_index(card)

	if card.get_parent() is Hand:
		var card_position = hand.calculate_card_position(card)
		var card_rotation = hand.calculate_card_rotation(card)
		move_card_to(card, Vector2(card_position.x, card_position.y), card_rotation, hand.cards_scale, 1.0)


func move_card_to(card: Card, arrival_position: Vector2, arrival_rotation: float, arrival_scale: float, arrival_fade: float) -> Tween:
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(card, "position", arrival_position, card_animation_speed)
	tween.parallel().tween_property(card, "rotation", arrival_rotation, card_animation_speed)
	tween.parallel().tween_property(card, "scale", Vector2(arrival_scale, arrival_scale), card_animation_speed)
	tween.parallel().tween_property(card, "modulate:a", arrival_fade, card_animation_speed)
	return tween
