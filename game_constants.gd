extends Node

# Shared enums and constants for the card game

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

# Collision masks
const COLLISION_MASK_CARD = 1