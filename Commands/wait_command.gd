class_name WaitCommand
extends GameCommand

## Command to wait for a specified duration
## Useful for creating delays between command executions (e.g., showing a card preview)
## This is a reusable command that can be used by any effect

var duration: float

func _init(wait_time: float) -> void:
	duration = wait_time


func can_execute(game_manager: GameManager) -> bool:
	return duration >= 0.0 and game_manager != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("WaitCommand: Invalid wait duration or game_manager")
		return

	if duration > 0.0:
		print("  → Waiting for ", duration, " second(s)")
		await game_manager.get_tree().create_timer(duration).timeout
	# If duration is 0, don't wait at all (instant)
