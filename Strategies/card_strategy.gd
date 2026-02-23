class_name CardStrategy
extends Resource

# Logic variables
@export var card_id: String
@export var deck: GameEnums.DeckType
@export var duration: int
@export var productivity: int
@export var sanity_toll: int
@export var effects: Array[EffectStrategy]
@export var play_prerequisites: Array[PrerequisiteStrategy]
@export var image: Texture2D
@export var tags: Array[String] = []


func has_tag(tag: String) -> bool:
	return tags.has(tag)


# Get localized title
func get_title() -> String:
	return tr("CARD_" + card_id + "_TITLE")

# Get localized description
func get_description() -> String:
	return tr("CARD_" + card_id + "_DESC")
