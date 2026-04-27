# Spec: Main Menu

## Goal
A polished entry point for Flower modeled on the conventions of modern action
RPGs (Diablo IV, Last Epoch, Path of Exile, Hades). The player is dropped into
the main menu on launch — never directly into the game world — and can flow to
character select, settings, credits, or quit without going through gameplay.

## Source of inspiration
| Game | Pattern adopted |
|------|-----------------|
| Diablo IV | Big stylized title, vertical button stack, settings categorized by tab |
| Hades | Buttons highlight on hover/focus with subtle motion |
| Last Epoch | Player count chosen *before* character select for couch co-op |
| Streets of Rage 4 | "Press any button" prompt to claim a controller as P1 |

## Scenes & Flow

```
main_menu.tscn
  ├─ New Game     → player_count.tscn → character_select.tscn → main.tscn
  ├─ Settings     → settings_menu.tscn (back returns here)
  ├─ Credits      → credits.tscn (back returns here)
  └─ Quit         → quit_to_OS()
```

The character_select scene already exists; this spec removes its built-in 1P/2P
toggle (the choice now happens upstream in `player_count.tscn`).

## main_menu.tscn

### Layout
- Centered title: **FLOWER**
- Subtitle: *"A bouquet of demons"*
- Vertical button stack: New Game, Settings, Credits, Quit
- Background: dark vignette + subtle ColorRect tint matching `Color(0.06, 0.04, 0.08)`
- Version string anchored bottom-left
- Build hash / git SHA, if available, anchored bottom-right (dev only)

### Input
- **Keyboard:** Up/Down or W/S to move focus, Enter/Space to confirm, Esc on first menu does nothing
- **Controller:** D-pad or left stick to move focus, A/X to confirm, B/Circle to back out (no-op on root)
- First button auto-focused so controller-only users can navigate without touching mouse

### Behavior
- `New Game` → `change_scene_to_file("res://scenes/ui/player_count.tscn")`
- `Settings` → push settings overlay (or change scene, simpler)
- `Credits` → change scene
- `Quit` → `get_tree().quit()`

## player_count.tscn

### Layout
- Title: "How many players?"
- Two large cards: **1 PLAYER** (default) and **2 PLAYERS**
- Below 2P card: "Press any button on the second controller to join"
- Back button (or Esc) returns to main menu

### Behavior
- 1P: confirms with Enter / A → loads character select with `_two_player=false`
- 2P: requires a second controller (any joypad button event with `device != 0`)
  to "register" before confirm is enabled
- Selected count is written to `PartyConfig` as a transient hint; the actual
  character class assignment happens in character_select.

## settings_menu.tscn

Categories presented as tabs or sections. All values persisted via
`scripts/settings.gd` (`user://settings.cfg`).

### Audio
- Master volume slider: -40 to +6 dB, default 0
- Music volume slider: same range (placeholder until music bus is added)
- SFX volume slider: same range (placeholder until SFX bus is added)

### Display
- Fullscreen toggle
- VSync toggle
- Camera shake intensity slider: 0.0 to 2.0, default 1.0 — multiplies amplitude
  on `HitFeedback.shake()` calls

### Gameplay
- Damage numbers toggle (on by default)
- Loot magnet radius slider: 1.0 to 6.0, default 3.0

### Reset
- "Reset to defaults" button at the bottom of the page; deletes settings.cfg.

## credits.tscn

Static rolling text:
- Game design: Tim Rowsey
- Engine: Godot 4.6
- AI workforce: Castlevania squad (Lead, Spec-writer, Architect, Test-writer, Test-reviewer,
  Implementer, Code-reviewer, Test-runner)
- Music: TBD
- "Press any button to return"

## Settings.gd extensions
The existing settings module gains:
- `get_music_volume()` / `set_music_volume(db)`
- `get_sfx_volume()` / `set_sfx_volume(db)`
- `get_vsync()` / `set_vsync(on)`
- `get_camera_shake()` / `set_camera_shake(scale)`
- `get_damage_numbers()` / `set_damage_numbers(on)`
- `get_loot_magnet_radius()` / `set_loot_magnet_radius(r)`
- `reset_to_defaults()`

`load_and_apply()` applies the new keys to the appropriate engine systems
(VSync via `DisplayServer.window_set_vsync_mode()`).

## Project entry point
`project.godot` `run/main_scene` switches to
`res://scenes/ui/main_menu.tscn`. Character select is no longer the first
scene; it is reached via the New Game button.

## Tests
1. Settings extension tests — every getter/setter round-trips through cfg
2. Reset-to-defaults test — clears settings.cfg
3. PartyConfig still works after entering character select via menu flow
4. Existing 130 GUT tests must remain green
5. Existing 10 autobot E2E checks must remain green

## Out of scope (future work)
- Save/load of multiple character profiles
- Localized strings
- Custom keybindings UI
- Music tracks per menu
- "Continue" button (would require save/load)
