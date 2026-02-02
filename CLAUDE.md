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
zen_start_time, zen_end_time, current_sanity, max_sanity
```

**Events Autoload** (`Utils/events.gd`): Global signal bus
```gdscript
signal game_state_changed(game_state: Dictionary)
signal card_archived(archived_card: CardData)
signal burnout_triggered
signal week_ended(week_number: int)
```
- `game_state_changed`: Emitted when card played, commands executed, focus window changes, initial draw
- `card_archived`: Emitted when a card is archived (for ON_ARCHIVE reactive effects)
- `burnout_triggered`: Emitted when player sanity reaches 0 (game over)
- `week_ended`: Emitted when a week completes (after mission processing)

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

- CardStrategy: Template (card_id, deck, duration, productivity, sanity_toll, effects, play_prerequisites)
- CardData: Runtime instance via `CardData.create_card_data_from_strategy()`
- Card: Visual node, displays predicted values with color coding (green=buff, red=debuff)

---

## Sanity System

**Sanity = Player Health Resource**

Players must manage sanity to survive the work day. Reaching 0 sanity triggers "Burnout" (game over).

**Key Properties**:
- `GameManager.current_sanity`: Current sanity (starts at 10)
- `GameManager.max_sanity`: Maximum sanity (20)
- `CardStrategy.sanity_toll`: Sanity change per card (negative = drains, positive = restores)

**Key Components**:
- `SanityBar` (`Objects/UI/sanity_bar.gd`): UI health bar with animated transitions
- `BurnoutScreen` (`Objects/UI/burnout_screen.gd`): Game over overlay
- `Events.burnout_triggered` signal: Fires when sanity reaches 0

**Flow**:
1. Card played → `apply_sanity_toll()` called after ON_PLAY effects
2. `current_sanity = clamp(current_sanity + sanity_toll, 0, max_sanity)`
3. If sanity <= 0 → `Events.burnout_triggered.emit()`
4. BurnoutScreen appears, interactions disabled

**Sanity Toll Convention**:
- Negative value = cost (drains sanity, e.g., -3 means lose 3 sanity)
- Positive value = benefit (restores sanity, e.g., +2 means gain 2 sanity)
- Card UI displays explicit +/- sign (e.g., "+2" or "-3")

---

## Effect System

**Base Effect**: `trigger` (ON_DRAW/BEFORE_PLAY/ON_PLAY/ON_DISCARD/ON_HOLD/ON_ARCHIVE), `prerequisites`, `apply_effect(context)`

**Rule**: Effects queue commands, don't modify state directly (except FocusEffect/ZenEffect which set context flags)

**Built-in Effects**:
- **CardModifierEffect**: Modifies productivity/duration via targets (ADDER/MULTIPLIER)
- **CardCopyEffect**: Copies cards between piles with optional preview/animation. `archive_copy=true` archives instead of discarding
- **CardDiscardEffect**: Discards cards with optional preview (animates actual card, not copy)
- **ArchiveEffect**: Archives target cards (discard + generate productivity + track). Used by CLASSEMENT_PRIORITAIRE
- **ArchiveBonusEffect**: Buffs all archived cards with +N productivity. Used by DOSSIER_PERSISTANT
- **OnArchiveBoostEffect**: Boosts this card's productivity when any card is archived (ON_ARCHIVE trigger). Used by CENTRE_ARCHIVE
- **FocusEffect**: Creates time window where played cards get -1 duration (15 min saved). Visual: blue overlay on schedule
- **ZenEffect**: Creates time window where played cards get -1 sanity toll (only affects negative tolls). Visual: green overlay on schedule
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
→ Simulates BEFORE_PLAY + focus reduction + zen reduction + ON_PLAY effects
→ Returns predicted {productivity, duration, sanity_toll}
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
3. **Await** `BEFORE_PLAY` effects → Apply focus reduction → Apply zen reduction
4. Place in schedule (update time, add to `scheduled_cards`, free card node)
5. **Await** `ON_PLAY` effects (check `effect.prerequisites`) - async for player interaction
6. Execute command queue → Update productivity → Apply sanity toll (includes mission buff) → Set `previous_card`
7. Track card play for missions → Check for encounter trigger
8. Draw new card → **Emit `Events.game_state_changed`** → Hand updates card displays

**Note**: `trigger_card_effects()` is async to support effects requiring player input (e.g., PlanningEffect)

---

## Encounter & Mission System

**Purpose**: Colleagues offer missions during the workday. Players accept or refuse; accepted missions track progress across the current week with rewards on completion.

### Architecture

Follows the same Strategy Pattern as cards:

```
ColleagueStrategy (Resource) → MissionStrategy (Resource) → MissionData (Runtime)
                                       ↓                         ↓
                               MissionGoalStrategy        deck_cards_played tracking
                               MissionRewardStrategy      status (ACTIVE/COMPLETED/FAILED)
```

**ColleagueStrategy** (`Strategies/Encounters/colleague_strategy.gd`): Template for an NPC
```gdscript
@export var colleague_id: String        # "PAULA_LEDGER"
@export var display_name: String        # "Paula Ledger"
@export var portrait: Texture2D
@export var missions: Array[MissionStrategy]
```

**MissionStrategy** (`Strategies/Encounters/mission_strategy.gd`): Template for a mission offer
```gdscript
@export var mission_id: String
@export var title: String
@export var offer_text: String               # Dialog shown to player
@export_multiline var mission_description: String  # Goal + reward explanation
@export var accept_text: String = "Accept"
@export var refuse_text: String = "Refuse"
@export var goal: MissionGoalStrategy
@export var reward: MissionRewardStrategy
```

**MissionData** (`Strategies/Encounters/mission_data.gd`): Runtime state (RefCounted)
```gdscript
var strategy       # MissionStrategy (untyped — see circular dependency note)
var week_accepted: int
var deck_cards_played: Dictionary  # DeckType -> int
var status: MissionStatus          # ACTIVE / COMPLETED / FAILED
```

### Goals & Rewards (Extensible)

**MissionGoalStrategy** (base, `Strategies/Encounters/mission_goal_strategy.gd`):
```gdscript
@export var target_amount: int = 20
func get_progress(mission_data) -> int        # Override
func is_completed(mission_data) -> bool       # progress >= target_amount
func get_progress_text(mission_data) -> String
```

**MissionRewardStrategy** (base, `Strategies/Encounters/mission_reward_strategy.gd`):
```gdscript
func apply_reward(mission_data, game_manager) -> String   # Override — returns description
func get_reward_description(mission_data) -> String
```

**Concrete implementations**:
- `DeckTypeGoal` (`Goals/deck_type_goal.gd`): Tracks cards played by `GameEnums.DeckType`
- `CardSanityBuffReward` (`Rewards/card_sanity_buff_reward.gd`): Picks random card of target deck, applies sanity buff

### Creating New Content

**New colleague**: Create `.tres` extending ColleagueStrategy in `Resources/Colleagues/`, add to `MissionManager.all_colleagues` array in `_ready()`

**New mission**: Create `.tres` extending MissionStrategy in `Resources/Missions/`, reference it from a colleague's `missions` array

**New goal type**: Extend `MissionGoalStrategy`, override `get_progress()`. Place in `Strategies/Encounters/Goals/`

**New reward type**: Extend `MissionRewardStrategy`, override `apply_reward()` and `get_reward_description()`. Place in `Strategies/Encounters/Rewards/`

### MissionManager (Autoload)

`Managers/mission_manager.gd` — registered in `project.godot` as autoload.

**Important**: No `class_name` declaration. Autoloads are referenced by their autoload name; adding `class_name` causes Godot to resolve the identifier as the class instead of the singleton instance.

```gdscript
var active_missions: Array[MissionData] = []
var refused_mission_ids: Array[String] = []     # Permanent exclusion
var offered_this_week: Array[String] = []
var card_sanity_buffs: Dictionary = {}          # card game_id -> buff value

signal mission_accepted(mission_data: MissionData)
signal mission_completed(mission_data: MissionData, reward_text: String)
signal mission_failed(mission_data: MissionData)
signal mission_progress_updated(mission_data: MissionData)
```

Key methods: `track_card_played()`, `accept_mission()`, `refuse_mission()`, `process_week_end()`, `get_card_sanity_buff()`, `reset_for_new_game()`

### EncounterScheduler (RefCounted)

`Managers/encounter_scheduler.gd` — owned by GameManager, not in scene tree.

Extends `RefCounted` (not Node) because it needs no scene tree access and is instantiated via `.new()`.

- `schedule_encounters_for_day()`: Pre-schedules 2-3 random times (1+ morning 8-12, 1+ afternoon 12-16)
- `check_for_encounter(current_time)`: Returns true if an unvisited encounter time has been passed

### GameManager Integration Points

1. **`on_card_released()`** — after sanity toll, before drawing:
   - `MissionManager.track_card_played(card_data)` — updates mission progress
   - `encounter_scheduler.check_for_encounter()` — triggers encounter dialog if due

2. **`apply_sanity_toll()`** — includes mission buff:
   - `MissionManager.get_card_sanity_buff(card_data)` added to sanity calculation

3. **`start_new_day()`** — on week transition (day > 5):
   - `MissionManager.process_week_end()` — checks completion, applies rewards
   - Shows `MissionResultsScreen` before starting new week
   - Schedules new day's encounters

4. **`initialize_game()`** — calls `MissionManager.reset_for_new_game()`

### UI Components

- **EncounterDialogUI** (`Objects/UI/encounter_dialog_ui.gd`): Modal dialog with portrait, name, offer text, mission description (yellow), accept/refuse buttons. Blocks input via `InputManager.interactions_enabled = false`
- **MissionTrackerUI** (`Objects/UI/mission_tracker_ui.gd`): HUD element showing active mission progress (e.g., "12/20"). Visible only when a mission is active
- **MissionResultsScreen** (`Objects/UI/mission_results_screen.gd`): Week-end overlay showing mission success/failure and rewards earned

### Design Notes

- **Sanity buffs stored in MissionManager**, not on CardData, to avoid modifying immutable strategy resources
- **Buffs persist for current run only** — `reset_for_new_game()` clears them
- **Refused missions are gone forever** — creates meaningful accept/refuse choice
- **Failed day cards still count** — cards played before burnout count toward mission progress
- **Circular dependency workaround**: MissionStrategy↔MissionGoalStrategy↔MissionData form a cycle. Solved by using untyped parameters (`mission_data` instead of `mission_data: MissionData`) in goal/reward methods

---

## Quick Reference

**Create new effect**: Extend `EffectStrategy`, implement `apply_effect(context)`, create `.tres`, add to card

**Create new card**: Create `CardStrategy.tres`, add to `Resources/Cards/`, add ID to `GameEnums.CardID`

**Create new colleague**: Create `ColleagueStrategy.tres` in `Resources/Colleagues/`, add missions, register in MissionManager

**Create new mission**: Create `MissionStrategy.tres` in `Resources/Missions/` with goal + reward, add to colleague's `missions` array

**Add buff/debuff display**: EffectSimulator auto-simulates all CardModifierEffects targeting SELF

**Debugging**:
- Effect not applying? Check `trigger`, `prerequisites`, `target_strategies`
- Buff not showing? Check prerequisite passes in simulation context
- Wrong animation? AnimateCardCommand uses pile-specific behavior (Hand: visible, Schedule: fade, Discard/Draw: fade+flip)
- Mission not triggering? Check `encounter_scheduler.scheduled_times` and `MissionManager.get_available_missions()`
- Autoload "not declared"? Ensure no `class_name` on autoload scripts (use autoload name directly)

**Key Files**:
- `Utils/`: events, game_enums (autoload), effect_simulator, game_context, game_command
- `Strategies/`: card_strategy, card_data, effect_strategy, target_strategy, prerequisite_strategy
- `Strategies/Encounters/`: colleague_strategy, mission_strategy, mission_data, mission_goal_strategy, mission_reward_strategy
- `Strategies/Encounters/Goals/`: deck_type_goal
- `Strategies/Encounters/Rewards/`: card_sanity_buff_reward
- `Effects/`: card_modifier_effect, card_copy_effect, card_discard_effect, archive_effect, archive_bonus_effect, on_archive_boost_effect, focus_effect, zen_effect, planning_effect
- `Commands/`: copy_card, create_card_visual, find_card_node, remove_card_from_pile, reparent_card, wait, animate_card, add_card_to_pile, archive_card_command
- `Commands/` (Selection): draw_cards_to_selection, animate_cards_to_selection, wait_for_selection, return_cards_to_draw_pile, modify_selected_cards, add_selected_cards_to_pile, cleanup_selection_ui
- `Managers/`: game_manager, mission_manager (autoload), encounter_scheduler
- `Objects/UI/`: card_selection_ui, sanity_bar, burnout_screen, encounter_dialog_ui, mission_tracker_ui, mission_results_screen
- `Resources/Colleagues/`: paula_ledger
- `Resources/Missions/`: understaffed_reception
