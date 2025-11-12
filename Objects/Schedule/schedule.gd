class_name Schedule
extends Control

const TIME_SLOT_SCENE_PATH = "res://Objects/Schedule/time_slot.tscn"
const SCHEDULE_SIZE = 32  # 8 hours (8 AM to 4 PM) * 4 (each unit is 0.25 hours)

# Variables
var schedule_slots = []
var time_left = SCHEDULE_SIZE
var start_of_day := 8
var end_of_day := 16
var current_time: float = start_of_day
var schedule_height := 150
var horizontal_divider_height = 50
var time_slot_scene

func _ready() -> void:
	time_slot_scene = preload(TIME_SLOT_SCENE_PATH)
	
	# Add hour labels
	var day_length = end_of_day - start_of_day
	var grid_width = size.x / day_length
	for i in range(day_length + 1):
		var x = i * grid_width
		var hour = start_of_day + i

		var hour_label = RichTextLabel.new()
		hour_label.bbcode_enabled = true
		hour_label.add_theme_font_size_override("normal_font_size", 30)
		hour_label.text = "[center]" + str(hour) + ":00[/center]"
		hour_label.fit_content = true
		hour_label.size = Vector2(grid_width, 40)
		hour_label.position = Vector2(x - grid_width/2, 0)
		add_child(hour_label)

	queue_redraw()


func _draw():
	var day_length = end_of_day - start_of_day
	var grid_width = size.x / day_length


	draw_line(Vector2(0, horizontal_divider_height), Vector2(size.x, horizontal_divider_height), Color(1, 1, 1, 0.6), 4)

	# Draw vertical lines every 15 minutes (day_length * 4 intervals)
	for i in range(day_length * 4 + 1):
		var x = i * grid_width / 4
		if i % 4 == 0:
			# Every hour (thickest)
			draw_line(Vector2(x, horizontal_divider_height), Vector2(x, horizontal_divider_height + schedule_height), Color(1, 1, 1, 0.6), 3)
		elif i % 2 == 0:
			# Every 30 minutes (medium)
			draw_line(Vector2(x, horizontal_divider_height), Vector2(x, horizontal_divider_height + schedule_height), Color(1, 1, 1, 0.5), 2)
		else:
			# Every 15 minutes (thinnest)
			draw_line(Vector2(x, horizontal_divider_height), Vector2(x, horizontal_divider_height + schedule_height), Color(1, 1, 1, 0.3), 1)
		

func fill_slot(slot_color, slot_size):
	var day_length = end_of_day - start_of_day
	var grid_width = size.x / day_length

	# Calculate time unit size (width between lines * slot_size)
	# Each slot is now 15 minutes, so grid_width / 4
	var time_unit_size = (grid_width / 4) * slot_size

	# Calculate x position based on current_time
	var time_offset = current_time - start_of_day
	var x_position = time_offset * grid_width
	var y_position = horizontal_divider_height + 40

	var time_slot = time_slot_scene.instantiate()
	add_child(time_slot)
	time_slot.setup(slot_color, slot_size)

	var time_slot_scale_width = time_unit_size / time_slot.slot_width
	var time_slot_scale_height = grid_width/4 / time_slot.slot_height
	time_slot.scale = Vector2(time_slot_scale_width, time_slot_scale_height)
	time_slot.position = Vector2(
		x_position + time_slot_scale_width * time_slot.slot_width/2,
		y_position + time_slot_scale_height * time_slot.slot_height/2)

	# Update current_time and time_left (each slot is 0.25 hours = 15 minutes)
	current_time += slot_size * 0.25
	time_left -= slot_size


func get_slot_position(slot_size) -> Vector2:
	# Calculate and return the global position where a card should go
	var day_length = end_of_day - start_of_day
	var grid_width = size.x / day_length

	# Each slot is now 15 minutes, so grid_width / 4
	var time_unit_size = (grid_width / 4) * slot_size
	var time_offset = current_time - start_of_day
	var x_position = time_offset * grid_width
	var y_position = horizontal_divider_height + 40

	# Return global position (convert local to global)
	return global_position + Vector2(x_position + time_unit_size / 2, y_position)


func get_card_color(card_data: CardData) -> String:
	# Define colors based on card deck type or other properties
	match card_data.strategy.deck:
		GameEnums.DeckType.ADMIN:
			return "red"
		_:
			return "yellow"
