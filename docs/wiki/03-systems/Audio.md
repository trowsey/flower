# Audio

## Purpose
Switches a single ambient track for a "combat" track when enemies are nearby. That's the entire audio system today. Player-facing behavior: audio mood shifts when an enemy is within 10 units; otherwise the world is quiet ambience.

## Key files
- `scripts/audio/ambient_audio.gd` — only audio script in the repo.
- `scripts/settings.gd::set_master_volume / set_music_volume / set_sfx_volume` — bus-level db control (no SFX wired yet).

## Data flow
```
AmbientAudio._ready:
  resolve ambient_player and combat_player NodePaths to AudioStreamPlayers.
AmbientAudio._process(_delta):
  p = first node in "player" group
  near = any enemy within combat_radius (default 10) of p
  if near != _in_combat: _in_combat = near; _swap()
_swap():
  ambient.volume_db = -10.0 if in combat else 0.0
  combat.volume_db  = 0.0 if in combat else -80.0
```
Both streams must always be playing (no start/stop); `_swap` only adjusts `volume_db`. The `combat` track is silent (-80 dB) when no enemies are around.

## Public API
**`AmbientAudio`** (`class_name AmbientAudio extends Node`):
```gdscript
@export var ambient_player: NodePath
@export var combat_player: NodePath
@export var combat_radius: float = 10.0
```
No signals, no methods to call externally. Drop the script on a Node in a scene that contains two `AudioStreamPlayer` children, then assign the NodePaths.

**`Settings`** (audio bus controls):
```gdscript
static func get_master_volume() / set_master_volume(db)   # bus "Master"
static func get_music_volume() / set_music_volume(db)     # bus "Music"
static func get_sfx_volume()   / set_sfx_volume(db)       # bus "SFX"
```
All clamp `db` to `[-40.0, 6.0]` and apply via `AudioServer.set_bus_volume_db`. Bus indices are looked up by name; if the bus doesn't exist the call no-ops.

The `Master`/`Music`/`SFX` buses are defined in `default_bus_layout.tres`.

## Tests
- `tests/unit/test_settings.gd` — covers volume getters/setters round-trip.
- Gap: `AmbientAudio` itself is untested (would need a fake player + enemy in the tree).

## Extending
**Wire SFX hooks** (currently the major gap): subscribe to `HitFeedback`'s four signals from a new `audio/sfx_player.gd`:
```gdscript
HitFeedback.request_camera_shake.connect(_play_hit_sfx)
HitFeedback.request_hit_stop.connect(_play_thud_sfx)
```
Use bus `"SFX"` so the settings volume slider applies. Random pitch ±10% per hit to avoid ear fatigue.

**Add a per-biome ambient track:** subscribe to `main.biome_changed(biome)` and swap `ambient_player.stream` based on `biome.biome_id`.

**Add music for boss waves:** subscribe to `main.wave_started(wave)` and swap streams when `wave % 10 == 0`.

**Add new bus:** edit `default_bus_layout.tres` (Godot editor → Audio panel) and add a `Settings.get_X_volume / set_X_volume` mirror.

## Known gaps
- **No SFX at all.** `HitFeedback` emits visual signals but nothing plays a sound on hit, dash, level-up, pickup, item drop, or skill use.
- No ambient track variety (one ambient, one combat, both must be assigned in scene).
- No spatial audio — `AudioStreamPlayer` (2D) used, not `AudioStreamPlayer3D`.
- No fade between ambient and combat — abrupt volume snap on threshold cross.
- No per-enemy audio cues (e.g. demon snarl on aggro, bomber fuse hiss).

## Spec/code mismatches
- `docs/specs/ambient-sound.md` likely describes the current behavior; SFX-related specs (if any) describe planned, not implemented, behavior.
- Note: `HitFeedback` doc-comments reference SFX hooks as "TODO"; do not ship a doc claiming SFX exist.
