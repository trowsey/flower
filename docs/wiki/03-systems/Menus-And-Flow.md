# Menus and Flow

## Purpose
Everything outside the run: title screen, difficulty cycle, player count, character select, pause, settings, game over, credits. Scene transitions are blunt (`get_tree().change_scene_to_file`) with cross-scene state stashed on the `PartyConfig` autoload via `set_meta`. Player-facing flow: title → "New Game" → player count (1/2) → character select → main → game over → retry/menu.

## Key files
- `scripts/ui/main_menu.gd` — title screen with difficulty cycle button (procedurally inserted).
- `scripts/ui/player_count.gd` — 1P/2P chooser; detects 2nd controller.
- `scripts/ui/character_select.gd` — class picker, per-slot ready state.
- `scripts/ui/pause_menu.gd` — in-game pause overlay; embeds controls help.
- `scripts/ui/settings_menu.gd` — full settings screen (vs. pause menu's mini version).
- `scripts/ui/game_over_screen.gd` — wires to `player_died` for all players, shows recap.
- `scripts/ui/credits.gd` — static credits text.
- `scripts/transition_manager.gd` — autoload for fades (used in-run for room transitions, not menu→menu).
- `scripts/party_config.gd` — autoload that stashes the chosen party + meta dict.

## Data flow
```
MainMenu._new_game:
  PartyConfig.set_meta("difficulty_mult", 1.0|1.5|2.5)
  PartyConfig.set_meta("difficulty_name", "Normal"|"Hard"|"Hell")
  change_scene → player_count.tscn

PlayerCount._pick(count):
  PartyConfig.set_meta("requested_player_count", count)
  change_scene → character_select.tscn

CharacterSelect._ready:
  reads PartyConfig.get_meta("requested_player_count") → _two_player flag
  shows 1 or 2 slots; each slot can change class L/R and ready up
  when all ready → _start_game:
    PartyConfig.set_solo(class_id) OR set_two_player(p1, p2, -1, 1)
    change_scene → main.tscn

Main._ready:
  reads PartyConfig.slots; configures slot 0 = pre-placed Player node
  spawns Player2..N from scenes/player.tscn at SPAWN_OFFSETS[i]

In-game pause: PauseMenu listens for Esc / START → toggles get_tree().paused

GameOverScreen._ready: connects to every player's player_died.
  On any death: wait 0.5s, if _all_dead → show recap (RunStats.summary()), pause tree.
  Retry → reload_current_scene; QuitToMenu → change_scene → main_menu

TransitionManager (autoload) — fade_to_room / fade_to_floor for in-run scene
  shifts (e.g. boss arena entry). Not used between menu screens.
```

## Public API
**`PartyConfig`** (autoload `PartyConfig`):
```gdscript
var slots: Array        # [{ "character_class_id": int, "device_id": int }, ...]
func clear() / add_slot(class_id, device) / set_solo(class_id)
func set_two_player(p1_class, p2_class, p1_dev=-1, p2_dev=0)
func player_count() -> int
func get_slot(i) -> Dictionary
# Plus inherited Node.set_meta / get_meta / has_meta — used for cross-scene state:
#   "difficulty_mult", "difficulty_name", "requested_player_count"
```

**`TransitionManager`** (autoload):
```gdscript
signal transition_started; signal transition_finished
func is_transitioning() -> bool
func fade_to_room(player, target_pos, fade_duration=0.3) -> void
func fade_to_floor(player, target_pos, fade_duration=0.8) -> void
```
Builds its own `CanvasLayer` (layer=100) + ColorRect; tweens alpha to 1, repositions player, tweens back.

**Difficulty levels** (`main_menu.gd`): `["Normal", "Hard", "Hell"]` × multipliers `[1.0, 1.5, 2.5]`. Multiplier is read inside `main._spawn_wave` via `PartyConfig.get_meta("difficulty_mult", 1.0)`.

## Tests
- `tests/unit/test_party_config.gd` — slot manipulation and `set_two_player` device wiring.
- `tests/unit/test_settings.gd` — settings round-trip.
- `tests/e2e/` — at least the main-flow E2E exercises the player count → char select → main path.
- Gap: no test confirms the `requested_player_count` meta hand-off; no test for `GameOverScreen._all_dead` quorum.

## Extending
**Add a new menu screen:** new `scripts/ui/foo.gd extends Control` + matching `scenes/ui/foo.tscn`. Wire in/out via `change_scene_to_file`. If state must survive: use `PartyConfig.set_meta`.

**Add a new top-level flow option (e.g. "Continue"):** add a button to `main_menu.gd`, route through new meta state. Avoid creating new autoloads — `PartyConfig` already serves as the cross-scene whiteboard.

**Persist progression beyond a run:** add a static helper module that writes to `user://progress.cfg`, mirroring `settings.gd`'s pattern. Don't bloat `PartyConfig` with disk persistence.

**Replace blunt scene swap with a fade:** call `TransitionManager.fade_to_floor(...)` then `change_scene_to_file` after the await. Currently menu→menu transitions are instantaneous.

## Known gaps
- `change_scene_to_file` causes a hard cut between menus — no transition.
- 2P character select uses device 0 / 1 hard-coded for slot routing; arbitrary device ids aren't supported.
- Game over wait of 0.5s for revive opportunity is a hand-tuned magic number; revive itself takes 2s, so the recap may pop before a revive completes if both players die ~simultaneously.
- No "settings save" feedback in the settings menu — saves are immediate per setter, but no toast.
- No way to back out of `main` to the menu without dying or pausing.

## Spec/code mismatches
- `docs/specs/main-menu.md`: difficulty cycle was added later; verify spec includes "Normal/Hard/Hell" with `[1.0, 1.5, 2.5]` multipliers.
- The intended flow per `Home.md` is `main_menu → player_count → character_select → main`. `character_select` also accepts ESC to go back to `player_count`. There is no direct "back to main menu" path from char-select except via `player_count` → ESC.
