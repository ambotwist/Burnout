extends Control

const TIME_SLOT_SCENE_PATH = "res://scenes/time_slot.tscn"
const SCHEDULE_SIZE = 12

var time_slot_scene
var schedule_slots = []
var time_left = SCHEDULE_SIZE
var start_of_day := 8
var end_of_day := 16
var schedule_height := 150
var current_time: float = start_of_day
var horizontal_divider_height = 50

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

	# Draw vertical lines + time labels
	for i in range(day_length * 2 + 1):
		var x = i * grid_width / 2
		if i % 2 == 0:
			draw_line(Vector2(x, horizontal_divider_height), Vector2(x, horizontal_divider_height + schedule_height), Color(1, 1, 1, 0.6), 3)
		else:
			draw_line(Vector2(x, horizontal_divider_height), Vector2(x, horizontal_divider_height + schedule_height), Color(1, 1, 1, 0.4), 1)
		

func fill_slot(slot_color, slot_size):
	var day_length = end_of_day - start_of_day
	var grid_width = size.x / day_length

	# Calculate time unit size (width between 2 lines * slot_size)
	var time_unit_size = (grid_width / 2) * slot_size

	# Calculate x position based on current_time
	var time_offset = current_time - start_of_day
	var x_position = time_offset * grid_width
	var y_position = horizontal_divider_height + 40

	# Create and add time slot instance
	var time_slot = time_slot_scene.instantiate()
	time_slot.setup(slot_color, slot_size)
	var time_slot_scale_width = time_unit_size / time_slot.slot_width
	var time_slot_scale_height = grid_width/2 / time_slot.slot_height
	time_slot.scale = Vector2(time_slot_scale_width, time_slot_scale_height)
	time_slot.position = Vector2(
		x_position + time_slot_scale_width * time_slot.slot_width/2,
		y_position + time_slot_scale_height * time_slot.slot_height/2)
	add_child(time_slot)

	# Update current_time
	current_time += slot_size * 0.5
