# Running The Game

## Launch

From the editor: press **F5**. The main scene defined in `project.godot` is `res://scenes/ui/main_menu.tscn` — it loads the title menu, not gameplay directly.

From the command line:

```bash
# Boot the editor's main scene (= main menu)
godot --path . res://scenes/ui/main_menu.tscn

# Skip the menu and drop straight into gameplay (Sarah, solo, default settings)
godot --path . res://scenes/main.tscn
```

The flow from cold boot is:

```
main_menu.tscn  →  player_count.tscn  →  character_select.tscn  →  main.tscn
```

`PartyConfig` (autoload) carries the per-slot character + device assignments through the chain. Booting `main.tscn` directly bypasses the menus and seeds a default solo party (Sarah, device `-1`) — see [`scripts/main.gd::_ready`](../../../scripts/main.gd).

## Default keybindings

Defined in `project.godot` (`[input]` section). All deadzones for analog sticks are `0.2`.

### Movement & camera (P1: keyboard or controller; P2: controller only)

| Action | Keyboard | Controller |
|---|---|---|
| Move | `W` / `A` / `S` / `D` | Left stick |
| Aim / face | Mouse cursor | Right stick (any direction > 0.1) |

Direct input always overrides click-to-move. Stick input below `STICK_DEADZONE = 0.2` is treated as zero.

### Combat

| Action | Keyboard / Mouse | Controller |
|---|---|---|
| Attack | Right mouse button | `X` (button index 2) |
| Click-to-move | Left mouse button | — |
| Dash / dodge | `Shift` | Right shoulder (R1) |
| Skill 1 (signature) | `1` | — |
| Skill 2 | `2` | — |
| Skill 3 | `3` | — |
| Skill 4 | `4` | — |
| Use potion | configured per slot | — |

The combo system advances with the same attack input — three stages with a `0.5s` window, damage multipliers `[1.0, 1.25, 1.75]`. Movement during the combo window resets it.

### Menus & UI

| Action | Keyboard | Controller |
|---|---|---|
| Inventory | `I` | back/select (mapped per platform) |
| Character / stat panel | `C` | — |
| Pause | `Esc` | `Start` |
| Interact | `E` (UI focus) | `A` (button index 0) |
| Confirm in menus | `Enter` / mouse | `A` |
| Back in menus | `Esc` | `B` |

Pause uses `get_tree().paused = true`; UI nodes that need to keep responding (settings, recap) set `process_mode = Node.PROCESS_MODE_ALWAYS`.

## Couch co-op

1. Plug in two controllers **before** the player-count screen.
2. Choose 2P. Each player picks a class on character-select; P1 confirms with kbd or first joypad, P2 confirms with the second joypad.
3. Press `attack` to start the run.

Per-device input filtering happens in [`scripts/player.gd::_owns_event`](../../../scripts/player.gd):

- Player 1 (`player_index = 0`, `device_id = -1`): owns mouse/keyboard + any joypad event.
- Player 2+ (`device_id >= 0`): only joypad events from the matching device.

Game over fires only when **all** players are dead. While at least one teammate stands, downed players can be revived: the rescuer stands within `REVIVE_RADIUS = 2.5` for `REVIVE_TIME = 2.0s`.

## Quick troubleshooting

- **No movement on F5:** make sure the focused window is the running game, not the editor's debugger panel.
- **Second controller not detected:** Godot polls on connect; replug *before* `player_count.tscn` and the screen will re-detect.
- **Autobot is firing in normal play:** you ran the autobot runner instead of the menu. See [Running Tests](Running-Tests.md).
- **Inventory toggles `I` but combat keeps going:** that's intentional today — see the mismatch note in [Current Feature Matrix](../01-overview/Current-Feature-Matrix.md).

## Spec/code mismatches noted

- The pause-menu help text in [`scripts/ui/pause_menu.gd`](../../../scripts/ui/pause_menu.gd) advertises `Space / A — dash`. The actual dash binding (in `scripts/player.gd::_is_dash_event`) is `Shift` and the **right shoulder button (R1)**, not `Space` / `A`. Either the help text or the implementation needs a follow-up.
- `docs/specs/input-config.md` REQ-8 names a `dodge` action on `B`. That action is in `project.godot` but no code consumes it; the working dash uses Shift / R1 directly.
- `docs/specs/level-up.md` says `C` *or* `Tab` opens the stat panel; only `C` is wired in `level_up_panel.gd`, and the `character` action it tries first isn't declared in `project.godot`.
