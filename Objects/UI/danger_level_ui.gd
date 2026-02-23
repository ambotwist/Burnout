class_name DangerLevelUI
extends RichTextLabel

## HUD element displaying current boss surveillance danger level.
## Listens to game_state_changed and reads danger_level from the state.

const DANGER_COLORS = {
	"LOW": "green",
	"MEDIUM": "yellow",
	"HIGH": "red"
}


func _ready() -> void:
	Events.game_state_changed.connect(_on_game_state_changed)
	bbcode_enabled = true
	fit_content = true
	_update_display("LOW")


func _on_game_state_changed(game_state: Dictionary) -> void:
	if game_state.has("danger_level"):
		_update_display(game_state["danger_level"])


func _update_display(danger_text: String) -> void:
	var color = DANGER_COLORS.get(danger_text, "white")
	text = "[center]DANGER: [color=%s]%s[/color][/center]" % [color, danger_text]
