extends Node2D
class_name InputManager

signal left_mouse_button_pressed(raycast)
signal left_mouse_button_released()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Listens and receives user input
func _input(event):
	# Left click input
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			left_mouse_button_pressed.emit(raycast())
		else:
			left_mouse_button_released.emit()


# Detects if this is a card under the cursor
func raycast():
	# Raycast code taken from Godot documentation
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = GameConstants.COLLISION_MASK_CARD
	var raycast_results = space_state.intersect_point(parameters)
	if raycast_results.size() > 0:
		return get_topmost_object(raycast_results)
	else:
		return null


# Returns the highest z index object when several are detected in the raycast
func get_topmost_object(objects):
	var topmost_object = objects[0].collider.get_parent()
	for i in range (1, objects.size()):
		var current_object = objects[i].collider.get_parent()
		if current_object.z_index > topmost_object.z_index:
			topmost_object = current_object
	return topmost_object
