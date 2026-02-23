class_name BossCheckOverlay
extends CanvasLayer

## Overlay that shows when the boss checks on the player.
## Two modes: "All clear" (brief) or "Caught slacking!" (longer, red).
## Auto-dismisses after a delay, emits check_dismissed for GameManager to await.

signal check_dismissed

@onready var overlay: ColorRect = $Control/Overlay
@onready var label: Label = $Control/Label


func _ready() -> void:
	visible = false


## Brief dark grey overlay — boss checked, player was working
func show_working_check() -> void:
	overlay.color = Color(0.1, 0.1, 0.1, 0.6)
	label.text = "Boss checked.\nAll clear."
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_show_and_dismiss(1.0)


## Longer dark red overlay — boss caught player slacking
func show_caught_check() -> void:
	overlay.color = Color(0.3, 0.05, 0.05, 0.7)
	label.text = "Boss caught you\nslacking!"
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_show_and_dismiss(1.5)


func _show_and_dismiss(duration: float) -> void:
	visible = true

	# Fade in
	var control = $Control
	control.modulate.a = 0.0
	var tween_in = create_tween()
	tween_in.tween_property(control, "modulate:a", 1.0, 0.2)
	await tween_in.finished

	# Hold
	await get_tree().create_timer(duration).timeout

	# Fade out
	var tween_out = create_tween()
	tween_out.tween_property(control, "modulate:a", 0.0, 0.3)
	await tween_out.finished

	check_dismissed.emit()
