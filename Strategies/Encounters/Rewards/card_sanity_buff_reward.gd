class_name CardSanityBuffReward
extends MissionRewardStrategy

@export var target_deck: GameEnums.DeckType = GameEnums.DeckType.ADMIN
@export var base_sanity_bonus: int = 2
@export var bonus_per_extra: int = 1
@export var extra_cards_threshold: int = 5


func calculate_total_bonus(mission_data) -> int:
	var progress = mission_data.deck_cards_played.get(target_deck, 0)
	var goal_amount = mission_data.strategy.goal.target_amount
	var extra_cards = max(0, progress - goal_amount)
	var extra_bonus = (extra_cards / extra_cards_threshold) * bonus_per_extra
	return base_sanity_bonus + extra_bonus


func apply_reward(mission_data, game_manager) -> String:
	var total_bonus = calculate_total_bonus(mission_data)

	# Find all cards of the target deck type in the draw pile
	var eligible_cards: Array[CardData] = []
	for card_data in game_manager.card_manager.draw_pile.cards:
		if card_data.strategy.deck == target_deck:
			eligible_cards.append(card_data)

	# Also check hand and discard pile
	for card in game_manager.card_manager.hand.cards:
		if card is Card and card.card_data and card.card_data.strategy.deck == target_deck:
			eligible_cards.append(card.card_data)

	for card_data in game_manager.discard_pile.cards:
		if card_data.strategy.deck == target_deck:
			eligible_cards.append(card_data)

	if eligible_cards.is_empty():
		return "No eligible cards found for reward"

	# Pick a random card and apply the sanity buff
	var target_card: CardData = eligible_cards.pick_random()
	MissionManager.card_sanity_buffs[target_card.game_id] = total_bonus

	var card_name = target_card.strategy.get_title()
	return "%s received +%d sanity" % [card_name, total_bonus]


func get_reward_description(mission_data) -> String:
	var total_bonus = calculate_total_bonus(mission_data)
	return "+%d sanity to a random ADMIN card" % total_bonus
