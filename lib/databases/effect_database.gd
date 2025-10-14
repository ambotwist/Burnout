extends Node

const EffectType = Effect.Type

var card_manager: CardManager

# Call this from GameManager when it's ready
func set_game_manager(cm: CardManager) -> void:
	card_manager = cm

# --- GENERAL CARD EFFECTS ---

func archive_card(card: Card) -> void:
	var effect = Effect.new()
	effect.effect_type = EffectType.CARD_ARCHIVATION
	effect.duration_modifier += card.duration
	effect.productivity_modifier += card.productivity
	card_manager.remove_card_from_hand(card)
	card_manager.apply_effect(effect)


func choose_random_hand_card() -> Card:
	var hand = card_manager.hand.hand
	var eligible_cards = hand.filter(func(card): return card != card_manager.playing_card)
	if eligible_cards.size() == 0:
		return null
	var random_index = randi() % eligible_cards.size()
	return eligible_cards[random_index]

# --- RED DECK CARD EFFECTS ---

# Formulaire standard: +1 de prod si elle jouee apres une carte rouge
func formulaire_standard() -> Array[Effect]:
	var effect = CardModifierEffect.new()
	effect.target = card_manager.playing_card
	var last_played_card = card_manager.get_last_played_card()
	if last_played_card != null and last_played_card.get("color") == "red":
		effect.productivity_modifier += 1
	return [effect]

# Lecture' d'email: +1 de prod si accomplit le matin
func lecture_email() -> Array[Effect]:
	var effect = CardModifierEffect.new()
	if GameState.current_time < 8:
		effect.target = card_manager.playing_card
		effect.productivity_modifier += 1
	return [effect]

# Bouclement des comptes: Jouable l'apres-midi uniquement
func bouclement_comptes() -> Array[Effect]:
	var effect = EmptyEffect.new()
	effect.prerequisite = func(): return GameState.current_time >= 8
	return [effect]

# Duplicata: Cree une copie d'une carte en main, puis l'archive
func duplicata() -> Array[Effect]:
	var source_card = choose_random_hand_card()
	if source_card == null:
		print("Duplicata: No card to copy")
		return []

	print("Duplicata: Copying card %s with productivity %d" % [source_card.card_name, source_card.productivity])

	# Create the card copy effect
	var creation_effect = CardCreationEffect.new()
	creation_effect.game_manager = card_manager
	creation_effect.target = source_card

	# Archive effect will be created after the copy is made
	var archive_effect = CardArchivationEffect.new()
	archive_effect.game_manager = card_manager
	archive_effect.delay = 1.5

	# Apply creation immediately to get the card reference
	var card_copy = creation_effect.apply()
	print("Duplicata: Created copy with productivity %d" % card_copy.productivity)
	archive_effect.target = card_copy

	return [archive_effect]

# classement_prioritaire: archive une carte en main. Reduit d'une case la prochaine carte rouge jouee
func classement_prioritaire() -> Array[Effect]:
	var archive_effect = CardArchivationEffect.new()
	archive_effect.game_manager = card_manager
	archive_effect.target = choose_random_hand_card()

	# Create modifier effect for the next red card
	var modifier_effect = CardModifierEffect.new()
	modifier_effect.prerequisite = func(): return card_manager.playing_card.color == "red"
	modifier_effect.duration_modifier = -1

	# Add to play_effects_buffer to wait for next red card
	card_manager.play_effects_buffer.append(modifier_effect)
	print("Added duration modifier to play_effects_buffer, waiting for next red card")

	# Only return the archive effect for immediate processing
	return [archive_effect]	

# prevision_budgetaire: Insight (pioche 3 cartes et en choisit une), La carte pioche double sa prod de base.
func prevision_budgetaire() -> Array[Effect]:
	var draw_effect = InsightEffect.new()
	draw_effect.deck = card_manager.deck
	draw_effect.insight_count = 3
	return [draw_effect]

# dossier_persistant: +1 de prod a chaque fois que la carte a ete defaussee precedemmjent pendant la run.

# Centre d'archive: en main: gagne +1 de prod a chaque archive

# Controle qualite: +2 prod a la prochaine carte rouge piochee
