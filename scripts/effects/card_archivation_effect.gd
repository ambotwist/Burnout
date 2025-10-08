class_name CardArchivationEffect
extends Effect

var game_manager: GameManager
var delay: float = 0.0  # Optional delay before archiving


func init() -> void:
	effect_type = Effect.Effect_Type.CARD_ARCHIVATION


func apply():
	if game_manager != null and target != null:
		# Wait if delay is specified
		if delay > 0:
			await game_manager.get_tree().create_timer(delay).timeout

		game_manager.productivity += target.productivity
		game_manager.discard_card(target)
