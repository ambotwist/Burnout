extends Node

## Global event bus for game-wide signals
## Emits when game state changes and cards in hand should refresh their displays
## Access via autoload: Events.game_state_changed.emit(...)

signal game_state_changed(game_state: Dictionary)

## Emits when a card is archived (for CENTRE_ARCHIVE to react while in hand)
signal card_archived(archived_card: CardData)

## Emits when player sanity reaches 0 (game over / burnout)
signal burnout_triggered

## Emits when an urgent card's window expires and it needs to be auto-discarded
signal urgent_card_expired(card: Card)

## Emits when the day is completed (schedule filled)
signal day_completed(day_number: int, total_productivity: int)

## Emits when player cannot complete the day (no playable cards)
signal day_failed(reason: String)

## Emits when a new day starts (after win screen)
signal new_day_started(day_number: int)
