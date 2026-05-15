# Battle Brothers Style System Clone Plan

## Summary

This project will implement a Battle Brothers-style system clone in Godot, without copying
the original IP, text, art, or exact data. The focus is the game structure: a mercenary
company management layer connected to a tactical hex combat layer.

The first milestone is the combat core. Before building the world map, contracts, shops,
events, and long-term progression, the project needs a deterministic and testable tactical
foundation.

## Direction

- Build an original game that borrows the system shape, not the setting or content.
- Keep the project GDScript-first: logic, data, and UI composition should be implemented in
  scripts before introducing scenes or resources.
- Avoid new scene files unless they are manual test entry points or complex editor-managed
  map assets, and ask for confirmation before creating any scene file.
- Use programmer art for the initial playable version: simple shapes, colors, text labels,
  and lightweight icons are enough while validating rules.

## First Milestone: Combat Core

The first playable milestone should support:

- Hex-grid battlefield.
- Player and enemy unit deployment.
- Initiative-based turn order.
- Unit selection and legal movement.
- Adjacent melee attacks.
- Hit, damage, armor or HP reduction, death, and removal from turn order.
- Victory when all enemies are dead.
- Defeat when all player units are dead.
- Deterministic behavior when given a fixed RNG seed.

The following systems are intentionally out of scope for the first milestone:

- World map movement.
- Settlements, contracts, shops, hiring, and economy.
- Level-up, perks, injuries, morale, fatigue depth, and equipment durability.
- Dynamic events and late-game crisis systems.
- Final art, animation polish, and audio.

## Combat Domain Model

Create the combat rules as script-first, testable classes under `src/combat/`.

### CombatBoard

Responsibilities:

- Store board dimensions and valid hex cells.
- Represent axial hex coordinates using `Vector2i`.
- Return neighbors, distance, and reachable cells.
- Track blocked cells and occupied cells.
- Reject movement outside the board or through occupied cells.

### CombatUnit

Responsibilities:

- Store unit identity, team, display name, position, and alive/dead state.
- Store core combat stats:
  - HP.
  - Armor.
  - Action points.
  - Initiative.
  - Melee skill.
  - Melee defense.
  - Damage range.
  - Move range.
- Store simple equipment references such as weapon ID and armor ID.

### CombatState

Responsibilities:

- Own the active combat encounter.
- Hold the board, units, round number, active turn index, RNG seed, and battle outcome.
- Start encounters from player and enemy unit data.
- Expose legal actions for the active unit.
- Apply movement and attacks through `CombatRules`.
- Advance turns and rounds.
- Emit or expose outcome states: `ongoing`, `victory`, `defeat`.

Suggested public methods:

```gdscript
func start_encounter(player_units: Array, enemy_units: Array, board_seed: int) -> void
func get_active_unit() -> CombatUnit
func get_legal_moves(unit_id: String) -> Array[Vector2i]
func move_unit(unit_id: String, target: Vector2i) -> bool
func attack(attacker_id: String, defender_id: String) -> Dictionary
func end_turn() -> void
func get_outcome() -> String
```

### CombatRules

Responsibilities:

- Keep rule calculations separate from rendering and input.
- Calculate movement cost and reachable cells.
- Calculate melee hit chance with clamped minimum and maximum values.
- Roll deterministic attacks through a seeded RNG.
- Apply damage to armor first, then HP.
- Mark units dead when HP reaches zero.
- Decide whether a battle has ended after each action.

## Code-Based Data

Create data definitions under `src/data/` as GDScript, not `.tres` files.

Initial data should include:

- Three starting mercenaries.
- Two or three basic enemy units.
- A small weapon list, such as sword, spear, mace, and axe.
- A small armor list.
- A test encounter that can be launched directly by the combat screen or a manual test entry
  point.

The current `SaveManager` already assumes party, inventory, and world data. The first
implementation should either add the missing registry scripts it references or simplify those
references so the project can boot cleanly.

## Combat Screen

Create `src/screen/combat_screen.gd` as a code-built screen.

Expected behavior:

- Render the board with simple hex shapes.
- Render player and enemy units as colored tokens.
- Show the active unit, selected unit, movement range, and attackable targets.
- Support click-to-select, click-to-move, and click-to-attack.
- Provide a simple end-turn control.
- Emit `combat_ended(win: bool)` when the outcome is no longer ongoing.

Do not create a new scene file for this screen unless explicitly approved.

## Test Plan

Add focused GUT tests under `test/unit/` for:

- Hex neighbor and distance calculations.
- Legal movement and blocked movement.
- Occupied cells preventing movement.
- Initiative ordering and action point reset.
- Deterministic hit and damage with fixed RNG seed.
- Death removing a unit from future turns.
- Victory and defeat detection.
- Save/load compatibility for any updated party schema.

Manual verification:

- Restore the local `./godot` symlink according to `doc/setup.md`.
- Run the project.
- Enter the combat screen.
- Move units, attack, end turns, and finish a battle.

## Assumptions

- The project is a system clone, not a content clone.
- The first milestone prioritizes a testable combat engine over world-map features.
- The initial visual layer uses programmer art.
- New scene files are not created without confirmation.
- Data is stored in GDScript classes and registries rather than `.tres` resources.

## Explore Screen Implementation Plan

### Summary

Add a code-built explore screen that displays the world map background and lets the player
move a character marker to the clicked position. This screen becomes the first campaign
entry point, with combat remaining available through a test button.

### Key Changes

- Add `src/screen/explore_screen.gd` as a script-only screen.
- Create the map background in code with `Sprite2D` and `res://asset/map.jpg`.
- Create a simple player marker in code until character art exists.
- Move the marker to the mouse click position with a short `Tween`.
- Add `ScreenManager.Screen.EXPLORE` and route it to `explore_screen.gd`.
- Change `TitleScreen` so "새 캠페인" opens `Screen.EXPLORE`.
- Add an explore-screen "전투 테스트" button that opens `Screen.COMBAT`.

### Input Behavior

- Left-clicking the map moves the character marker to that world position.
- Clicks on UI controls should not trigger movement.
- Movement is direct screen/world-coordinate movement for this milestone, with no pathfinding.

### Test Plan

- Confirm `Screen.EXPLORE` exists and is handled in `ScreenManager._create_screen()`.
- Confirm "새 캠페인" transitions from the title screen to the explore screen.
- Confirm `asset/map.jpg` appears as a `Sprite2D` background.
- Confirm left-clicking the map moves the character marker.
- Confirm "전투 테스트" opens the combat screen.
- Confirm "타이틀로" returns to the title screen.

### Assumptions

- No new `.tscn` files are created.
- `asset/map.jpg` remains the initial 1280x720 explore-map background.
- The initial character representation is a simple code-drawn marker.
- Explore movement is visual only and does not update save data yet.
