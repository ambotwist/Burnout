class_name CardModifierEffect
extends Effect

var duration_modifier: int = 0
var productivity_modifier: int = 0

func _init() -> void:
	effect_type = Effect.Effect_Type.CARD_MODIFIER

func apply():
	if target:
		# Store original duration for logging
		var original_duration = target.duration

		# Apply modifiers but ensure duration never goes below 1
		target.duration = max(1, target.duration + duration_modifier)
		target.productivity += productivity_modifier

		# Log the actual changes applied
		var actual_duration_change = target.duration - original_duration
		if actual_duration_change != 0 or productivity_modifier != 0:
			print("CardModifierEffect applied to ", target.card_name, ": duration ", actual_duration_change, " (min 1), productivity +", productivity_modifier)
	else:
		push_error("CardModifierEffect.apply(): No target set")
