extends Node

# Shared enums and constants for the card game

# Collision masks
const COLLISION_MASK_CARD = 1

# Card Dimensions
const CARD_WIDTH = 150
const CARD_HEIGHT = 210
const CARD_SCALE = 1.3
const CARD_SCALED_WIDTH = CARD_WIDTH * CARD_SCALE
const CARD_SCALED_HEIGHT = CARD_HEIGHT * CARD_SCALE

# Hand Properties
@warning_ignore("integer_division")
const HAND_Y_POSITION = 1080 - 210/2 - 50

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
