class_name Effect
extends Resource

var effect_type: Effect_Type
var prerequisite: Callable = func() -> bool: return true
var target = null

enum Effect_Type {
    EMPTY_EFFECT,
    HOLD_EFFECT,
    CARD_MODIFIER,
    CARD_CREATION,
    CARD_ARCHIVATION,
    DRAW_EFFECT
}

func can_play() -> bool:
    var can_be_played: bool = prerequisite.call()
    if not can_be_played:
        print("Cannot play effect ", Effect_Type.keys()[effect_type], " on target ", target)
    return can_be_played

func apply():
    push_error("Effect.apply() must be overriden in subclass.")