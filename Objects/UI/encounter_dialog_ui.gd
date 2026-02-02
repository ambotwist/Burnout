class_name EncounterDialogUI
extends CanvasLayer

## Modal dialog for encounter interactions (mission offers, etc.)
## Blocks all game input until player responds.

signal response_selected(accepted: bool)

@onready var control: Control = $Control
@onready var portrait_rect: TextureRect = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Portrait
@onready var name_label: Label = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/NameLabel
@onready var dialog_text: RichTextLabel = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/DialogText
@onready var mission_info: RichTextLabel = $Control/PanelContainer/MarginContainer/VBoxContainer/MissionInfo
@onready var accept_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/AcceptButton
@onready var refuse_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/RefuseButton


func _ready() -> void:
	visible = false
	accept_button.pressed.connect(_on_accept_pressed)
	refuse_button.pressed.connect(_on_refuse_pressed)


func show_mission_offer(colleague: ColleagueStrategy, mission: MissionStrategy) -> void:
	# Disable game interactions
	InputManager.interactions_enabled = false

	# Setup UI
	if colleague.portrait:
		portrait_rect.texture = colleague.portrait
	name_label.text = colleague.display_name
	dialog_text.text = "[center]%s[/center]" % mission.offer_text
	mission_info.text = "[center]%s[/center]" % mission.mission_description
	accept_button.text = mission.accept_text
	refuse_button.text = mission.refuse_text

	# Fade in
	visible = true
	control.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(control, "modulate:a", 1.0, 0.3)


func _on_accept_pressed() -> void:
	visible = false
	InputManager.interactions_enabled = true
	response_selected.emit(true)


func _on_refuse_pressed() -> void:
	visible = false
	InputManager.interactions_enabled = true
	response_selected.emit(false)
