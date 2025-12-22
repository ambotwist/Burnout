extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/CenterContainer/GridContainer
@onready var summary_label = $VBoxContainer/SummaryLabel
@onready var start_button = $VBoxContainer/StartButton

const DeckCardDisplayScene = preload("res://Objects/UI/deck_card_display.tscn")

var deck_counts: Dictionary = {}  # CardStrategy -> int


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	load_cards()
	update_summary()


func load_cards() -> void:
	var strategies = load_all_card_strategies()

	for strategy in strategies:
		var display = DeckCardDisplayScene.instantiate()
		grid_container.add_child(display)
		display.setup(strategy)
		display.card_count_changed.connect(_on_card_count_changed)

		# Initialize count to 0
		deck_counts[strategy] = 0


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


func _on_card_count_changed(strategy: CardStrategy, count: int) -> void:
	deck_counts[strategy] = count
	update_summary()


func update_summary() -> void:
	var total = 0
	for count in deck_counts.values():
		total += count
	summary_label.text = "Cards in deck: %d" % total


func get_deck_as_array() -> Array[CardStrategy]:
	var result: Array[CardStrategy] = []
	for strategy in deck_counts.keys():
		for i in range(deck_counts[strategy]):
			result.append(strategy)
	return result


func _on_start_pressed() -> void:
	DeckData.selected_deck = get_deck_as_array()
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")
