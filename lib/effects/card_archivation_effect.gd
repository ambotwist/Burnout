class_name CardArchivationEffect
extends Effect

var game_manager: GameManager
var delay: float = 0.0  # Optional delay before archiving


func init() -> void:
	effect_type = Effect.Type.CARD_ARCHIVATION


func apply():
	if game_manager != null and target != null:
		print("Archiving card %s with productivity %d" % [target.card_name, target.productivity])

		# Wait if delay is specified
		if delay > 0:
			await game_manager.get_tree().create_timer(delay).timeout

		print("Adding productivity %d to total (was %d)" % [target.productivity, GameState.productivity_total])
		GameState.productivity_total += target.productivity
		print("New total productivity: %d" % GameState.productivity_total)

		# Update UI immediately after changing productivity
		game_manager.update_ui()

		game_manager.discard_card(target)
