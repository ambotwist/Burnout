class_name GameManager
extends Node

# Class references
@export var card_manager: CardManager
@export var schedule: Control
@export var productivity_label: RichTextLabel
@export var discard_pile: Pile
@export var floating_text_scene: PackedScene
@export var floating_text_spawn_point: Marker2D

# Logic variables
var card_id_counter: int = 0
var card_is_over_schedule: bool = false
var scheduled_cards: Array[CardData] = []
var previous_card: CardData = null
var total_productivity: int = 0

# Focus window tracking
var focus_start_time: float = -1.0
var focus_end_time: float = -1.0


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
		DeckData.selected_deck.clear()  # Reset for next run
	else:
		card_strategies = load_all_card_strategies()

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

		# Trigger BEFORE_PLAY effects (await to handle async effects like planning)
		await trigger_card_effects(card, GameEnums.EffectTrigger.BEFORE_PLAY)

		# Apply focus reduction if card is played within focus window
		apply_focus_reduction(card)

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
		"focus_start_time": focus_start_time,
		"focus_end_time": focus_end_time
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
		"focus_start_time": focus_start_time,
		"focus_end_time": focus_end_time
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

	# Notify that game state may have changed (focus window updated)
	if context.focus_start_time != -1.0:
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
		"focus_start_time": focus_start_time,
		"focus_end_time": focus_end_time
	}
