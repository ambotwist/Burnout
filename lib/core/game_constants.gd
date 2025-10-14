extends Node

# Shared enums and constants for the card game

# Collision masks
const COLLISION_MASK_CARD = 1

# Card Dimensions
const CARD_WIDTH = 110
const CARD_HEIGHT = 170
const CARD_EDITOR_SCALE = 2.0
const CARD_SCRIPT_SCALE = 1.0
const CARD_SCALED_WIDTH = CARD_WIDTH * CARD_EDITOR_SCALE
const CARD_SCALED_HEIGHT = CARD_HEIGHT * CARD_EDITOR_SCALE

# Enumeration of possible interaction states for cards
enum DraggableState {
	IDLE,
	HOVERING,
	HOLDING,
	MOVING
}

# State transition rules
const ALLOWED_TRANSITIONS = {
	DraggableState.IDLE: [DraggableState.HOVERING, DraggableState.HOLDING, DraggableState.MOVING],
	DraggableState.HOVERING: [DraggableState.IDLE, DraggableState.HOLDING, DraggableState.MOVING],
	DraggableState.HOLDING: [DraggableState.IDLE, DraggableState.MOVING],
	DraggableState.MOVING: [DraggableState.IDLE]
}
