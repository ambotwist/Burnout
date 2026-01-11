class_name CleanupSelectionUICommand
extends GameCommand

## Command to clean up and free the selection UI after use
## Reads selection_ui from shared_data["selection_ui"]


func execute(game_manager: GameManager) -> void:
	var selection_ui = get_shared_data("selection_ui")

	if selection_ui and is_instance_valid(selection_ui):
		selection_ui.cleanup()
		selection_ui.queue_free()
		print("  -> Selection UI cleaned up")
	else:
		print("  -> No selection UI to clean up")
