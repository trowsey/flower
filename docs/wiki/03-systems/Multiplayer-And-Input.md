# Multiplayer and Input

## Purpose
Local couch co-op for up to 2 players sharing the screen. Each player owns one input device: P1 = mouse + keyboard + first joypad; P2 = a second joypad. Action mapping is global, but `Player._owns_event` filters by `device_id` so simultaneous key/stick presses don't double-fire. Player-facing behavior: plug in a 2nd controller before character select, pick "2 PLAYERS", both pick a class and ready up, the camera zooms to keep both in frame.

## Key files
- `scripts/party_config.gd` — autoload `PartyConfig`; holds `slots` + cross-scene `set_meta` whiteboard.
- `scripts/player.gd::_owns_event` / `_get_stick_input` — per-player input filtering.
- `scripts/main.gd::_ready` — instantiates `Player2..N` from `PartyConfig.slots`.
- `scripts/ui/player_count.gd` — detects 2nd controller via `Input.joy_connection_changed` or any joypad button with `device > 0`.
- `scripts/ui/character_select.gd::_slot_for_event` — per-device slot routing.
- `project.godot [input]` — action map definitions (global, device=-1 events).

## Data flow
```
PlayerCount: any joypad button with device>0 → _second_controller_ready=true
  Pick 1 or 2 → PartyConfig.set_meta("requested_player_count", n)

CharacterSelect:
  reads requested_player_count → _two_player flag
  _slot_for_event:
    InputEventKey       → slot 0 (P1)
    InputEventJoypad    → slot 0 if device==0 else 1 (only in 2P)
  _start_game:
    PartyConfig.set_two_player(p1, p2, p1_device=-1, p2_device=1)

main._ready:
  for slot 0: configure pre-placed Player (player_index=0, device_id=slots[0].device_id)
  for slot i≥1: instantiate player.tscn:
    p.player_index = i
    p.device_id = slots[i].device_id
    p.global_position = SPAWN_OFFSETS[i]
  Each player joins groups: "player", "player_<i>"

per-frame Player._unhandled_input:
  if not _owns_event(event): return
    _owns_event:
      if device_id < 0: accept everything (solo mode)
      if event is JoypadButton/Motion: must match device_id
      otherwise (kbd/mouse): only player_index == 0 owns it

Player._get_stick_input:
  if device_id < 0: read action map (combined kbd+joy)
  else: read Input.get_joy_axis(device_id, ...) directly
        AND if player_index == 0: also blend in keyboard axes
```

## Public API
**`PartyConfig`** — see also [Menus-And-Flow](Menus-And-Flow.md):
```gdscript
var slots: Array       # [{ "character_class_id": int, "device_id": int }, ...]
func set_solo(class_id)
func set_two_player(p1_class, p2_class, p1_dev=-1, p2_dev=0)
func add_slot(class_id, device_id)
func player_count() -> int
# Cross-scene state via inherited Node.set_meta / get_meta:
#   "requested_player_count": int (1|2)   — set by player_count, read by character_select
#   "difficulty_mult": float              — set by main_menu, read by main._spawn_wave
#   "difficulty_name": String             — display only
```

**Player input wiring**:
- `device_id == -1` → "listen to anything" (solo / P1 default).
- `device_id >= 0` → only listens to that joypad (P2 with id 1 in 2P mode).
- `player_index == 0` always also gets keyboard/mouse, even with a `device_id` set, so P1 can swap freely between kbd and pad.

**Action map** (`project.godot [input]`):
- `move_up/down/left/right` — WASD + left stick (axis ±1, deadzone 0.2).
- `attack` — LMB + joypad face button (X on Xbox).
- `interact` — separate face button.
- `skill_1` … `skill_4` — keyboard 1/2/3/4 + joypad face/shoulder buttons.
- `inventory` — keyboard (default `I`); used by `inventory_screen.gd`.

**Camera multi-player handling** (`scripts/camera.gd`): focus point is the average of all players' positions; zoom adds `multi_zoom_per_unit_distance * spread`, clamped to `multi_max_extra_zoom`.

## Tests
- `tests/unit/test_party_config.gd` — `set_solo`, `set_two_player`, slot composition.
- `tests/unit/test_input_config.gd` — input action presence + binding sanity.
- Gap: no automated test for `_owns_event` device routing; would need synthetic `InputEventJoypadButton(device=1)` events.

## Extending
**Add 3-4 player support:**
1. Extend `player_count.gd` UI to allow choosing 3 / 4.
2. `character_select.gd._slot_for_event` already keys off `event.device` — add slot indices 2 / 3.
3. `PartyConfig` already supports N slots via `add_slot`.
4. `main.gd::SPAWN_OFFSETS` — add more spawn points; the array is already indexed by `i % size()`.
5. HUD anchors are `_left_anchor` and `_right_anchor` only; add anchors for slots 2 / 3.

**Add a new input action:** declare in `project.godot [input]`, then either gate via `InputMap.has_action("foo")` (recommended for soft-deprecation safety) or call `Input.is_action_just_pressed("foo")` directly. Player input must be wrapped in `_owns_event` or controllers will collide.

**Hook a new device-aware UI:** mirror `character_select._slot_for_event(event) -> int` to map devices to slots.

## Known gaps
- All keyboard input goes to P1; no second-keyboard support.
- Inventory and Level-up panels only attach to player 0 — P2 cannot inspect their bag (see [UI-And-HUD](UI-And-HUD.md)).
- Skill input (`skill_1`-`skill_4`) is not yet device-routed inside `Player._unhandled_input` — both players' slot N can fire on the same key/button press if devices aren't filtered correctly.
- No remappable bindings UI; users must edit `project.godot`.
- No online multiplayer; couch only.

## Spec/code mismatches
- `docs/specs/input-config.md` should list the actions defined above; cross-check after touching the input map.
- The README sometimes refers to "device 0 = P1, device 1 = P2" — actually `player_index 0` (P1) uses `device_id = -1` (listen-all) by default; P2 uses `device_id = 1` from `set_two_player(..., p2_device=1)`.
