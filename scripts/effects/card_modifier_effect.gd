class_name CardModifierEffect
extends Effect

var duration_modifier: int = 0
var productivity_modifier: int = 0

func _init() -> void:
	effect_type = Effect.Effect_Type.CARD_MODIFIER

func apply():  
	if target:
		target.duration += duration_modifier
		target.productivity += productivity_modifier
		if duration_modifier != 0 or productivity_modifier != 0:
			print("CardModifierEffect applied to ", target.card_name, ": duration +", duration_modifier, ", productivity +", productivity_modifier)
	else:
		push_error("CardModifierEffect.apply(): No target set")
