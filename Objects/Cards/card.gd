class_name Card
extends Node2D

const DECK_BACKGROUNDS = {
	GameEnums.DeckType.NEUTRAL: preload("res://Assets/CardIllustrations/illu_card.shape.white.png"),
	GameEnums.DeckType.ADMIN: preload("res://Assets/card_front.png"),
	GameEnums.DeckType.TECH: preload("res://Assets/card_front.png"),
	GameEnums.DeckType.STRAIN: preload("res://Assets/CardIllustrations/illu_card.shape.black.png"),
}

var card_data: CardData
static var card_width: int
static var card_height: int

@onready var image_rect = $Node2D/Sprites/FrontSprites/ImageRect
@onready var front_sprite = $Node2D/Sprites/FrontSprites/FrontSprite
@onready var title_label = $Texts/Title
@onready var description_label = $Texts/Description
@onready var sanity_toll_label = $Texts/SanityToll
@onready var productivity_label = $Texts/Productivity
@onready var duration_label = $Texts/Duration
@onready var collision_shape = $Node2D/Area2D/CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var urgency_overlay = $Node2D/Sprites/FrontSprites/UrgencyOverlay

var _urgency_tween: Tween = null

func _ready() -> void:
	add_to_group("interactable")

	if card_data:
		apply_card_data()

	card_width = $Node2D.scale.x * $Node2D/Sprites/FrontSprites/FrontSprite.texture.get_width()
	card_height = $Node2D.scale.y * $Node2D/Sprites/FrontSprites/FrontSprite.texture.get_height()

	# Connect to archive events for ON_ARCHIVE effects (e.g., CENTRE_ARCHIVE)
	Events.card_archived.connect(_on_card_archived)

func apply_card_data() -> void:
	# Set deck-specific background
	var deck_type = card_data.strategy.deck
	if deck_type in DECK_BACKGROUNDS:
		front_sprite.texture = DECK_BACKGROUNDS[deck_type]

	if card_data.strategy.image:
		image_rect.texture = card_data.strategy.image

	title_label.text = card_data.strategy.get_title()
	description_label.text = card_data.strategy.get_description()
	productivity_label.text = str(card_data.productivity)
	duration_label.text = format_duration(card_data.duration)
	sanity_toll_label.text = format_sanity_toll(card_data.strategy.sanity_toll)

	# Update urgency visual overlay
	_update_urgency_visual()


func format_duration(duration_slots: int) -> String:
	# Convert slots to minutes (each slot = 15 minutes)
	var total_minutes = duration_slots * 15
	var hours = total_minutes / 60
	var minutes = total_minutes % 60

	# Format as "0h15", "1h45", etc.
	return "%dh%02d" % [hours, minutes]


func format_sanity_toll(sanity_toll: int) -> String:
	# Show explicit plus/minus sign
	# Positive = heals sanity, Negative = drains sanity
	if sanity_toll > 0:
		return "+%d" % sanity_toll
	else:
		return "%d" % sanity_toll  # Negative numbers already have minus sign


## Update card display with simulated values (shows buffs/debuffs with color coding)
func update_display_with_preview(base_productivity: int, predicted_productivity: int, base_duration: int, predicted_duration: int, base_sanity_toll: int = 0, predicted_sanity_toll: int = 0) -> void:
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

	# Update sanity toll display with color coding
	# Higher sanity toll is better (less drain or more restore)
	if predicted_sanity_toll > base_sanity_toll:
		# Sanity toll increased (less drain): show in green
		sanity_toll_label.text = format_sanity_toll(predicted_sanity_toll)
		sanity_toll_label.add_theme_color_override("default_color", Color.GREEN)
	elif predicted_sanity_toll < base_sanity_toll:
		# Sanity toll decreased (more drain): show in red
		sanity_toll_label.text = format_sanity_toll(predicted_sanity_toll)
		sanity_toll_label.add_theme_color_override("default_color", Color.RED)
	else:
		# No change: show in white
		sanity_toll_label.text = format_sanity_toll(predicted_sanity_toll)
		sanity_toll_label.remove_theme_color_override("default_color")


## Reset card display to base values (no color coding)
func reset_display_to_base() -> void:
	if not card_data:
		return

	productivity_label.text = str(card_data.strategy.productivity)
	productivity_label.remove_theme_color_override("default_color")

	duration_label.text = format_duration(card_data.strategy.duration)
	duration_label.remove_theme_color_override("default_color")

	sanity_toll_label.text = format_sanity_toll(card_data.strategy.sanity_toll)
	sanity_toll_label.remove_theme_color_override("default_color")


## Called when any card is archived - applies ON_ARCHIVE effects if this card is in hand
func _on_card_archived(_archived_card: CardData) -> void:
	# Only react if this card is in hand (has a Hand parent)
	var parent = get_parent()
	if not parent is Hand:
		return

	if not card_data:
		return

	# Check for ON_ARCHIVE effects and apply them
	for effect in card_data.effects:
		if effect and effect.trigger == GameEnums.EffectTrigger.ON_ARCHIVE:
			# Create a minimal context for the effect
			var context = GameContext.new()
			context.self_card = card_data
			context.self_card_node = self

			# Apply the effect (modifies self_card directly)
			effect.apply_effect(context)

			# Update display to show new productivity
			apply_card_data()


## Update urgency visual overlay based on card_data.is_urgent
func _update_urgency_visual() -> void:
	if not urgency_overlay:
		return

	if card_data and card_data.is_urgent:
		_show_urgency_overlay()
	else:
		_hide_urgency_overlay()


## Show pulsing red urgency overlay
func _show_urgency_overlay() -> void:
	urgency_overlay.visible = true

	# Kill existing tween if running
	if _urgency_tween and _urgency_tween.is_running():
		_urgency_tween.kill()

	# Create pulsing animation (loops infinitely)
	_urgency_tween = create_tween().set_loops()
	_urgency_tween.tween_property(urgency_overlay, "modulate:a", 0.5, 0.4)
	_urgency_tween.tween_property(urgency_overlay, "modulate:a", 0.2, 0.4)


## Hide urgency overlay
func _hide_urgency_overlay() -> void:
	if urgency_overlay:
		urgency_overlay.visible = false

	if _urgency_tween and _urgency_tween.is_running():
		_urgency_tween.kill()
		_urgency_tween = null
