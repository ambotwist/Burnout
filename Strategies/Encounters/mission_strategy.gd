class_name MissionStrategy
extends Resource

@export var mission_id: String
@export var title: String
@export var offer_text: String
@export_multiline var mission_description: String
@export var accept_text: String = "Accept"
@export var refuse_text: String = "Refuse"
@export var goal: MissionGoalStrategy
@export var reward: MissionRewardStrategy
@export var on_accept_cards: Array[CardStrategy] = []
@export var on_accept_card_count: int = 0
