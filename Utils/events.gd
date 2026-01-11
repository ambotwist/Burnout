extends Node

## Global event bus for game-wide signals
## Emits when game state changes and cards in hand should refresh their displays
## Access via autoload: Events.game_state_changed.emit(...)

signal game_state_changed(game_state: Dictionary)

## Emits when a card is archived (for CENTRE_ARCHIVE to react while in hand)
signal card_archived(archived_card: CardData)
