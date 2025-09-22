extends Node2D
class_name Card

# Signals
signal mouse_entered_card(card)
signal mouse_exited_card(card)

var hand_position
var collision_shape

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals to the parent (Card Manager)
	get_parent().connect_card_signals(self)
	# Set scale defined in the GameConstants file
	scale = Vector2(GameConstants.CARD_SCALE, GameConstants.CARD_SCALE)
	# Set reference to the CollisionShape2D
	collision_shape = $Area2D/CollisionShape2D

# Emits signal when the cursor enters the Area2D
func _on_area_2d_mouse_entered() -> void:
	mouse_entered_card.emit(self)


# Emits signal when the cursor exits the Area2D
func _on_area_2d_mouse_exited() -> void:
	mouse_exited_card.emit(self)
