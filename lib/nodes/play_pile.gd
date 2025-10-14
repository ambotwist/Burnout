@tool
extends Pile
class_name PlayPile

@export var pile_size: Vector2 = Vector2(200, 300):
	set(value):
		pile_size = value
		_update_size()

@onready var color_rect: ColorRect = $ColorRect
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_update_size()

func _update_size() -> void:
	if not is_node_ready():
		return

	if color_rect:
		# Center the ColorRect around the PlayPile position
		color_rect.position = -pile_size / 2
		color_rect.size = pile_size

	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape as RectangleShape2D
		rect_shape.size = pile_size
