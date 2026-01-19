class_name SetNextCardUrgentCommand
extends GameCommand

## Command that sets a flag to make the next drawn card urgent
## Used by ApplyUrgencyToNextDrawnEffect

func execute(game_manager: GameManager) -> void:
	game_manager.set_next_card_urgent()
	print("  -> Command: Next drawn card will be URGENT")


func can_execute(_game_manager: GameManager) -> bool:
	return true
