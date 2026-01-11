class_name Card
extends Node2D

var card_data: CardData
static var card_width: int
static var card_height: int

@onready var image_rect = $Node2D/Sprites/FrontSprites/ImageRect
@onready var title_label = $Texts/Title
@onready var description_label = $Texts/Description
@onready var sanity_toll_label = $Texts/SanityToll
@onready var productivity_label = $Texts/Productivity
@onready var duration_label = $Texts/Duration
@onready var collision_shape = $Node2D/Area2D/CollisionShape2D
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	add_to_group("interactable")

	if card_data:
		apply_card_data()

	card_width = $Node2D.scale.x * $Node2D/Sprites/FrontSprites/FrontSprite.texture.get_width()
	card_height = $Node2D.scale.y * $Node2D/Sprites/FrontSprites/FrontSprite.texture.get_height()

	# Connect to archive events for ON_ARCHIVE effects (e.g., CENTRE_ARCHIVE)
	Events.card_archived.connect(_on_card_archived)

func apply_card_data() -> void:
	if card_data.strategy.image:
		image_rect.texture = card_data.strategy.image

	title_label.text = card_data.strategy.get_title()
	description_label.text = card_data.strategy.get_description()
	productivity_label.text = str(card_data.productivity)
	duration_label.text = format_duration(card_data.duration)
	sanity_toll_label.text = str(card_data.strategy.sanity_toll)


func format_duration(duration_slots: int) -> String:
	# Convert slots to minutes (each slot = 15 minutes)
	var total_minutes = duration_slots * 15
	var hours = total_minutes / 60
	var minutes = total_minutes % 60

	# Format as "0h15", "1h45", etc.
	return "%dh%02d" % [hours, minutes]


## Update card display with simulated values (shows buffs/debuffs with color coding)
func update_display_with_preview(base_productivity: int, predicted_productivity: int, base_duration: int, predicted_duration: int) -> void:
	# Update productivity display with color coding
	if predicted_productivity > base_productivity:
		# Buff: show in green
		productivity_label.text = str(predicted_productivity)
		productivity_label.add_theme_color_override("default_color", Color.GREEN)
	elif predicted_productivity < base_productivity:
		# Debuff: show in red
		productivity_label.text = str(predicted_productivity)
		productivity_label.add_theme_color_override("default_color", Color.RED)
	else:
		# No change: show in white
		productivity_label.text = str(predicted_productivity)
		productivity_label.remove_theme_color_override("default_color")

	# Update duration display with color coding
	if predicted_duration < base_duration:
		# Duration reduction is a buff (less time spent): show in green
		duration_label.text = format_duration(predicted_duration)
		duration_label.add_theme_color_override("default_color", Color.GREEN)
	elif predicted_duration > base_duration:
		# Duration increase is a debuff (more time spent): show in red
		duration_label.text = format_duration(predicted_duration)
		duration_label.add_theme_color_override("default_color", Color.RED)
	else:
		# No change: show in white
		duration_label.text = format_duration(predicted_duration)
		duration_label.remove_theme_color_override("default_color")


## Reset card display to base values (no color coding)
func reset_display_to_base() -> void:
	if not card_data:
		return

	productivity_label.text = str(card_data.strategy.productivity)
	productivity_label.remove_theme_color_override("default_color")

	duration_label.text = format_duration(card_data.strategy.duration)
	duration_label.remove_theme_color_override("default_color")


## Called when any card is archived - applies ON_ARCHIVE effects if this card is in hand
func _on_card_archived(_archived_card: CardData) -> void:
	# Only react if this card is in hand (has a Hand parent)
	var parent = get_parent()
	if not parent is Hand:
		return

	if not card_data:
		return

	print("  -> Card in hand received archive event: ", card_data.strategy.card_id)

	# Check for ON_ARCHIVE effects and apply them
	for effect in card_data.effects:
		if effect and effect.trigger == GameEnums.EffectTrigger.ON_ARCHIVE:
			print("  -> Found ON_ARCHIVE effect on: ", card_data.strategy.card_id)
			# Create a minimal context for the effect
			var context = GameContext.new()
			context.self_card = card_data
			context.self_card_node = self

			# Apply the effect (modifies self_card directly)
			effect.apply_effect(context)

			# Update display to show new productivity
			apply_card_data()
