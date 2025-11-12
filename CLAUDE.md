# Card Game Architecture

Godot card game where players schedule task cards (8 AM - 4 PM) to maximize productivity. Uses Strategy Pattern + Command Pattern + Event Bus + Effect Simulation for data-driven design.

## Core Patterns

- **Strategy Pattern**: Cards, effects, targets, prerequisites are Godot resources
- **Command Pattern**: Effects queue commands; GameManager executes them
- **Event Bus**: Global `Events` autoload broadcasts state changes via signals
- **Effect Simulation**: Preview card buffs/debuffs before playing (Slay the Spire style)
- **Dependency Injection**: `GameContext` passes game state to effects/prerequisites

---

## Game State & Context

**GameContext** (`Utils/game_context.gd`): Structured container for effect execution
```gdscript
self_card, self_card_node, hand, draw_pile, discard_pile, schedule
current_time (8.0-16.0), time_left, scheduled_cards, previous_card
command_queue, focus_start_time, focus_end_time
```

**Events Autoload** (`Utils/events.gd`): Global signal bus
```gdscript
signal game_state_changed(game_state: Dictionary)
```
Emitted when: card played, commands executed, focus window changes, initial draw

---

## Command System

**Base**: `GameCommand` with `shared_data: Dictionary`, `next_command`, `execute()`, `can_execute()`

**Pattern**: Build chains backwards, share one dict, effects queue → GameManager executes

**Core Commands**:
- Copy/Create/Find card nodes, Remove/Reparent, Wait, Animate, AddToPile
- Pile-specific behavior: Hand reparents, Schedule updates productivity, Discard/Draw free node

---

## Card System

**CardStrategy** (Resource) → **CardData** (Runtime) → **Card** (Node2D Visual)

- CardStrategy: Template (card_id, deck, duration, productivity, effects, play_prerequisites)
- CardData: Runtime instance via `CardData.create_card_data_from_strategy()`
- Card: Visual node, displays predicted values with color coding (green=buff, red=debuff)

---

## Effect System

**Base Effect**: `trigger` (ON_DRAW/BEFORE_PLAY/ON_PLAY/ON_DISCARD/ON_HOLD), `prerequisites`, `apply_effect(context)`

**Rule**: Effects queue commands, don't modify state directly (except FocusEffect which sets context flags)

**Built-in Effects**:
- **CardModifierEffect**: Modifies productivity/duration via targets (ADDER/MULTIPLIER)
- **CardCopyEffect**: Copies cards between piles with optional preview/animation
- **CardDiscardEffect**: Discards cards with optional preview (animates actual card, not copy)
- **FocusEffect**: Creates 2-hour window where played cards get -1 duration (15 min saved)
- **DrawCardsEffect**: Draws cards from draw pile (not yet implemented)

---

## Effect Simulation (`Utils/effect_simulator.gd`)

**Purpose**: Preview card values before playing (Slay the Spire style)

**Flow**:
```
Hand receives game_state_changed signal
→ For each card: EffectSimulator.simulate_card_play(card_data, game_state)
→ Simulates BEFORE_PLAY + focus reduction + ON_PLAY effects
→ Returns predicted {productivity, duration}
→ Card displays with color coding (green=buff, red=debuff, white=unchanged)
```

**Key**: Simulation creates temporary GameContext, checks prerequisites, applies modifiers to temp values (no side effects)

---

## Targeting & Prerequisites

**TargetStrategy**: `target_card` (SELF/ANY/RANDOM/specific), `target_deck`, `target_pile`
- Returns `Array[CardData]` via `select_targets(context)`

**Prerequisite Types**:
1. **Card Prerequisites** (`CardStrategy.play_prerequisites`): Checked before placement, fail → return to hand
2. **Effect Prerequisites** (`EffectStrategy.prerequisites`): Checked before effect, fail → skip effect, card still played

**Logic**: ALL must pass (AND)

**Common**: ScheduleFitsPrerequisite, PlayedAfterCardPrerequisite, OnlyMorning/AfternoonPrerequisite

---

## Time & Schedule

**Schedule**: `SCHEDULE_SIZE = 32` (8 hours × 4, each unit = 0.25 hours = 15 min)
- `current_time`: 8.0-16.0
- `time_left`: Remaining slots
- **Time units**: `duration=1` = 15 minutes, `duration=4` = 1 hour

---

## Card Play Flow

1. `on_card_released()` → Check `play_prerequisites` (fail → return to hand)
2. Trigger `BEFORE_PLAY` effects → Apply focus reduction
3. Place in schedule (update time, add to `scheduled_cards`)
4. Trigger `ON_PLAY` effects (check `effect.prerequisites`)
5. Execute command queue → Update productivity → Set `previous_card`
6. **Emit `Events.game_state_changed`** → Hand updates card displays

---

## Quick Reference

**Create new effect**: Extend `EffectStrategy`, implement `apply_effect(context)`, create `.tres`, add to card

**Create new card**: Create `CardStrategy.tres`, add to `Resources/Cards/`, add ID to `GameEnums.CardID`

**Add buff/debuff display**: EffectSimulator auto-simulates all CardModifierEffects targeting SELF

**Debugging**:
- Effect not applying? Check `trigger`, `prerequisites`, `target_strategies`
- Buff not showing? Check prerequisite passes in simulation context
- Wrong animation? AnimateCardCommand uses pile-specific behavior (Hand: visible, Schedule: fade, Discard/Draw: fade+flip)

**Key Files**:
- `Utils/`: events, game_enums (autoload), effect_simulator, game_context, game_command
- `Strategies/`: card_strategy, card_data, effect_strategy, target_strategy, prerequisite_strategy
- `Effects/`: card_modifier_effect, card_copy_effect, card_discard_effect
- `Commands/`: copy_card, create_card_visual, find_card_node, remove_card_from_pile, reparent_card, wait, animate_card, add_card_to_pile
