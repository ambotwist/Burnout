extends Resource
class_name Effect

enum Trigger {
    ON_DRAW,
    BEFORE_PLAY,
    ON_PLAY,
    ON_DISCARD,
    ON_HOLD,
}

enum Type {
    VOID,
    MODIFIER,
    SCORER,
    CARD_CREATION,
    CARD_ARCHIVATION,
    CARD_DELETION
}

var trigger_type: Trigger
var effect_type: Type
var target: Card = null
var prerequisite: Callable = func() -> bool: return true


func can_play() -> bool:
    return prerequisite.call()


func apply() -> void:
    push_error("Function must be overriden in sublcass")

