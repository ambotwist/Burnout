extends Node

const EffectType = Effect.Effect_Type
const CARDS = { #Cost #Duration #Productivity #Effect_Types #Title #Description
	# Red Deck
	"formulaire_standard": [2, 1, "red", [ EffectType.CARD_MODIFIER], "Basic Form", "+1 productivity if scheduled after an admin task."],
	"lecture_email": [1, 1, "red", [ EffectType.CARD_MODIFIER], "Read Inbox", "+1 productivity if scheduled in the morning."],
	"bouclement_comptes": [2, 4, "red", [ EffectType.EMPTY_EFFECT], "Close Account", "Can only be scheduled the afternoon." ],
	"duplicata": [1, 1, "red", [EffectType.CARD_CREATION, EffectType.CARD_ARCHIVATION], "Photocopy", "Creates a copy of a card in hand and ARCHIVES it."]
}
