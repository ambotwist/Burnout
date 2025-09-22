extends Control

const SCHEDULE_SLOT_SCENE_PATH = "res://scenes/schedule_slot.tscn"
const SCHEDULE_SLOT_COUNT = 12

var schedule_slots = []

func _ready() -> void:
	for i in SCHEDULE_SLOT_COUNT:
		var schedule_slot_scene = preload(SCHEDULE_SLOT_SCENE_PATH)
		var new_slot = schedule_slot_scene.instantiate()
		add_child(new_slot)
		schedule_slots.append(new_slot)
		new_slot.position = calculate_slot_position(i)

func calculate_slot_position(index):
	var slot_width = 100
	var gap = 40
	var total_width = slot_width + gap
	@warning_ignore("integer_division")
	var center_index = SCHEDULE_SLOT_COUNT / 2
	return Vector2((index - center_index) * total_width, 120)


func fill_slot(index):
	if index >= 0 and index < schedule_slots.size():
		schedule_slots[index].get_children()[0].texture = load("res://assets/schedule_slot_filled.png")
	else:
		print("Schedule is full")
