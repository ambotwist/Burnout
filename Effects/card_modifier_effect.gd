class_name CardModifierEffect
extends EffectStrategy

@export var target_strategies: Array[TargetStrategy]
@export var target_property: GameEnums.TargetProperty
@export var modifier: GameEnums.ModifierType
@export var modifier_value: int

func apply_effect(context: GameContext) -> void:
	# Show current card stats before any modifications
	if context.self_card:
		var prop_name = "productivity" if target_property == GameEnums.TargetProperty.PRODUCTIVITY else "duration"
		var current_value = context.self_card.productivity if target_property == GameEnums.TargetProperty.PRODUCTIVITY else context.self_card.duration
		print("  Stats before: ", context.self_card.strategy.card_id, " ", prop_name, "=", current_value)

	var all_targets: Array[CardData] = []

	# Collect targets from all strategies (OR logic)
	for strategy in target_strategies:
		if strategy:
			var targets = strategy.select_targets(context)
			for target in targets:
				# Avoid duplicates
				if target and not all_targets.has(target):
					all_targets.append(target)

	# Apply modification to all collected targets
	for target in all_targets:
		_modify_target(target)


func _modify_target(target: CardData) -> void:
	var old_value = 0
	var new_value = 0
	var property_name = ""

	match target_property:
		GameEnums.TargetProperty.DURATION:
			property_name = "duration"
			old_value = target.duration
			match modifier:
				GameEnums.ModifierType.ADDER:
					target.duration += modifier_value
				GameEnums.ModifierType.MULTIPLIER:
					target.duration *= modifier_value
			new_value = target.duration
		GameEnums.TargetProperty.PRODUCTIVITY:
			property_name = "productivity"
			old_value = target.productivity
			match modifier:
				GameEnums.ModifierType.ADDER:
					target.productivity += modifier_value
				GameEnums.ModifierType.MULTIPLIER:
					target.productivity *= modifier_value
			new_value = target.productivity

	print("    → Modified ", target.strategy.card_id, ": ", property_name, " ", old_value, " → ", new_value)
