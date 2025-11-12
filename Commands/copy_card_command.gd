class_name CopyCardCommand
extends GameCommand

## Command to create a copy of a CardData object
## Stores the copied CardData in shared_data for subsequent commands to use

var source_card: CardData

func _init(card: CardData) -> void:
	source_card = card


func can_execute(game_manager: GameManager) -> bool:
	return source_card != null and source_card.strategy != null


func execute(game_manager: GameManager) -> void:
	if not can_execute(game_manager):
		push_error("CopyCardCommand: Cannot copy card - invalid source")
		return

	# Create a new CardData instance from the source's strategy
	var copied_card_data = CardData.create_card_data_from_strategy(source_card.strategy)

	# Copy over current runtime values (in case they were modified by effects)
	copied_card_data.duration = source_card.duration
	copied_card_data.productivity = source_card.productivity
	copied_card_data.effects = source_card.effects.duplicate()

	# Store copied data for next command in chain
	set_shared_data("card_data", copied_card_data)

	print("  → Card copied: ", source_card.strategy.card_id)
