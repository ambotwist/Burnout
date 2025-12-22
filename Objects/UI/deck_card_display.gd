class_name DeckCardDisplay
extends VBoxContainer

signal card_count_changed(strategy: CardStrategy, count: int)

var strategy: CardStrategy
var count: int = 0

@onready var card_container = $CardContainer
@onready var count_label = $ButtonContainer/CountLabel
@onready var minus_button = $ButtonContainer/MinusButton
@onready var plus_button = $ButtonContainer/PlusButton

const CardScene = preload("res://Objects/Cards/card.tscn")

@export var card_scale: float = 1.0

func _ready() -> void:
	minus_button.pressed.connect(_on_minus_pressed)
	plus_button.pressed.connect(_on_plus_pressed)


func setup(card_strategy: CardStrategy) -> void:
	strategy = card_strategy

	# Create card visual
	var card_data = CardData.create_card_data_from_strategy(strategy)
	var card_node = CardScene.instantiate()
	card_node.card_data = card_data
	card_node.scale = Vector2(card_scale, card_scale)

	# Disable card interaction (view-only)
	card_node.remove_from_group("interactable")

	card_container.add_child(card_node)

	# Position card at center of container (container size is set in .tscn)
	var container_size = card_container.custom_minimum_size
	card_node.position = Vector2(container_size.x / 2.0, container_size.y / 2.0)

	# Make card container clickable
	card_container.gui_input.connect(_on_card_gui_input)

	update_count_label()


func set_count(new_count: int) -> void:
	count = max(0, new_count)
	update_count_label()


func update_count_label() -> void:
	count_label.text = "x%d" % count


func _on_plus_pressed() -> void:
	count += 1
	update_count_label()
	card_count_changed.emit(strategy, count)


func _on_minus_pressed() -> void:
	if count > 0:
		count -= 1
		update_count_label()
		card_count_changed.emit(strategy, count)


func _on_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_plus_pressed()
