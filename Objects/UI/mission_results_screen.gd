extends CanvasLayer

## Shows mission results at end of week (after day complete screen).
## Displays success/failure and rewards earned.

@onready var control: Control = $Control
@onready var title_label: Label = $Control/PanelContainer/VBoxContainer/TitleLabel
@onready var results_label: RichTextLabel = $Control/PanelContainer/VBoxContainer/ResultsText
@onready var continue_button: Button = $Control/PanelContainer/VBoxContainer/ContinueButton

signal results_dismissed


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)


## Show mission results. results is an Array of Dictionaries with keys:
## "mission" (MissionData), "success" (bool), "reward_text" (String)
func show_results(results: Array[Dictionary]) -> void:
	InputManager.interactions_enabled = false

	title_label.text = "WEEK COMPLETE"

	var text = ""
	for result in results:
		var mission_data: MissionData = result["mission"]
		var success: bool = result["success"]
		var mission_title = mission_data.strategy.title

		if success:
			text += "[color=green]COMPLETED:[/color] " + mission_title + "\n"
			text += "  Reward: " + result["reward_text"] + "\n"
		else:
			var progress = mission_data.strategy.goal.get_progress_text(mission_data)
			text += "[color=red]FAILED:[/color] " + mission_title + "\n"
			text += "  Progress: " + progress + "\n"
		text += "\n"

	if results.is_empty():
		text = "No active missions this week."

	results_label.text = text

	# Fade in
	visible = true
	control.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(control, "modulate:a", 1.0, 0.5)


func _on_continue_pressed() -> void:
	visible = false
	InputManager.interactions_enabled = true
	results_dismissed.emit()
