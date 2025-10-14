extends Node

const EffectType = Effect.Type
var CARDS = { #Duration #Productivity #Color #Title #Description #Prerequisite #Trigger #Types
	# Red Deck
	"formulaire_standard": [
		2,
		1,
		"admin",
		"Sequential Filing",
		"+1 productivity if scheduled after an Admin task.",
		get_prerequisite(""),
		Effect.Trigger.ON_PLAY,
		[Effect.Type.MODIFIER]
	],
	"lecture_email": [
		1,
		1,
		"admin",
		"Read Inbox",
		"+1 productivity if scheduled in the morning.",
		get_prerequisite(""),
		Effect.Trigger.ON_PLAY,
		[Effect.Type.MODIFIER]
	],
	"bouclement_comptes": [
		2,
		4,
		"admin",
		"Report Rush",
		"Can only be scheduled in the afternoon.",
		get_prerequisite("afternoon_only"),
		Effect.Trigger.ON_PLAY,
		[Effect.Type.VOID]
	],
	"duplicata": [
		1,
		1,
		"admin",
		"Photocopy",
		"Creates a copy of a card in hand and ARCHIVES it.",
		get_prerequisite(""),
		Effect.Trigger.ON_PLAY,
		[Effect.Type.CARD_CREATION, Effect.Type.CARD_ARCHIVATION]
	],
	"classement_prioritaire": [
		2,
		2,
		"admin",
		"Folder Organization",
		"ARCHIVES a card in hand. Reduces the duration of the next Admin task.",
		get_prerequisite(""),
		Effect.Trigger.ON_PLAY,
		[Effect.Type.CARD_ARCHIVATION, Effect.Type.MODIFIER]
	],
	"prevision_budgetaire": [
		2,
		2,
		"admin",
		"Project Forecast",
		"INSIGHT. The chosen card doubles its productivity.",
		get_prerequisite(""),
		Effect.Trigger.ON_PLAY,
		[Effect.Type.MODIFIER]
	]
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
		"":
			return func() -> bool: return true  # No prerequisite
		_:
			return func() -> bool: return true  # Default to no restriction
