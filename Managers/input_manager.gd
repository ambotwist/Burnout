extends Node2D

signal left_mouse_button_pressed(raycast_result)
signal left_mouse_button_released()
signal hovered_over_object(object)
signal dehovered_from_object(object)

var hovered_object = null
var hover_grace_period: float = 0.0
var interactions_enabled: bool = true
const HOVER_GRACE_TIME: float = 0.1

func _input(event: InputEvent) -> void:
	if not interactions_enabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			left_mouse_button_pressed.emit(raycast())
		else:
			left_mouse_button_released.emit()


func _process(delta: float) -> void:
	if not interactions_enabled:
		#Clear any existing hover state when disabled
		if hovered_object:
			dehovered_from_object.emit(hovered_object)
			hovered_object = null
		return

	# Decrease grace period timer
	if hover_grace_period > 0:
		hover_grace_period -= delta

	var raycast_result = raycast()

	# New object detected
	if raycast_result and raycast_result != hovered_object:
		if hovered_object:
			dehovered_from_object.emit(hovered_object)
		hovered_object = raycast_result
		hovered_over_object.emit(hovered_object)
		hover_grace_period = HOVER_GRACE_TIME  # Start grace period

	# Lost hover - but only dehover if grace period expired
	elif !raycast_result and hovered_object and hover_grace_period <= 0:
		dehovered_from_object.emit(hovered_object)
		hovered_object = null

	# If we detect the same object during grace period, refresh the timer
	elif raycast_result == hovered_object and hover_grace_period > 0:
		hover_grace_period = HOVER_GRACE_TIME  # Refresh grace period


# Detects if this is a card under the cursor
func raycast():
	# Raycast code taken from Godot documentation
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var raycast_results = space_state.intersect_point(parameters)
	if raycast_results.size() > 0:
		return get_topmost_object(raycast_results)
	else:
		return null


# Returns the highest z index object when several are detected in the raycast
func get_topmost_object(objects):
	var topmost_object = get_interactable_from_collider(objects[0].collider)
	if not topmost_object:
		return null

	for i in range (1, objects.size()):
		var current_object = get_interactable_from_collider(objects[i].collider)
		if current_object and current_object.z_index > topmost_object.z_index:
			topmost_object = current_object
	return topmost_object

# Traverse up the scene tree to find an interactable node
# An interactable node must be in the "interactable" group
func get_interactable_from_collider(collider) -> Node:
	var node = collider
	while node:
		if node.is_in_group("interactable"):
			return node
		node = node.get_parent()
	return null
