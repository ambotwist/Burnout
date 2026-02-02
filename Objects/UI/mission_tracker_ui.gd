extends Control

## Small HUD element showing active mission progress.
## Only visible when a mission is active.

@onready var mission_label: RichTextLabel = $MissionLabel
@onready var progress_label: RichTextLabel = $ProgressLabel


func _ready() -> void:
	visible = false
	Events.game_state_changed.connect(_on_game_state_changed)
	MissionManager.mission_accepted.connect(_on_mission_accepted)
	MissionManager.mission_progress_updated.connect(_on_progress_updated)


func _on_mission_accepted(mission_data: MissionData) -> void:
	_update_display(mission_data)
	visible = true


func _on_progress_updated(mission_data: MissionData) -> void:
	_update_display(mission_data)


func _on_game_state_changed(_game_state: Dictionary) -> void:
	if MissionManager.active_missions.is_empty():
		visible = false
		return

	# Show the first active mission
	_update_display(MissionManager.active_missions[0])
	visible = true


func _update_display(mission_data: MissionData) -> void:
	mission_label.text = mission_data.strategy.title
	progress_label.text = mission_data.strategy.goal.get_progress_text(mission_data)
