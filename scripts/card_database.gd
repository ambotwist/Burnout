extends Node

const EffectType = Effect.Effect_Type
const CARDS = { #Cost #Duration #Productivity #Effect_Types #Title #Description #Prerequisite
	# Red Deck
	"formulaire_standard": [2, 1, "red", [ EffectType.CARD_MODIFIER], "Doc Review", "+1 productivity if scheduled after an admin task.", ""],
	"lecture_email": [1, 1, "red", [ EffectType.CARD_MODIFIER], "Read Inbox", "+1 productivity if scheduled in the morning.", ""],
	"bouclement_comptes": [2, 4, "red", [ EffectType.EMPTY_EFFECT], "Close Account", "Can only be scheduled the afternoon.", "afternoon_only"],
	"duplicata": [1, 1, "red", [EffectType.CARD_CREATION, EffectType.CARD_ARCHIVATION], "Photocopy", "Creates a copy of a card in hand and ARCHIVES it.", ""],
	"classement_prioritaire": [2, 2, "red", [EffectType.CARD_ARCHIVATION, EffectType.CARD_MODIFIER], "Archive Task", "ARCHIVES a card in hand. Reduces the duration of the next admin task.", ""],
	"prevision_budgetaire": [2, 2, "red", [EffectType.DRAW_EFFECT], "Budget Cut", "INSIGHT. The chosen card doubles its productivity.", ""]
}

# Prerequisite functions - return true if the card can be played
func get_prerequisite(prerequisite_id: String) -> Callable:
	match prerequisite_id:
		"morning_only":
			return func() -> bool:
				return GameState.is_morning()
		"afternoon_only":
			return func() -> bool:
				return GameState.is_afternoon()
		"after_admin":
			return func() -> bool:
				return GameState.was_previous_card_admin()
		"early_morning":
			return func() -> bool:
				return GameState.is_early_morning()
		"late_afternoon":
			return func() -> bool:
				return GameState.is_late_afternoon()
		"":
			return func() -> bool: return true  # No prerequisite
		_:
			return func() -> bool: return true  # Default to no restriction
