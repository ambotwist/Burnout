class_name Card
extends Node2D

var card_data: CardData
static var card_width: int
static var card_height: int

@onready var image_rect = $Node2D/Sprites/FrontSprites/ImageRect
@onready var title_label = $Texts/Title
@onready var description_label = $Texts/Description
@onready var productivity_label = $Texts/Productivity
@onready var duration_label = $Texts/Duration
@onready var collision_shape = $Node2D/Area2D/CollisionShape2D
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	add_to_group("interactable")

	if card_data:
		apply_card_data()

	card_width = $Node2D.scale.x * $Node2D/Sprites/FrontSprites/FrontSprite.texture.get_width()
	card_height = $Node2D.scale.y * $Node2D/Sprites/FrontSprites/FrontSprite.texture.get_height()

func apply_card_data() -> void:
	if card_data.strategy.image:
		image_rect.texture = card_data.strategy.image

	title_label.text = card_data.strategy.get_title()
	description_label.text = card_data.strategy.get_description()
	productivity_label.text = str(card_data.strategy.productivity)
	duration_label.text = str(card_data.strategy.duration)
