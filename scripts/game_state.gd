extends Node
# Global game state singleton (autoload)
# Add to Project Settings > Autoload as "GameState"

# Time/Schedule
var current_time: int = 0
var current_slot: int = 0
var day: int = 1
var total_time_slots: int = 16

# Player resources
var energy: int = 100
var productivity_total: int = 0
var burnout_level: int = 0

# Current game state
var cards_played_today: Array[String] = []
var last_played_card: Card = null
var last_played_card_type: String = ""

# Schedule tracking
var scheduled_cards: Array = []  # Array of cards scheduled for the day

# Helper methods for time checks
func is_morning() -> bool:
	return current_time < 8

func is_afternoon() -> bool:
	return current_time >= 8 and current_time < 16

func is_early_morning() -> bool:
	return current_time < 4

func is_late_afternoon() -> bool:
	return current_time >= 12

# Check if previous card was a specific type
func was_previous_card_type(card_type: String) -> bool:
	return last_played_card_type == card_type

func was_previous_card_admin() -> bool:
	return last_played_card != null and last_played_card.color == "red"

# Reset for new day
func reset_day() -> void:
	current_time = 0
	current_slot = 0
	cards_played_today.clear()
	last_played_card = null
	last_played_card_type = ""
	scheduled_cards.clear()
	day += 1

# Update when a card is played
func on_card_played(card: Card) -> void:
	last_played_card = card
	last_played_card_type = card.color
	cards_played_today.append(card.card_name)
	current_time += card.duration
	productivity_total += card.productivity