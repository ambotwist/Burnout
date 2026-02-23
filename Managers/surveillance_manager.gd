class_name SurveillanceManager
extends RefCounted

## Boss surveillance system — randomly checks if player is slacking.
## Per 15-min slot check: a card with duration N gets N independent probability rolls.
## Catching a neutral card = infraction + danger escalation.

# Danger levels: 0=LOW, 1=MEDIUM, 2=HIGH
var danger_level: int = 0
var weekly_infractions: int = 0

const DANGER_PROBABILITIES: Array[float] = [0.10, 0.20, 0.30]
const DANGER_NAMES: Array[String] = ["LOW", "MEDIUM", "HIGH"]


## Roll per 15-min slot. Returns { boss_checked, is_slacking, voided }.
func check_card(card_data: CardData) -> Dictionary:
	var result = {
		"boss_checked": false,
		"is_slacking": false,
		"voided": false
	}

	var probability = DANGER_PROBABILITIES[danger_level]

	# Roll once per 15-min slot (duration = number of slots)
	for i in range(card_data.duration):
		if randf() < probability:
			result.boss_checked = true
			break  # One catch is enough

	if not result.boss_checked:
		return result

	# Boss checked — determine if slacking (neutral deck)
	var is_neutral = card_data.strategy.deck == GameEnums.DeckType.NEUTRAL
	result.is_slacking = is_neutral

	if is_neutral:
		result.voided = true
		weekly_infractions += 1
		_escalate_danger()
		print("SurveillanceManager: Caught slacking! Danger: ", get_danger_text(), " Infractions: ", weekly_infractions)
	else:
		print("SurveillanceManager: Boss checked — all clear.")

	return result


## Get current danger level as text
func get_danger_text() -> String:
	return DANGER_NAMES[danger_level]


## Reset weekly infractions (called at week end)
func reset_weekly_infractions() -> void:
	weekly_infractions = 0


## Reset everything for a new game
func reset_for_new_game() -> void:
	danger_level = 0
	weekly_infractions = 0


## Escalate danger level (caps at HIGH)
func _escalate_danger() -> void:
	if danger_level < DANGER_NAMES.size() - 1:
		danger_level += 1
		print("SurveillanceManager: Danger escalated to ", get_danger_text())
