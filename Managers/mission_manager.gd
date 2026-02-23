extends Node

## Tracks all mission and encounter state for the current run.
## Registered as autoload. Persists across days/weeks until game reset.

# Active missions for current week
var active_missions: Array[MissionData] = []

# Missions that were refused (permanently excluded from future offers)
var refused_mission_ids: Array[String] = []

# Missions already offered this week (each mission offered once per week)
var offered_this_week: Array[String] = []

# Card sanity buffs from completed missions (card game_id -> buff value)
var card_sanity_buffs: Dictionary = {}

# Game IDs of temporary cards injected by missions (survives past active_missions.clear())
var temporary_card_game_ids: Array[int] = []

# All loaded colleagues
var all_colleagues: Array[ColleagueStrategy] = []

signal mission_accepted(mission_data: MissionData)
signal mission_completed(mission_data: MissionData, reward_text: String)
signal mission_failed(mission_data: MissionData)
signal mission_progress_updated(mission_data: MissionData)


func _ready() -> void:
	_load_colleagues()


func _load_colleagues() -> void:
	var dir = DirAccess.open("res://Resources/Colleagues/")
	if not dir:
		push_warning("No Resources/Colleagues/ directory found")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var colleague = load("res://Resources/Colleagues/" + file_name)
			if colleague is ColleagueStrategy:
				all_colleagues.append(colleague)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("MissionManager: Loaded ", all_colleagues.size(), " colleague(s)")


## Track a card play for all active missions
func track_card_played(card_data: CardData) -> void:
	for mission_data in active_missions:
		mission_data.track_card_played(card_data)
		mission_progress_updated.emit(mission_data)


## Get available missions that can be offered this week
func get_available_missions() -> Array[MissionStrategy]:
	var available: Array[MissionStrategy] = []
	for colleague in all_colleagues:
		for mission in colleague.missions:
			if mission.mission_id in refused_mission_ids:
				continue
			if mission.mission_id in offered_this_week:
				continue
			# Don't offer missions that are already active
			var already_active = false
			for active in active_missions:
				if active.strategy.mission_id == mission.mission_id:
					already_active = true
					break
			if already_active:
				continue
			available.append(mission)
	return available


## Find the colleague who owns a given mission
func get_colleague_for_mission(mission: MissionStrategy) -> ColleagueStrategy:
	for colleague in all_colleagues:
		if mission in colleague.missions:
			return colleague
	return null


## Accept a mission. Pass game_manager to enable on-accept card injection.
func accept_mission(mission: MissionStrategy, current_week: int, game_manager = null) -> void:
	var mission_data = MissionData.create_from_strategy(mission, current_week)
	active_missions.append(mission_data)
	offered_this_week.append(mission.mission_id)

	# Inject temporary cards into draw pile if mission specifies them
	if game_manager and not mission.on_accept_cards.is_empty() and mission.on_accept_card_count > 0:
		_inject_temporary_cards(mission, game_manager)

	mission_accepted.emit(mission_data)
	print("MissionManager: Accepted mission '", mission.mission_id, "'")


## Refuse a mission (permanently excluded)
func refuse_mission(mission: MissionStrategy) -> void:
	refused_mission_ids.append(mission.mission_id)
	offered_this_week.append(mission.mission_id)
	print("MissionManager: Refused mission '", mission.mission_id, "' (permanently)")


## Process end of week: check mission completion, apply rewards
## Returns an array of result dictionaries for the results screen
func process_week_end(game_manager) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for mission_data in active_missions:
		var result: Dictionary = {}
		result["mission"] = mission_data

		if mission_data.strategy.goal.is_completed(mission_data):
			mission_data.status = MissionData.MissionStatus.COMPLETED
			var reward_text = mission_data.strategy.reward.apply_reward(mission_data, game_manager)
			result["success"] = true
			result["reward_text"] = reward_text
			mission_completed.emit(mission_data, reward_text)
			print("MissionManager: Mission '", mission_data.strategy.mission_id, "' COMPLETED - ", reward_text)
		else:
			mission_data.status = MissionData.MissionStatus.FAILED
			result["success"] = false
			result["reward_text"] = ""
			mission_failed.emit(mission_data)
			print("MissionManager: Mission '", mission_data.strategy.mission_id, "' FAILED")

		results.append(result)

	# Clear weekly state
	active_missions.clear()
	offered_this_week.clear()

	return results


## Get sanity buff for a specific card (from completed mission rewards)
func get_card_sanity_buff(card_data: CardData) -> int:
	return card_sanity_buffs.get(card_data.game_id, 0)


## Inject temporary cards into the draw pile when a mission is accepted
func _inject_temporary_cards(mission: MissionStrategy, game_manager) -> void:
	for i in range(mission.on_accept_card_count):
		# Cycle through on_accept_cards templates
		var template = mission.on_accept_cards[i % mission.on_accept_cards.size()]
		var card_data = CardData.create_card_data_from_strategy(template)
		card_data.game_id = game_manager.card_id_counter
		game_manager.card_id_counter += 1
		game_manager.card_manager.draw_pile.add_card(card_data)
		temporary_card_game_ids.append(card_data.game_id)
		print("MissionManager: Injected temporary card '", template.card_id, "' (game_id=", card_data.game_id, ")")

	game_manager.card_manager.draw_pile.shuffle()


## Remove all temporary mission cards from the draw pile (call after _collect_all_cards_to_draw_pile)
func cleanup_temporary_cards(game_manager) -> void:
	if temporary_card_game_ids.is_empty():
		return

	var removed_count = 0
	for game_id in temporary_card_game_ids:
		for card_data in game_manager.card_manager.draw_pile.cards.duplicate():
			if card_data.game_id == game_id:
				game_manager.card_manager.draw_pile.cards.erase(card_data)
				removed_count += 1
				break

	print("MissionManager: Cleaned up ", removed_count, " temporary card(s)")
	temporary_card_game_ids.clear()


## Reset all state for a new game
func reset_for_new_game() -> void:
	active_missions.clear()
	refused_mission_ids.clear()
	offered_this_week.clear()
	card_sanity_buffs.clear()
	temporary_card_game_ids.clear()
