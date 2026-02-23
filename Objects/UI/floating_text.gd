extends Control

@onready var label = $Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 10, 3.0)
	tween.tween_property(self,"modulate:a", 0.0, 0.5).set_delay(0.5)
	tween.chain().tween_callback(queue_free)


func setup(value: int, start_position: Vector2) -> void:
	label.text = "+" + str(value) + " Productivity"
	global_position = start_position - Vector2(label.size.x / 2, label.size.y / 2)


func setup_custom(text: String, start_position: Vector2, color: Color = Color.WHITE) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)
	global_position = start_position - Vector2(label.size.x / 2, label.size.y / 2)
