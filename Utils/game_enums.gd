extends Node

# Deck types used across cards, targets, and game logic
enum DeckType {
	ANY = -1,      # For targeting: match any deck
	RANDOM = -2,   # For targeting: pick random deck
	NEUTRAL = 0,
	ADMIN = 1,
	TECH = 2,
	STRAIN = 3
}

# Specific card IDs (based on Resources/Cards)
enum CardID {
	ANY = -1,                    # For targeting: match any card
	RANDOM = -2,                 # For targeting: pick random card
	SELF = -3,                   # For targeting: the card with this effect
	FORMULAIRE_STANDARD = 0,
	LECTURE_EMAIL = 1,
	DUPLICATA = 2,
	PREVISION_BUDGETAIRE = 3,
	BOUCLEMENT_COMPTES = 4,
	CENTRE_ARCHIVE = 5,
	CONTROLE_QUALITE = 6,
	DOSSIER_PERSISTANT = 7,
	CLASSEMENT_PRIORITAIRE = 8,
	PAUSE_CLOPE = 9,
	ACCOUNTING_UPDATE = 10
}

# Card pile locations
enum PileType {
	ANY = -1,       # For targeting: match any pile
	RANDOM = -2,    # For targeting: pick random pile
	DRAW = 0,
	HAND = 1,
	DISCARD = 2,
	SCHEDULE = 3
}

# Target property types for modifiers
enum TargetProperty {
	DURATION,
	PRODUCTIVITY
}

# Modifier operations
enum ModifierType {
	ADDER,
	MULTIPLIER
}

# Effect triggers
enum EffectTrigger {
	ON_DRAW,
	BEFORE_PLAY,
	ON_PLAY,
	ON_DISCARD,
	ON_HOLD,
	ON_ARCHIVE  # Triggers when ANY card is archived (while this card is in hand)
}

# Preview positions for visual effects (used by commands)
enum PreviewPosition {
	SCHEDULE_CENTER,   # Center of the schedule
	HAND_CENTER,       # Center of the hand area
	DRAW_PILE,         # Draw pile position
	DISCARD_PILE,      # Discard pile position
	CUSTOM             # Use custom Vector2 (fallback)
}
