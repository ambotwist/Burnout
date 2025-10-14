extends Node2D
class_name Card

# Scene
var card_scene

# Signals
signal mouse_entered_card(card)
signal mouse_exited_card(card)

# Class references
var parent: Pile

# Node children
var collision_shape
var sprites
var animation_player

# Card data
var id: int
var type: String
var duration: int
var productivity: int
var deck: String
var title: String
var description: String
var prerequisite: Callable = func() -> bool: return true
var effect_trigger: Effect.Trigger
var effect_types: Array


func _ready() -> void:
	card_scene = preload("res://lib/nodes/card.tscn")
	collision_shape = $Area2D/CollisionShape2D
	sprites = $Sprites
	animation_player = $AnimationPlayer


func copy_card() -> Card:
	var new_card = card_scene.instantiate()
	new_card.assign_data(id)
	return new_card 


func get_data() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"duration": duration,
		"productivity": productivity,
		"deck": deck,
		"title": title,
		"description": description,
		"effect_trigger": effect_trigger,
		"effect_types": effect_types,
		"prerequisite": prerequisite
	}


func assign_data(card_data: CardData) -> void:
	id = card_data.id
	type = card_data.type
	duration = card_data.duration
	productivity = card_data.productivity
	deck = card_data.deck
	title = card_data.title
	description = card_data.description
	prerequisite = card_data.prerequisite
	effect_trigger = card_data.effect_trigger
	effect_types = card_data.effect_types

	# Update UI labels
	$Cost.text = str(duration)
	$Value.text = str(productivity)
	$Name.text = title
	$Description.text = description


func print_data() -> void:
	print("Card data for ", title, " card:")
	print(get_data())


func is_playable() -> bool:
	if prerequisite and prerequisite is Callable:
		return prerequisite.call()
	return true 


### --- Signal Processing --- ###

func _on_area_2d_mouse_entered() -> void:
	mouse_entered_card.emit(self)


func _on_area_2d_mouse_exited() -> void:
	mouse_exited_card.emit(self)
