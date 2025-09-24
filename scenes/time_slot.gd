extends Node2D

# Sprite texture
var sprite_atlas_texture: AtlasTexture

# Slot variables
var slot_colors = ["red", "blue", "yellow"]
var x_origin
var y_origin
var slot_width
var slot_height = 28

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Setup function to choose the correct slot color and size
func setup(slot_color, slot_size):
	if slot_color not in slot_colors:
		print("Given slot color not in accepted set (", slot_colors, ")")
		return
	if slot_size < 1 or slot_size > 4:
		print("Given slot size not in accepted range (1 to 4)")
		return

	match slot_color:
		"red":
			y_origin = 2
		"yellow":
			y_origin = 34
		"blue":
			y_origin = 66

	match slot_size:
		1:
			x_origin = 2
			slot_width = 28
		2:
			x_origin = 36
			slot_width = 56
		3:
			x_origin = 102
			slot_width = 84
		4:
			x_origin = 192
			slot_width = 112

	# Use Sprite2D region instead of AtlasTexture for better memory efficiency
	var sprite = $Sprite2D
	sprite.texture = ($Sprite2D.texture as AtlasTexture).atlas
	sprite.region_enabled = true
	sprite.region_rect = Rect2(x_origin, y_origin, slot_width, slot_height)
