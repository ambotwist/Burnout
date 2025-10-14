extends Node2D
class_name GameManager

# Signals
signal ui_updated()

# Class references
var input_manager: InputManager
var card_manager: CardManager
# @onready var effects_manager: EffectsManager = $"../EffectsManager" as EffectsManager  # TODO: Add EffectsManager to scene
var effects_manager: EffectsManager

# UI variables
@onready var mental_health_label = $"../UI/Scores/MentalHealthLabel"
@onready var productivity_label = $"../UI/Scores/ProductivityLabel" 

# Card tracking
var card_being_played: Card = null
var current_card_index: int = 0
var played_card: Array[Card] = []


### --- SETUP --- ####

func _ready() -> void:
	_setup_references()
	_setup_signal_connections()
	await get_tree().create_timer(2).timeout
	for i in range(5):
		if card_manager.draw_pile.is_empty():
			return
		card_manager.draw_card()
		await get_tree().create_timer(0.1).timeout


func _setup_references() -> void:
	input_manager = $"../InputManager"
	card_manager = $"../CardManager"


func _setup_signal_connections() -> void:
	card_manager.card_released.connect(on_card_released)


func update_ui() -> void:
	productivity_label.text = "Productivity: " + str(GameState.productivity_total)


### --- PROCESSING --- ###

func on_card_released(card: Card) -> void:
	card_manager.hand.update_cards_hand_positions()


func on_effects_queue_processed() -> void:
	pass


func _on_input_manager_left_mouse_button_pressed(raycast: Variant) -> void:
	pass # Replace with function body.


func _on_input_manager_left_mouse_button_released() -> void:
	pass # Replace with function body.
