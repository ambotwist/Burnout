extends CanvasLayer

@onready var control: Control = $Control
@onready var restart_button: Button = $Control/VBoxContainer/RestartButton
@onready var deck_editor_button: Button = $Control/VBoxContainer/DeckEditorButton


func _ready() -> void:
	# Start hidden
	visible = false

	# Connect to burnout signal
	Events.burnout_triggered.connect(_on_burnout)

	# Connect buttons
	restart_button.pressed.connect(_on_restart_pressed)
	deck_editor_button.pressed.connect(_on_deck_editor_pressed)


func _on_burnout() -> void:
	# Disable game interactions
	InputManager.interactions_enabled = false

	# Show with fade-in animation
	visible = true
	control.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(control, "modulate:a", 1.0, 0.5)


func _on_restart_pressed() -> void:
	# Reload current scene (GameManager.restart_game pattern)
	DeckData.selected_deck = DeckData.last_used_deck.duplicate()
	get_tree().reload_current_scene()


func _on_deck_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/deck_editor.tscn")
