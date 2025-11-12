# Card Game Architecture

Godot card game where players schedule task cards (8 AM - 4 PM) to maximize productivity. Uses Strategy Pattern + Command Pattern + Dependency Injection for data-driven design.

## Core Architecture

```
GameManager → GameContext → Effects → Commands → CardManager/Piles
```

**Key Patterns:**
- **Strategy Pattern**: Cards, effects, targets, prerequisites are Godot resources
- **Command Pattern**: Effects queue commands; GameManager executes them
- **Dependency Injection**: `GameContext` passes game state to effects/prerequisites

---

## GameContext (`Utils/game_context.gd`)

Structured container holding game state:

```gdscript
class GameContext:
    var self_card: CardData
    var self_card_node: Card
    var hand: Hand
    var draw_pile: Pile
    var discard_pile: Pile
    var schedule: Schedule
    var current_time: float        # 8.0-16.0
    var time_left: int             # Remaining 0.5hr slots
    var scheduled_cards: Array[CardData]
    var previous_card: CardData
    var command_queue: Array[GameCommand]
```

---

## Command System

### Base Command (`Utils/game_command.gd`)
```gdscript
class GameCommand:
    var shared_data: Dictionary = {}
    var next_command: GameCommand = null

    func execute(game_manager: GameManager) -> void  # Async
    func can_execute(game_manager: GameManager) -> bool
```

### Command Chaining
Build chains backwards, share one `Dictionary`:

```gdscript
var shared = {}
var add_cmd = AddCardToPileCommand.new(DISCARD)
add_cmd.shared_data = shared
var animate_cmd = AnimateCardCommand.new(DISCARD, pos, scale)
animate_cmd.shared_data = shared
animate_cmd.set_next_command(add_cmd)
context.command_queue.append(animate_cmd)
```

### Core Commands
- **CopyCardCommand**: Copies CardData → `shared_data["card_data"]`
- **CreateCardVisualCommand**: Creates Card node → `shared_data["card_node"]`
- **FindCardNodeCommand**: Finds existing Card node from CardData → `shared_data["card_node"]`
- **RemoveCardFromPileCommand**: Removes card from its current pile array (updates hand positions)
- **ReparentCardCommand**: Reparents card to CardManager while preserving global position
- **WaitCommand**: Async delay for previews
- **AnimateCardCommand**: Animates card using CardManager, pile-specific fade/flip
- **AddCardToPileCommand**: Pile-specific handling (Hand reparents, Schedule updates productivity, Discard/Draw free node)

### Execution Flow
```
Effects queue commands → GameManager._execute_queued_commands()
→ Pop, check can_execute(), await execute(), queue next_command if exists
```

---

## Card System

```
CardStrategy (Resource) → CardData (Runtime) → Card (Node2D Visual)
```

**CardStrategy** (`Strategies/card_strategy.gd`): Template with `card_id`, `deck`, `duration`, `productivity`, `effects`, `play_prerequisites`

**CardData** (`Strategies/card_data.gd`): Runtime instance, created via `CardData.create_card_data_from_strategy()`

---

## Effect System

### Base Effect (`Strategies/effect_strategy.gd`)
```gdscript
@export var trigger: GameEnums.EffectTrigger
@export var prerequisites: Array[PrerequisiteStrategy]
func apply_effect(context: GameContext) -> void
```

**Triggers**: `ON_DRAW`, `BEFORE_PLAY`, `ON_PLAY`, `ON_DISCARD`, `ON_HOLD`

**Rule**: Effects queue commands, don't modify state directly.

### CardModifierEffect
Modifies `duration`/`productivity`:
```gdscript
@export var target_strategies: Array[TargetStrategy]
@export var target_property: GameEnums.TargetProperty
@export var modifier: GameEnums.ModifierType  # ADDER/MULTIPLIER
@export var modifier_value: int
```

### CardCopyEffect
Copies cards between piles with optional preview:
```gdscript
@export var target_strategy: TargetStrategy
@export var destination_pile: GameEnums.PileType
@export var show_preview: bool
@export var preview_position: GameEnums.PreviewPosition
@export var preview_duration: float
@export var animate_to_pile: bool
```

Builds chain: `CopyCard → CreateVisual → Wait → Animate → AddToPile`

### CardDiscardEffect
Discards cards with optional preview (animates actual card, not a copy):
```gdscript
@export var target_strategy: TargetStrategy
@export var show_preview: bool
@export var preview_position: GameEnums.PreviewPosition
@export var preview_duration: float
@export var animate_to_pile: bool
```

Builds chain: `FindCardNode → RemoveFromPile → Reparent → AnimateToPreview → Wait → AnimateToDiscard → AddToPile`

---

## Targeting System (`Strategies/target_strategy.gd`)

```gdscript
@export var target_card: GameEnums.CardID = ANY  # SELF/ANY/RANDOM/specific
@export var target_deck: GameEnums.DeckType = ANY
@export var target_pile: GameEnums.PileType = ANY
func select_targets(context: GameContext) -> Array[CardData]
```

**Special values**: `ANY` (all), `RANDOM` (one random), `SELF` (current card)

---

## Prerequisite System

**Two types:**

### Card Prerequisites
- Location: `CardStrategy.play_prerequisites`
- When: Before placement
- Fail: Card returns to hand

### Effect Prerequisites
- Location: `EffectStrategy.prerequisites`
- When: Before effect applies
- Fail: Effect skipped, card still played

**Logic**: ALL must pass (AND)

**Common prerequisites:**
- `ScheduleFitsPrerequisite`: `card.duration <= context.time_left`
- `PlayedAfterCardPrerequisite`: `context.previous_card` matches filters
- `OnlyAfternoonPrerequisite`: `context.current_time >= 12.0`

---

## Enums (`Utils/game_enums.gd`)

```gdscript
enum DeckType { ANY=-1, RANDOM=-2, NEUTRAL=0, ADMIN=1, TECH=2 }
enum CardID { ANY=-1, RANDOM=-2, SELF=-3, ... }
enum PileType { ANY=-1, RANDOM=-2, DECK=0, HAND=1, DISCARD=2, SCHEDULE=3 }
enum TargetProperty { DURATION, PRODUCTIVITY }
enum ModifierType { ADDER, MULTIPLIER }
enum EffectTrigger { ON_DRAW, BEFORE_PLAY, ON_PLAY, ON_DISCARD, ON_HOLD }
enum PreviewPosition { SCHEDULE_CENTER, HAND_CENTER, DRAW_PILE, DISCARD_PILE, CUSTOM }
```

---

## Schedule System (`Objects/Schedule/schedule.gd`)

```gdscript
const SCHEDULE_SIZE = 16  # 8 hours × 2 (0.5hr units)
var current_time: float   # 8.0-16.0
var time_left: int
```

**Time units**: 1 = 0.5 hours. `duration=2` = 1 hour.

---

## Card Play Flow

1. Player releases card → `GameManager.on_card_released()`
2. Check `play_prerequisites` (ALL must pass) → else return to hand
3. Trigger `BEFORE_PLAY` effects
4. Place card in schedule (update `current_time`, `time_left`, add to `scheduled_cards`)
5. Trigger `ON_PLAY` effects (check `effect.prerequisites`)
6. Execute command queue (`_execute_queued_commands()`)
7. Update productivity, set `previous_card`

---

## File Structure

```
Commands/          # copy_card, create_card_visual, find_card_node, remove_card_from_pile, reparent_card, wait, animate_card, add_card_to_pile
Effects/           # card_modifier_effect, card_copy_effect, card_discard_effect
Managers/          # game_manager, card_manager
Objects/Cards/     # card.gd
Objects/Piles/     # pile, hand, draw_pile, discard_pile
Objects/Schedule/  # schedule.gd
Prerequisites/     # schedule_fits, played_after_card, only_afternoon
Resources/         # Cards/, Effects/ (.tres files)
Strategies/        # card_strategy, card_data, effect_strategy, target_strategy, prerequisite_strategy
Utils/             # game_enums (autoload), game_context, game_command
```

---

## Quick Reference

**Create new effect:**
1. Extend `EffectStrategy`, implement `apply_effect(context)`
2. Add `@export` vars, create `.tres`, add to card

**Create new card:**
1. Create `CardStrategy.tres`, set properties/effects/prerequisites
2. Add to `Resources/Cards/`, add ID to `GameEnums.CardID`

**Common issue - effect not applying:**
- Check `trigger` matches timing
- Check `prerequisites` pass
- Check `target_strategies` returns cards

**Common issue - wrong animation:**
- `AnimateCardCommand` uses pile-specific behavior automatically
- Hand: visible, Schedule: fade out, Discard/Draw: fade + flip
