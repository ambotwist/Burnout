extends Node

const EffectType = Effect.Effect_Type

var game_manager: GameManager

# Call this from GameManager when it's ready
func set_game_manager(gm: GameManager) -> void:
	game_manager = gm

# --- GENERAL CARD EFFECTS ---

func archive_card(card: Card) -> void:
	var effect = Effect.new()
	effect.effect_type = EffectType.CARD_ARCHIVATION
	effect.duration_modifier += card.duration
	effect.productivity_modifier += card.productivity
	game_manager.remove_card_from_hand(card)
	game_manager.apply_effect(effect)


# --- RED DECK CARD EFFECTS ---

# +1 de prod si elle jouee apres une carte rouge
func formulaire_standard() -> Array[Effect]:
	var effect = CardModifierEffect.new()
	effect.target = game_manager.playing_card
	var last_played_card = game_manager.get_last_played_card()
	if last_played_card != null and last_played_card.get("color") == "red":
		effect.productivity_modifier += 1
	return [effect]

# +1 de prod si accomplit le matin
func lecture_email() -> Array[Effect]:
	var effect = CardModifierEffect.new()
	if game_manager.current_time < 8:
		effect.target = game_manager.playing_card
		effect.productivity_modifier += 1
	return [effect]

# Jouable l'apres-midi uniquement
func bouclement_comptes() -> Array[Effect]:
	var effect = EmptyEffect.new()
	effect.prerequisite = func(): return game_manager.current_time >= 8
	return [effect]

# Duplicata: Cree une copie d'une carte en main, puis l'archive
func duplicata() -> Array[Effect]:
	var hand = game_manager.hand.hand
	var eligible_cards = hand.filter(func(card): return card != game_manager.playing_card)

	if eligible_cards.size() == 0:
		return []

	var random_index = randi() % eligible_cards.size()
	var source_card = eligible_cards[random_index]

	# Create the card copy
	var creation_effect = CardCreationEffect.new()
	creation_effect.game_manager = game_manager
	creation_effect.target = source_card

	# Archive it after a delay
	var archive_effect = CardArchivationEffect.new()
	archive_effect.game_manager = game_manager
	archive_effect.target = source_card  # Will be updated to card_copy after creation
	archive_effect.delay = 1.5

	return [creation_effect, archive_effect]
	
		


# classement_prioritaire: archive une carte en main. Reduit d'une case la prochaine carte rouge jouee

# prevision_budgetaire: Insight (pioche 3 cartes et en choisit une), La carte pioche double sa prod de base.

# dossier_persistant: +1 de prod a chaque fois que la carte a ete defaussee precedemmjent pendant la run.

# Centre d'archive: en main: gagne +1 de prod a chaque archive

# Controle qualite: +2 prod a la prochaine carte rouge piochee
