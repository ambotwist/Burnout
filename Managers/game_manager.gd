class_name GameManager
extends Node

# Class references
@export var card_manager: CardManager
@export var schedule: Control
@export var productivity_label: RichTextLabel
@export var day_label: RichTextLabel
@export var week_label: RichTextLabel
@export var discard_pile: Pile
@export var floating_text_scene: PackedScene
@export var floating_text_spawn_point: Marker2D

# Logic variables
var card_id_counter: int = 0
var card_is_over_schedule: bool = false
var scheduled_cards: Array[CardData] = []
var previous_card: CardData = null
var archived_cards: Array[CardData] = []
var total_productivity: int = 0

# Sanity tracking
var current_sanity: int = 10
var max_sanity: int = 20
const STARTING_SANITY: int = 10

# Focus window tracking
var focus_start_time: float = -1.0
var focus_end_time: float = -1.0

# Zen window tracking
var zen_start_time: float = -1.0
var zen_end_time: float = -1.0

# Urgency tracking
var just_drawn_card: CardData = null  # The most recently drawn card (for urgency checks)
var next_card_is_urgent: bool = false  # Flag to make the next drawn card urgent

# Day progression tracking
var current_day: int = 1  # Day within the current week (1-5)
var current_week: int = 1
const DAYS_PER_WEEK: int = 5


### SETUP ###

func _ready() -> void:
	if !card_manager:
		push_error("Card manager not set in game manager")
	await get_tree().process_frame # Wait for other nodes to get added to the tree
	card_manager.card_released.connect(on_card_released)
	initialize_game()


func initialize_game() -> void:
	# Use deck from DeckData if available, otherwise load all cards
	var card_strategies: Array[CardStrategy]

	if DeckData.selected_deck.size() > 0:
		card_strategies = DeckData.selected_deck.duplicate()
		DeckData.last_used_deck = DeckData.selected_deck.duplicate()
		DeckData.selected_deck.clear()  # Reset for next run
	else:
		card_strategies = load_all_card_strategies()
		DeckData.last_used_deck = card_strategies.duplicate()

	for strategy in card_strategies:
		var card_data = CardData.create_card_data_from_strategy(strategy)
		card_data.game_id = card_id_counter
		card_id_counter += 1
		card_manager.draw_pile.add_card(card_data)
	
	card_manager.draw_pile.shuffle()

	InputManager.interactions_enabled = false # Disable interactions while drawing cards

	await get_tree().create_timer(1.0).timeout
	for i in range(3):
		if card_manager.draw_pile.is_empty():
			break
		card_manager.draw_card()
		await get_tree().create_timer(0.1).timeout

	# Wait one frame to ensure Hand._ready() has connected to the signal
	await get_tree().process_frame

	# Wait for half a second to ensure all cards are in hand
	await get_tree().create_timer(0.5).timeout
	InputManager.interactions_enabled = true # Enable interactions again

	# Initialize UI labels
	update_day_label()
	update_week_label()

	# Initialize card displays after initial draw
	Events.game_state_changed.emit(_build_game_state())


func load_all_card_strategies() -> Array[CardStrategy]:
	var strategies: Array[CardStrategy] = []
	var dir = DirAccess.open("res://Resources/Cards/")

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var strategy = load("res://Resources/Cards/" + file_name) as CardStrategy
				if strategy:
					strategies.append(strategy)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_error("Could not open Resources/Cards directory")

	return strategies


### PROCESSING ###

func _process(delta: float) -> void:
	if card_manager.held_card:
		check_if_card_is_over_schedule(card_manager.held_card)
	else:
		card_is_over_schedule = false


func check_if_card_is_over_schedule(card: Card) -> void:
	if not schedule:
		push_error("Schedule not set in game manager")
		return

	var schedule_rect = schedule.get_global_rect()
	var card_position = card.global_position

	var is_over = schedule_rect.has_point(card_position)
	if is_over != card_is_over_schedule:
		card_is_over_schedule = is_over


# Apply focus reduction if the card is being played within the focus window
func apply_focus_reduction(card: Card) -> void:
	if not card or not card.card_data:
		return

	# Check if focus window is active
	if focus_start_time < 0 or focus_end_time < 0:
		return  # No active focus window

	var current_time = schedule.current_time if schedule else 0.0

	# Check if card starts within the focus window
	if current_time >= focus_start_time and current_time < focus_end_time:
		# Only reduce duration if it's greater than 1 (more than 15 minutes)
		if card.card_data.duration > 1:
			var old_duration = card.card_data.duration
			card.card_data.duration -= 1  # Reduce by 1 slot (15 minutes)
			print("  → FOCUS: Duration reduced from ", old_duration, " to ", card.card_data.duration, " (saved 15 min)")


# Apply zen reduction if the card is being played within the zen window
func apply_zen_reduction(card: Card) -> void:
	if not card or not card.card_data:
		return

	# Check if zen window is active
	if zen_start_time < 0 or zen_end_time < 0:
		return  # No active zen window

	var current_time = schedule.current_time if schedule else 0.0

	# Check if card starts within the zen window
	if current_time >= zen_start_time and current_time < zen_end_time:
		# Only reduce sanity toll if it's negative (draining cards)
		if card.card_data.strategy.sanity_toll < 0:
			var old_toll = card.card_data.strategy.sanity_toll
			# Store the zen bonus in card_data for display purposes
			card.card_data.zen_sanity_bonus = 1
			print("  → ZEN: Sanity toll will be reduced from ", old_toll, " to ", old_toll + 1, " (saved 1 sanity)")
	

func on_card_released(card: Card) -> void:
	if card_is_over_schedule:
		# Check if card can be played (play prerequisites)
		if not can_play_card(card):
			# Card cannot be played - return it to hand
			print("Cannot play card: Prerequisites not met")
			card_manager.update_cards_hand_positions()
			# TODO: Show visual feedback to player (e.g., shake animation, error message)
			return

		# Save reference to card_data before the card node is freed
		# (add_to_schedule frees the card node after animation)
		var played_card_data: CardData = card.card_data

		# Check if this is the urgent card being played immediately
		var is_playing_urgent_card = played_card_data.is_urgent and played_card_data == just_drawn_card

		# Trigger BEFORE_PLAY effects (await to handle async effects like planning)
		await trigger_card_effects(card, GameEnums.EffectTrigger.BEFORE_PLAY)

		# Apply focus reduction if card is played within focus window
		apply_focus_reduction(card)

		# Apply zen reduction if card is played within zen window
		apply_zen_reduction(card)

		# Apply urgency bonus if playing urgent card immediately (doubles productivity)
		if is_playing_urgent_card:
			apply_urgency_bonus(card)

		var slot_position = schedule.get_slot_position(played_card_data.duration)
		card_manager.add_to_schedule(card, slot_position)

		var slot_color = schedule.get_card_color(played_card_data)
		schedule.fill_slot(slot_color, played_card_data.duration)

		# Update scheduled cards (but NOT previous_card yet)
		scheduled_cards.append(played_card_data)

		print("Card played: ", played_card_data.strategy.card_id)

		# Trigger ON_PLAY effects (await to handle async effects like planning)
		# Note: card node may be freed after add_to_schedule, but played_card_data is still valid
		await trigger_card_effects(card, GameEnums.EffectTrigger.ON_PLAY)

		# Add card's final productivity to total
		total_productivity += played_card_data.productivity
		update_productivity_label()

		# Apply sanity toll
		apply_sanity_toll(played_card_data)

		# Check for day completion (win condition)
		if schedule.time_left <= 0:
			Events.day_completed.emit(current_day, total_productivity)
			return  # Day is done, skip drawing new card

		# Spawn floating text showing productivity gained
		if floating_text_scene and floating_text_spawn_point:
			var floating_text = floating_text_scene.instantiate()
			get_tree().current_scene.add_child(floating_text)
			floating_text.setup(played_card_data.productivity, floating_text_spawn_point.global_position)

		# NOW update previous_card after all effects have triggered
		previous_card = played_card_data

		# Draw a new card (after half a second delay)
		await get_tree().create_timer(0.5).timeout
		card_manager.draw_card()

		# Update just-drawn card tracking and check for urgency expiration
		_update_just_drawn_card()
		await _check_urgency_expiration()

		# Check if player is stuck (cannot complete day)
		if not can_complete_day():
			Events.day_failed.emit("No playable cards remaining")
			return

		# Notify that game state changed (previous_card updated)
		Events.game_state_changed.emit(_build_game_state())
	else:
		card_manager.update_cards_hand_positions()


# Check if a card's play prerequisites are satisfied
func can_play_card(card: Card) -> bool:
	if not card or not card.card_data:
		return false

	# If no play prerequisites, card can always be played
	if card.card_data.strategy.play_prerequisites.is_empty():
		return true

	# Build context to check prerequisites
	var game_state = {
		"hand": card_manager.hand,
		"draw_pile": card_manager.draw_pile,
		"discard_pile": discard_pile,
		"schedule": schedule,
		"current_time": schedule.current_time if schedule else 0.0,
		"time_left": schedule.time_left if schedule else 0,
		"scheduled_cards": scheduled_cards,
		"previous_card": previous_card,
		"archived_cards": archived_cards,
		"focus_start_time": focus_start_time,
		"focus_end_time": focus_end_time,
		"zen_start_time": zen_start_time,
		"zen_end_time": zen_end_time
	}

	var context = GameContext.create_for_card(card, game_state)

	# Check if ALL play prerequisites are satisfied (AND logic)
	for prerequisite in card.card_data.strategy.play_prerequisites:
		if prerequisite and not prerequisite.is_satisfied(context):
			var prerequisite_name = prerequisite.get_script().resource_path.get_file()
			print("  ✗ Prerequisite failed: ", prerequisite_name)
			return false  # If any prerequisite fails, card cannot be played

	return true  # All prerequisites passed


func play_card(card: Card) -> void:
	pass


# Update the productivity label UI
func update_productivity_label() -> void:
	if productivity_label:
		productivity_label.text = "PRODUCTIVITY: " + str(total_productivity)


func update_day_label() -> void:
	if day_label:
		day_label.text = "DAY " + str(current_day)


func update_week_label() -> void:
	if week_label:
		week_label.text = "WEEK " + str(current_week)


# Apply urgency bonus - doubles productivity when urgent card is played immediately
func apply_urgency_bonus(card: Card) -> void:
	if not card or not card.card_data:
		return

	var old_productivity = card.card_data.productivity
	card.card_data.productivity *= 2
	card.card_data.is_urgent = false
	print("  -> URGENCY: Productivity doubled from ", old_productivity, " to ", card.card_data.productivity)


# Update tracking for the most recently drawn card (for urgency mechanics)
func _update_just_drawn_card() -> void:
	just_drawn_card = null
	if not card_manager.hand.cards.is_empty():
		var last_card = card_manager.hand.cards.back()
		if last_card is Card and last_card.card_data:
			just_drawn_card = last_card.card_data

			# Apply pending urgency if flagged
			if next_card_is_urgent:
				just_drawn_card.is_urgent = true
				next_card_is_urgent = false
				# Update visual to show urgency overlay
				last_card.apply_card_data()
				print("  -> Applied URGENCY to drawn card")


## Set flag to make the next drawn card urgent (called by ApplyUrgencyToNextDrawnEffect)
func set_next_card_urgent() -> void:
	next_card_is_urgent = true


# Check for urgent cards that missed their window and need to be auto-discarded
func _check_urgency_expiration() -> void:
	for card in card_manager.hand.cards:
		if card is Card and card.card_data and card.card_data.is_urgent:
			# If this urgent card is NOT the just-drawn card, it missed its window
			if card.card_data != just_drawn_card:
				await _auto_discard_urgent_card(card)
				break  # Only discard one per turn


# Auto-discard an urgent card that missed its play window
func _auto_discard_urgent_card(card: Card) -> void:
	print("  -> URGENCY EXPIRED: Auto-discarding card")
	card.card_data.is_urgent = false
	Events.urgent_card_expired.emit(card)

	# Remove from hand
	card_manager.hand.remove_card(card)
	card_manager.update_cards_hand_positions()

	# Reparent to CardManager for animation
	var current_global_pos = card.global_position
	card.reparent(card_manager)
	card.global_position = current_global_pos

	# Animate to discard pile
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(card, "global_position", discard_pile.global_position, 0.3)
	tween.parallel().tween_property(card, "scale", Vector2(discard_pile.cards_scale, discard_pile.cards_scale), 0.3)
	tween.parallel().tween_property(card, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Add to discard pile and free the node
	discard_pile.add_card(card.card_data)
	card.queue_free()


# Apply sanity toll from a played card
# Positive sanity_toll = restore sanity, Negative sanity_toll = drain sanity
func apply_sanity_toll(card_data: CardData) -> void:
	var sanity_toll = card_data.strategy.sanity_toll + card_data.zen_sanity_bonus
	var old_sanity = current_sanity
	current_sanity = clamp(current_sanity + sanity_toll, 0, max_sanity)

	if card_data.zen_sanity_bonus > 0:
		print("Sanity: ", old_sanity, " -> ", current_sanity, " (base: ", card_data.strategy.sanity_toll, ", zen bonus: +", card_data.zen_sanity_bonus, ")")
	else:
		print("Sanity: ", old_sanity, " -> ", current_sanity, " (change: ", sanity_toll, ")")

	# Check for burnout (game over)
	if current_sanity <= 0:
		Events.burnout_triggered.emit()


## Check if player can still complete the day
## Returns true if at least one card can be played to fill remaining time
func can_complete_day() -> bool:
	# If schedule is full, day is completable (it's completed)
	if schedule.time_left <= 0:
		return true

	# Check if any card in hand fits remaining time
	for card in card_manager.hand.cards:
		if card is Card and card.card_data:
			if card.card_data.duration <= schedule.time_left:
				return true  # At least one card can be played

	# Check if there are cards to draw
	var has_cards_to_draw = not card_manager.draw_pile.is_empty()

	# If hand is not full and there are cards to draw, player might draw a playable card
	if not card_manager.hand.is_full() and has_cards_to_draw:
		return true  # Might draw a playable card

	# No playable cards and no way to get more - day cannot be completed
	return false


# Build game context and trigger card effects
# Async to support effects that queue commands requiring player interaction
func trigger_card_effects(card: Card, trigger: GameEnums.EffectTrigger) -> void:
	if not card or not card.card_data:
		return

	# Build the game state dictionary
	var game_state = {
		"hand": card_manager.hand,
		"draw_pile": card_manager.draw_pile,
		"discard_pile": discard_pile,
		"schedule": schedule,
		"current_time": schedule.current_time if schedule else 0.0,
		"time_left": schedule.time_left if schedule else 0,
		"scheduled_cards": scheduled_cards,
		"previous_card": previous_card,
		"archived_cards": archived_cards,
		"focus_start_time": focus_start_time,
		"focus_end_time": focus_end_time,
		"zen_start_time": zen_start_time,
		"zen_end_time": zen_end_time
	}

	# Create context using factory method
	var context = GameContext.create_for_card(card, game_state)

	# Apply effects that match the trigger and satisfy prerequisites
	for effect in card.card_data.effects:
		if effect and effect.trigger == trigger:
			# Check if ALL prerequisites are satisfied (AND logic)
			var prerequisites_satisfied = true
			for prerequisite in effect.prerequisites:
				if prerequisite and not prerequisite.is_satisfied(context):
					prerequisites_satisfied = false
					break  # One failed, skip this effect

			if not prerequisites_satisfied:
				continue  # Skip this effect

			# Apply the effect
			print("  → Applying effect: ", effect.get_script().resource_path.get_file())
			effect.apply_effect(context)

	# Sync focus window state from context (effects may have updated it)
	focus_start_time = context.focus_start_time
	focus_end_time = context.focus_end_time

	# Sync zen window state from context (effects may have updated it)
	zen_start_time = context.zen_start_time
	zen_end_time = context.zen_end_time

	# Notify that game state may have changed (focus/zen window updated)
	if context.focus_start_time != -1.0 or context.zen_start_time != -1.0:
		Events.game_state_changed.emit(_build_game_state())

	# Execute all queued commands after effects have been applied
	# Await to ensure commands complete before returning (e.g., player selection)
	await _execute_queued_commands(context)


# Execute all commands in the context's command queue (async to support command chains)
func _execute_queued_commands(context: GameContext) -> void:
	if context.command_queue.is_empty():
		return

	print("  → Executing ", context.command_queue.size(), " queued command(s)")

	# Process commands one by one (allows commands to queue more commands)
	while not context.command_queue.is_empty():
		var command = context.command_queue.pop_front()

		if not command.can_execute(self):
			push_warning("Command cannot be executed, stopping chain: ", command.get_script().resource_path.get_file())
			break  # Stop chain on failure (as requested)

		# Execute command (await if it's async)
		await command.execute(self)

		# If command has a next command, add it to the queue
		if command.next_command:
			context.command_queue.push_front(command.next_command)

	# Notify that game state may have changed after command execution
	Events.game_state_changed.emit(_build_game_state())


## Public method to queue a command (for use by other commands)
func queue_command(command: GameCommand, context: GameContext) -> void:
	if command:
		context.command_queue.append(command)


## Restart the game with the same deck
func restart_game() -> void:
	# Restore the last used deck for reinitialization
	DeckData.selected_deck = DeckData.last_used_deck.duplicate()
	# Reload the current scene
	get_tree().reload_current_scene()


## Start a new day - reset sanity, reshuffle deck, increment day counter
func start_new_day() -> void:
	# Progress day/week counters
	current_day += 1
	if current_day > DAYS_PER_WEEK:
		current_day = 1
		current_week += 1
		# TODO: Week completed - add rewards/new mechanics here

	current_sanity = STARTING_SANITY

	# Reset time windows
	focus_start_time = -1.0
	focus_end_time = -1.0
	zen_start_time = -1.0
	zen_end_time = -1.0

	# Reset game state
	scheduled_cards.clear()
	previous_card = null
	archived_cards.clear()
	total_productivity = 0
	update_productivity_label()
	update_day_label()
	update_week_label()
	just_drawn_card = null
	next_card_is_urgent = false

	# Reset schedule
	schedule.reset()

	# Collect cards and reshuffle
	_collect_all_cards_to_draw_pile()
	card_manager.draw_pile.shuffle()

	# Clear hand visuals
	_clear_hand()

	# Emit new day signal
	Events.new_day_started.emit(current_day)

	# Draw initial hand
	InputManager.interactions_enabled = false
	await get_tree().create_timer(0.5).timeout

	for i in range(3):
		if card_manager.draw_pile.is_empty():
			break
		card_manager.draw_card()
		await get_tree().create_timer(0.1).timeout

	await get_tree().create_timer(0.5).timeout
	InputManager.interactions_enabled = true

	Events.game_state_changed.emit(_build_game_state())


## Collect all cards from hand and discard pile back to draw pile
func _collect_all_cards_to_draw_pile() -> void:
	# Move discard pile cards to draw pile
	for card_data in discard_pile.cards.duplicate():
		card_manager.draw_pile.add_card(card_data)
	discard_pile.cards.clear()

	# Move hand cards to draw pile (card_data only, visuals freed separately)
	for card in card_manager.hand.cards:
		if card is Card and card.card_data:
			card_manager.draw_pile.add_card(card.card_data)


## Clear all card visuals from hand
func _clear_hand() -> void:
	for card in card_manager.hand.cards.duplicate():
		if is_instance_valid(card):
			card.queue_free()
	card_manager.hand.cards.clear()
	card_manager.hand.card_positions.clear()


## Show confirmation dialog for returning to deck editor
func _on_deck_editor_button_pressed() -> void:
	$"../Control/ConfirmationDialog".popup_centered()


## Return to deck editor when confirmed
func _on_deck_editor_confirmed() -> void:
	get_tree().change_scene_to_file("res://Scenes/deck_editor.tscn")


## Build game state dictionary for effect simulation and prerequisites
func _build_game_state() -> Dictionary:
	return {
		"hand": card_manager.hand,
		"draw_pile": card_manager.draw_pile,
		"discard_pile": discard_pile,
		"schedule": schedule,
		"current_time": schedule.current_time if schedule else 0.0,
		"time_left": schedule.time_left if schedule else 0,
		"scheduled_cards": scheduled_cards,
		"previous_card": previous_card,
		"archived_cards": archived_cards,
		"focus_start_time": focus_start_time,
		"focus_end_time": focus_end_time,
		"zen_start_time": zen_start_time,
		"zen_end_time": zen_end_time,
		"current_sanity": current_sanity,
		"max_sanity": max_sanity,
		"just_drawn_card": just_drawn_card,
		"current_day": current_day,
		"current_week": current_week
	}
