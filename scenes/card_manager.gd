extends Node2D

var screen_size

var selected_card

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size


func _process(delta: float) -> void:
	if selected_card:
		var mouse_position = get_global_mouse_position()
		selected_card.position = Vector2(
			clamp(mouse_position.x, 0, screen_size.x), 
			clamp(mouse_position.y, 0, screen_size.y))


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var detected_card = detect_card()
			if detected_card:
				selected_card = detected_card
				selected_card.current_state = GameConstants.DraggableState.MOVING
		else:
			selected_card = null


# Detects if this is a card under the cursor
func detect_card():
	# Raycast code taken from Godot documentation
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var raycast_result = space_state.intersect_point(parameters)
	
	# Check if the raycast returned anything
	if raycast_result.size() > 0:
		# In our card scene, the Area2D is the direct parent of the collider
		var card_area = raycast_result[0].collider.get_parent()
		return card_area
	else:
		return null
