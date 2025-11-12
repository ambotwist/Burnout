class_name DiscardPile
extends Pile

@onready var empty_slot_sprite = $Sprites/EmptySlotSprite
@onready var card_back_sprite = $Sprites/CardBackSprite


func _process(delta: float) -> void:
	if is_empty():
		empty_slot_sprite.visible = true
		card_back_sprite.visible = false
	else:
		empty_slot_sprite.visible = false
		card_back_sprite.visible = true
