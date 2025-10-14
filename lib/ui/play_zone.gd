@tool
extends Control
class_name PlayZone

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	_update_visuals()
	resized.connect(_update_visuals)

func _update_visuals() -> void:
	if not is_node_ready():
		return

	if color_rect:
		# Make ColorRect fill the entire Control node
		color_rect.position = Vector2.ZERO
		color_rect.size = size


func fade_in_zone() -> void:
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)


func fade_out_zone() -> void:
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
