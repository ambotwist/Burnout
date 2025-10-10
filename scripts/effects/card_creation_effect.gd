class_name CardCreationEffect
extends Effect

var game_manager

func _init() -> void:
	effect_type = Effect.Effect_Type.CARD_CREATION


func apply():
	if game_manager != null:
		var card_copy = target.copy_card()
		game_manager.add_card_to_game(card_copy, Vector2(0, 0))
		return card_copy
		
