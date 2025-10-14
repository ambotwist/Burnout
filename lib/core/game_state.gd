extends Node


# Time/Schedule
var current_time: int = 0
var current_slot: int = 0
var day: int = 1
var total_time_slots: int = 16

# Player stats
var energy: int = 100
var productivity_total: int = 100

# Day state
var cards_played_today: Array[String] = []

# Run state
var all_cards_played: Array[String] = []

# Static id counter
static var _next_card_id: int = 0

# Helper functions
func is_morning() -> bool:
	return current_time < 8

func is_afternoon() -> bool:
	return current_time >= 8 and current_time < 16

func reset_day() -> void:
	current_time = 0
	current_slot = 0
	cards_played_today.clear()
	day += 1

# Signal processing

func on_effect_applied(duration: int, productivity: int) -> void:
	current_time += duration
	productivity_total = productivity


static func generate_unique_card_id() -> int:
	var id = _next_card_id
	_next_card_id += 1
	return id
