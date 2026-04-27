# Settings and Persistence

## Purpose
Persist user preferences (audio dB, fullscreen, vsync, camera shake, damage numbers, loot magnet radius) and a tiny "tutorial seen" flag across runs. Implemented as a **static-method script** on `class_name Settings` — there's deliberately **no autoload**; callers invoke `Settings.get_X()` / `Settings.set_X(v)` directly. Player-facing behavior: open Settings from main menu, slide a slider, your choice survives the next launch.

## Key files
- `scripts/settings.gd` — the entire system. Static methods, no instance state.
- `scripts/ui/settings_menu.gd` — full settings UI (main menu route).
- `scripts/ui/pause_menu.gd` — mini settings (volume + fullscreen) inline in pause overlay.
- `scripts/main.gd::_ready` — calls `Settings.load_and_apply()` on scene start so audio buses + fullscreen are correct.
- `scripts/ui/main_menu.gd::_ready` — same call, so menu also reflects saved settings.
- `scripts/party_config.gd` — adjacent "session-only persistence" via `set_meta` (no disk).

## Data flow
```
Disk file: user://settings.cfg                ← godot per-user dir

Settings.<getter>:
  ConfigFile.load(PATH) (silent OK if missing)
  return cfg.get_value(section, key, DEFAULTS[section][key])

Settings.<setter>(v):
  clamp v
  ConfigFile.load → set_value(section, key, clamped) → save
  apply side effect (AudioServer.set_bus_volume_db, DisplayServer.window_set_mode, …)

Settings.load_and_apply():
  re-applies audio buses, fullscreen, vsync from saved values.
  Called by main.gd._ready and main_menu.gd._ready.

reset_to_defaults():
  remove user://settings.cfg → load_and_apply()
```

`PartyConfig` (autoload) is "persistence-ish" only in the sense that it survives scene transitions within a single launch via `set_meta`/`get_meta`. It is **not** written to disk. Use `Settings` for anything that must survive a quit.

## Public API
**`Settings`** (`class_name Settings`, all static, `PATH = "user://settings.cfg"`):

Defaults dict:
```gdscript
const DEFAULTS := {
    "audio":    { "master_db": 0.0, "music_db": 0.0, "sfx_db": 0.0 },
    "display":  { "fullscreen": false, "vsync": true, "camera_shake": 1.0 },
    "gameplay": { "damage_numbers": true, "loot_magnet_radius": 4.0 },
}
```

| Setter | Clamp |
|---|---|
| `set_master_volume(db)` / `set_music_volume(db)` / `set_sfx_volume(db)` | `[-40.0, 6.0]` |
| `set_camera_shake(scale)` | `[0.0, 2.0]` |
| `set_loot_magnet_radius(r)` | `[1.0, 10.0]` |
| `set_fullscreen(on)` / `set_vsync(on)` / `set_damage_numbers(on)` | bool, no clamp |

```gdscript
static func load_and_apply() -> void   # re-apply audio/fullscreen/vsync to engine
static func reset_to_defaults() -> void
```

**Tutorial flag** (separate; `tutorial_overlay.gd` reads/writes `[tutorial] seen` directly via `ConfigFile`, bypassing `Settings`). Same file (`user://settings.cfg`).

**`PartyConfig`** session-only state via `set_meta` — see [Multiplayer-And-Input](Multiplayer-And-Input.md). Keys in active use:
- `"requested_player_count"` (int)
- `"difficulty_mult"` (float)
- `"difficulty_name"` (String)

## Tests
- `tests/unit/test_settings.gd` — round-trip getters/setters; clamping; `reset_to_defaults`.
- Gap: no test verifies that `load_and_apply` re-applies after a "fresh" launch (would need to delete `user://settings.cfg` mid-test).

## Extending
**Add a new setting:**
1. Add a key under the right `DEFAULTS[section]`.
2. Add a getter and setter mirroring the existing pattern (clamp inside the setter).
3. Wire UI in `settings_menu.gd` (slider/checkbox + `_load_values` + `_refresh_labels`).
4. If it has a runtime side effect that must survive launch, add it to `load_and_apply()`.

**Add a new section:** add a top-level key to `DEFAULTS` (e.g. `"controls"`) and use the same `_get_value` / `_set_value` helpers.

**Add real persistence (e.g. cross-run progression, achievements):** create a parallel `scripts/progress.gd` static script using a separate file like `user://progress.cfg`. Keep `Settings` focused on preferences; don't let `user://settings.cfg` become a dumping ground.

**Replace `PartyConfig.set_meta` with structured fields:** if the meta dict grows past ~5 keys, promote them to typed `var` fields on `PartyConfig` for IDE autocomplete and grep-ability.

## Known gaps
- Each `_get_value` re-loads the file — fine for menu navigation, wasteful for hot-paths. `Player._process_magnet` calls `Settings.get_loot_magnet_radius()` every physics frame; consider caching.
- `tutorial_overlay.gd` writes to `user://settings.cfg` directly under `[tutorial]` instead of going through `Settings` — fragmenting the abstraction.
- No version field in the config — schema migrations have nowhere to go.
- `set_camera_shake` saves the value but does **not** call `load_and_apply` to push it anywhere; the value is read on demand by `HitFeedback._shake`. Fine, but inconsistent with `set_master_volume` which applies immediately.
- No way to inspect or wipe `user://settings.cfg` from inside the game except via "Reset" in settings menu.

## Spec/code mismatches
- The user-facing description sometimes states `loot_magnet_radius` defaults to 3.0 (matching `Player.MAGNET_RADIUS`); actual `Settings` default is `4.0` (`settings.gd:23`). Magnet radius at runtime is the **Settings** value (the `MAGNET_RADIUS` const is only a fallback if `SettingsScript` were unavailable — which never happens in practice). Treat 4.0 as canonical.
- Camera shake clamp is `[0.0, 2.0]` (`settings.gd:101`); UI label shows it as a percentage (`%.0f%%`). Make sure new UIs match.
