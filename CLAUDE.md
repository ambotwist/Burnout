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
archived_cards, command_queue, focus_start_time, focus_end_time
```

**Events Autoload** (`Utils/events.gd`): Global signal bus
```gdscript
signal game_state_changed(game_state: Dictionary)
signal card_archived(archived_card: CardData)
```
- `game_state_changed`: Emitted when card played, commands executed, focus window changes, initial draw
- `card_archived`: Emitted when a card is archived (for ON_ARCHIVE reactive effects)

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

**Base Effect**: `trigger` (ON_DRAW/BEFORE_PLAY/ON_PLAY/ON_DISCARD/ON_HOLD/ON_ARCHIVE), `prerequisites`, `apply_effect(context)`

**Rule**: Effects queue commands, don't modify state directly (except FocusEffect which sets context flags)

**Built-in Effects**:
- **CardModifierEffect**: Modifies productivity/duration via targets (ADDER/MULTIPLIER)
- **CardCopyEffect**: Copies cards between piles with optional preview/animation. `archive_copy=true` archives instead of discarding
- **CardDiscardEffect**: Discards cards with optional preview (animates actual card, not copy)
- **ArchiveEffect**: Archives target cards (discard + generate productivity + track). Used by CLASSEMENT_PRIORITAIRE
- **ArchiveBonusEffect**: Buffs all archived cards with +N productivity. Used by DOSSIER_PERSISTANT
- **OnArchiveBoostEffect**: Boosts this card's productivity when any card is archived (ON_ARCHIVE trigger). Used by CENTRE_ARCHIVE
- **FocusEffect**: Creates 2-hour window where played cards get -1 duration (15 min saved)
- **PlanningEffect**: Draw N cards, player selects M, applies optional modifiers, rest shuffled back

---

## Archive System

**Archive = Discard + Generate Productivity + Track**

Archiving a card immediately generates its productivity (unlike regular discard) and tracks it for future bonuses.

**Key Components**:
- `GameManager.archived_cards: Array[CardData]` - Tracks all archived cards
- `ArchiveCardCommand` - Command that performs archive action
- `Events.card_archived` signal - Notifies when a card is archived

**How to Archive Cards**:
1. **ArchiveEffect**: Archives existing cards (e.g., CLASSEMENT_PRIORITAIRE archives random card from hand)
2. **CardCopyEffect with `archive_copy=true`**: Creates a copy and archives it (e.g., DUPLICATA)

**Archive-Related Effects**:
- **ArchiveBonusEffect** (ON_PLAY): Buffs all archived cards permanently. Example: DOSSIER_PERSISTANT gives +1 productivity to all archived cards
- **OnArchiveBoostEffect** (ON_ARCHIVE): Reacts while in hand when any card is archived. Example: CENTRE_ARCHIVE gains +1 productivity per archive

**ON_ARCHIVE Trigger**: Special trigger handled by Card node. When `card_archived` signal fires, cards in hand check for ON_ARCHIVE effects and apply them to themselves.

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

**Key**: Simulation starts from current `card_data` values (which may have modifiers from planning effect), then applies additional effects. Compares against `strategy` base values for color coding.

---

## Card Selection System (`Objects/UI/card_selection_ui.gd`)

**Purpose**: Reusable UI for player card selection (used by PlanningEffect, reusable for Scry, Mulligan, Tutor)

**Components**:
- **CardSelectionUI**: Node2D scene with dimmed background, displays cards horizontally, handles click selection
- **Selection Commands**: Modular command chain for draw → animate → wait → process selection

**Command Chain** (PlanningEffect):
```
DrawCardsToSelectionCommand → AnimateCardsToSelectionCommand → WaitForSelectionCommand
  → ReturnCardsToDrawPileCommand → ModifySelectedCardsCommand (optional) → AddSelectedCardsToPileCommand
  → CleanupSelectionUICommand
```

**Key Design**:
- CardSelectionUI handles its own input via `_input()` (independent of InputManager.interactions_enabled)
- Commands share data via `shared_data` dictionary: `selection_ui`, `drawn_cards`, `selected_cards`, `unselected_cards`
- `trigger_card_effects()` is async - awaits command execution for player interaction
- Selected cards can go to HAND or SCHEDULE (configurable)

**PlanningEffect Properties**:
```gdscript
cards_to_draw: int = 3
cards_to_select: int = 1
shuffle_remainder: bool = true
destination: GameEnums.PileType = HAND
selected_card_productivity_modifier: int = 0  # Optional buff/debuff
selected_card_duration_modifier: int = 0
```

**Example**: PREVISION_BUDGETAIRE uses PlanningEffect with `selected_card_productivity_modifier = 1`

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
2. Save `card_data` reference (card node will be freed later)
3. **Await** `BEFORE_PLAY` effects → Apply focus reduction
4. Place in schedule (update time, add to `scheduled_cards`, free card node)
5. **Await** `ON_PLAY` effects (check `effect.prerequisites`) - async for player interaction
6. Execute command queue → Update productivity → Set `previous_card`
7. Draw new card → **Emit `Events.game_state_changed`** → Hand updates card displays

**Note**: `trigger_card_effects()` is async to support effects requiring player input (e.g., PlanningEffect)

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
- `Effects/`: card_modifier_effect, card_copy_effect, card_discard_effect, archive_effect, archive_bonus_effect, on_archive_boost_effect, focus_effect, planning_effect
- `Commands/`: copy_card, create_card_visual, find_card_node, remove_card_from_pile, reparent_card, wait, animate_card, add_card_to_pile, archive_card_command
- `Commands/` (Selection): draw_cards_to_selection, animate_cards_to_selection, wait_for_selection, return_cards_to_draw_pile, modify_selected_cards, add_selected_cards_to_pile, cleanup_selection_ui
- `Objects/UI/`: card_selection_ui (scene + script)
