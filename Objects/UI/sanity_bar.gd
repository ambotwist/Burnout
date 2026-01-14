class_name SanityBar
extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var displayed_sanity: int = 10
var animation_duration: float = 0.3


func _ready() -> void:
	# Connect to game state changes
	Events.game_state_changed.connect(_on_game_state_changed)

	# Initialize display
	_update_display(10, 20, false)


func _on_game_state_changed(game_state: Dictionary) -> void:
	var current = game_state.get("current_sanity", 10)
	var maximum = game_state.get("max_sanity", 20)

	if current != displayed_sanity:
		_update_display(current, maximum, true)


func _update_display(current: int, maximum: int, animate: bool) -> void:
	var old_sanity = displayed_sanity
	displayed_sanity = current

	# Update progress bar max (in case it changes)
	progress_bar.max_value = maximum

	# Update label
	label.text = "SANITY: %d/%d" % [current, maximum]

	if animate:
		# Animate the progress bar
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", current, animation_duration)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)

		# Color flash on damage or heal
		if current < old_sanity:
			_flash_damage()
		elif current > old_sanity:
			_flash_heal()
	else:
		progress_bar.value = current


func _flash_damage() -> void:
	# Brief red flash when taking sanity damage
	var original_modulate = modulate
	modulate = Color(1.5, 0.5, 0.5)

	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.2)


func _flash_heal() -> void:
	# Brief green flash when gaining sanity
	var original_modulate = modulate
	modulate = Color(0.5, 1.5, 0.5)

	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.2)
