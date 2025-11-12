class_name DrawPile
extends Pile

@onready var back_sprite = $Sprites/BackSprite
@onready var text_label = $Label

func _process(delta: float) -> void:
	if is_empty():
		back_sprite.visible = false
		text_label.visible = false
	else:
		back_sprite.visible = true
		text_label.visible = true
