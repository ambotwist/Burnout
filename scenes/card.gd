extends Node2D
class_name Card

# Signals
signal mouse_entered_card(card)
signal mouse_exited_card(card)

# References
var hand_position

# Node children
var collision_shape
var sprites

# Card data
var card_name: String
var duration: int
var productivity: int
var color: String
var effect_types: Array[Effect.Effect_Type] = []
var title: String
var description: String


func _ready() -> void:
	# Initialize card setup
	scale = Vector2(GameConstants.CARD_SCRIPT_SCALE, GameConstants.CARD_SCRIPT_SCALE)
	collision_shape = $Area2D/CollisionShape2D
	sprites = $Sprites

	# Only connect signals if parent has the method (e.g., in game scene)
	if get_parent() and get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)


func copy_card() -> Card:
	var card_scene = preload("res://scenes/card.tscn")
	var new_card = card_scene.instantiate()

	# Use assign_data to properly set up the card with database info
	# This will also update all the UI labels
	new_card.assign_data(card_name)

	return new_card


# Returns a dictionary with just the card data (no scene/sprite references)
func get_card_data() -> Dictionary:
	return {
		"card_name": card_name,
		"duration": duration,
		"productivity": productivity,
		"color": color,
		"effect_types": effect_types,
		"title": title,
		"description": description
	}


func assign_data(db_card_name: String) -> void:
	const DB_CARDS = CardDatabase.CARDS
	card_name = db_card_name
	duration = DB_CARDS[db_card_name][0]
	productivity = DB_CARDS[db_card_name][1]
	color = DB_CARDS[db_card_name][2]
	effect_types.assign(DB_CARDS[db_card_name][3])
	title = DB_CARDS[db_card_name][4]
	description = DB_CARDS[db_card_name][5]

	# Update the UI labels
	if has_node("Cost"):
		$Cost.text = str(duration)
	if has_node("Value"):
		$Value.text = str(productivity)
	if has_node("Name"):
		$Name.text = title
	if has_node("Description"):
		$Description.text = description

func print_card_data() -> void:
	print(get_card_data())


# Emits signal when the cursor enters the Area2D
func _on_area_2d_mouse_entered() -> void:
	mouse_entered_card.emit(self)


# Emits signal when the cursor exits the Area2D
func _on_area_2d_mouse_exited() -> void:
	mouse_exited_card.emit(self)
