class_name EffectSimulator
extends RefCounted

## Simulates the effects that would apply to a card without actually modifying it
## Used for previewing buff/debuff values on cards in hand

## Simulate what would happen if a card were played right now
## Returns a dictionary with predicted productivity, duration, and sanity_toll values
static func simulate_card_play(card_data: CardData, game_state: Dictionary) -> Dictionary:
	if not card_data:
		return {"productivity": 0, "duration": 0, "sanity_toll": 0}

	# Start with current card_data values (may already have modifiers applied, e.g., from planning effect)
	var result = {
		"productivity": card_data.productivity,
		"duration": card_data.duration,
		"sanity_toll": card_data.strategy.sanity_toll
	}

	# Create a temporary context for simulation (no node reference, no command queue)
	var context = _create_simulation_context(card_data, game_state)

	# Simulate BEFORE_PLAY effects
	_simulate_effects_for_trigger(card_data, context, GameEnums.EffectTrigger.BEFORE_PLAY, result)

	# Simulate focus reduction (happens between BEFORE_PLAY and ON_PLAY)
	_simulate_focus_reduction(card_data, context, result)

	# Simulate zen reduction (happens between BEFORE_PLAY and ON_PLAY)
	_simulate_zen_reduction(card_data, context, result)

	# Simulate ON_PLAY effects
	_simulate_effects_for_trigger(card_data, context, GameEnums.EffectTrigger.ON_PLAY, result)

	return result


## Create a GameContext for simulation (lightweight, no command queue)
static func _create_simulation_context(card_data: CardData, game_state: Dictionary) -> GameContext:
	var context = GameContext.new()

	# Set the card being simulated
	context.self_card = card_data
	context.self_card_node = null  # We don't have a node during simulation

	# Fill in game state
	context.hand = game_state.get("hand")
	context.draw_pile = game_state.get("draw_pile")
	context.discard_pile = game_state.get("discard_pile")
	context.schedule = game_state.get("schedule")
	context.current_time = game_state.get("current_time", 0.0)
	context.time_left = game_state.get("time_left", 0)
	context.scheduled_cards = game_state.get("scheduled_cards", [])
	context.previous_card = game_state.get("previous_card")
	context.focus_start_time = game_state.get("focus_start_time", -1.0)
	context.focus_end_time = game_state.get("focus_end_time", -1.0)
	context.zen_start_time = game_state.get("zen_start_time", -1.0)
	context.zen_end_time = game_state.get("zen_end_time", -1.0)

	return context


## Simulate effects for a specific trigger
static func _simulate_effects_for_trigger(card_data: CardData, context: GameContext, trigger: GameEnums.EffectTrigger, result: Dictionary) -> void:
	if not card_data.effects:
		return

	for effect in card_data.effects:
		if not effect or effect.trigger != trigger:
			continue

		# Check if prerequisites are satisfied
		var prerequisites_satisfied = true
		for prerequisite in effect.prerequisites:
			if prerequisite and not prerequisite.is_satisfied(context):
				prerequisites_satisfied = false
				break

		if not prerequisites_satisfied:
			continue

		# Simulate the effect (only CardModifierEffect for now)
		if effect is CardModifierEffect:
			_simulate_modifier_effect(effect, context, result)


## Simulate a CardModifierEffect
static func _simulate_modifier_effect(effect: CardModifierEffect, _context: GameContext, result: Dictionary) -> void:
	# Check if this effect targets SELF
	var targets_self = false
	for target_strategy in effect.target_strategies:
		if target_strategy and target_strategy.target_card == GameEnums.CardID.SELF:
			targets_self = true
			break

	if not targets_self:
		return  # Only simulate effects that modify the card itself

	# Apply the modification to the result
	match effect.target_property:
		GameEnums.TargetProperty.PRODUCTIVITY:
			match effect.modifier:
				GameEnums.ModifierType.ADDER:
					result.productivity += effect.modifier_value
				GameEnums.ModifierType.MULTIPLIER:
					result.productivity *= effect.modifier_value

		GameEnums.TargetProperty.DURATION:
			match effect.modifier:
				GameEnums.ModifierType.ADDER:
					result.duration += effect.modifier_value
				GameEnums.ModifierType.MULTIPLIER:
					result.duration *= effect.modifier_value


## Simulate focus reduction (from GameManager.apply_focus_reduction)
static func _simulate_focus_reduction(_card_data: CardData, context: GameContext, result: Dictionary) -> void:
	# Check if focus window is active
	if context.focus_start_time < 0 or context.focus_end_time < 0:
		return

	var current_time = context.current_time

	# Check if card would start within the focus window
	if current_time >= context.focus_start_time and current_time < context.focus_end_time:
		# Only reduce duration if it's greater than 1 (more than 15 minutes)
		if result.duration > 1:
			result.duration -= 1  # Reduce by 1 slot (15 minutes)


## Simulate zen reduction (from GameManager.apply_zen_reduction)
static func _simulate_zen_reduction(_card_data: CardData, context: GameContext, result: Dictionary) -> void:
	# Check if zen window is active
	if context.zen_start_time < 0 or context.zen_end_time < 0:
		return

	var current_time = context.current_time

	# Check if card would start within the zen window
	if current_time >= context.zen_start_time and current_time < context.zen_end_time:
		# Only reduce sanity toll if it's negative (draining cards)
		if result.sanity_toll < 0:
			result.sanity_toll += 1  # Reduce drain by 1
