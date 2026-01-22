extends CanvasLayer

@onready var control: Control = $Control
@onready var day_label: Label = $Control/DayLabel
@onready var productivity_label: Label = $Control/ProductivityLabel
@onready var continue_button: Button = $Control/VBoxContainer/ContinueButton
@onready var deck_editor_button: Button = $Control/VBoxContainer/DeckEditorButton


func _ready() -> void:
	# Start hidden
	visible = false

	# Connect to day completed signal
	Events.day_completed.connect(_on_day_completed)

	# Connect buttons
	continue_button.pressed.connect(_on_continue_pressed)
	deck_editor_button.pressed.connect(_on_deck_editor_pressed)


func _on_day_completed(day_number: int, total_productivity: int) -> void:
	# Disable game interactions
	InputManager.interactions_enabled = false

	# Update labels
	day_label.text = "DAY %d COMPLETE!" % day_number
	productivity_label.text = "Productivity: %d" % total_productivity

	# Show with fade-in animation
	visible = true
	control.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(control, "modulate:a", 1.0, 0.5)


func _on_continue_pressed() -> void:
	# Hide screen and start new day
	visible = false
	InputManager.interactions_enabled = true

	# Get GameManager and start new day
	var game_manager = get_tree().current_scene.get_node("GameManager")
	if game_manager:
		game_manager.start_new_day()


func _on_deck_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/deck_editor.tscn")
