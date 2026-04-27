---
name: flower-debug
description: Flower (Godot 4 GDScript) debugging recipes. TRIGGER when investigating Godot parse errors, autobot/E2E test failures, autoload class_name issues, headless input behavior, or SceneTree runner problems in this repo.
context: fork
---

# Flower Debug Recipes

Deep-dive recipes for the recurring debugging modes in this codebase. AGENTS.md gives the one-liner for each gotcha; this skill gives the full fix.

---

## Recipe 1 — `class_name` resolution failures

**Symptom:** `SCRIPT ERROR: Parse Error: Could not find type 'X' in the current scope.`

**Why it happens:** GDScript's global class registry (populated from `class_name` declarations) isn't loaded yet when:
- Autoload scripts compile (autoloads load before the class scan completes)
- Custom `extends SceneTree` runners run via `--script` (e.g., `scripts/e2e/autobot_runner.gd`)
- Static methods on a class reference the class's own type (self-reference during compile)

**Fix pattern:**

```gdscript
# DON'T (under autoloads or --script runners):
var run_stats: RunStats = null
var stats := PlayerStats.new()

# DO:
const RunStatsScript = preload("res://scripts/run_stats.gd")
const PlayerStatsScript = preload("res://scripts/items/player_stats.gd")

var run_stats: Node = null  # untyped or Node — loosen to avoid registry dep
var stats = PlayerStatsScript.new()
```

For variables that *must* keep typed annotations, use a generic supertype (`Node`, `Resource`) and a comment naming the real type:

```gdscript
var run_stats: Node = null  # RunStats; loosened so this script compiles under SceneTree runners
```

**Sites that have hit this:** `scripts/main.gd`, `scripts/party_config.gd`, `scripts/items/character_class.gd` (self-reference in factory methods → use `_new_instance()` helper that does `load(...).new()`).

---

## Recipe 2 — Custom SceneTree runner setup

**Symptom under a `--script` runner:**
- `get_tree().current_scene` returns `null` (or the wrong node)
- "Invalid access to property 'X' on a base object of type 'Node3D'" — `current_scene` is the bare scene root, script didn't attach
- Autoloads not initialized

**Canonical pattern** (mirrors `scripts/e2e/autobot_runner.gd`):

```gdscript
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"

func _initialize() -> void:
    # 1. Configure autoloads BEFORE instantiating the scene
    PartyConfig.set_solo(0)  # or set_two_player(...)

    # 2. Instantiate and add to root
    var packed: PackedScene = load(MAIN_SCENE)
    var inst: Node = packed.instantiate()
    root.add_child(inst)

    # 3. CRITICAL: explicitly set current_scene — add_child does NOT
    current_scene = inst

    # 4. Add your driver as a sibling so it sees the live scene
    var driver := MyDriverScript.new()
    inst.add_child(driver)

func _idle(_dt: float) -> bool:
    # Return false to keep ticking; true to quit
    return false
```

**When looking up the main scene from a driver:**

```gdscript
# Defensive — works whether current_scene is set or not
var main: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root.get_child(0)
```

---

## Recipe 3 — Headless input matrix

What works under `godot --headless` and what doesn't:

| Input mechanism | Polling (`Input.is_action_pressed` / `get_vector`) | Event (`_input` / `_unhandled_input`) |
|---|---|---|
| `Input.action_press(name)` / `action_release(name)` | ✅ Works | ❌ Does NOT generate events |
| `Input.parse_input_event(InputEventAction)` | ❌ Doesn't update polled state | ⚠️ Unreliable in headless |
| `Input.parse_input_event(InputEventJoypadMotion)` with `device ≥ 0` | ✅ Updates `Input.get_joy_axis(device, axis)` | ✅ Fires `_unhandled_input` |
| `Input.parse_input_event(InputEventJoypadButton)` with `device ≥ 0` | ✅ | ✅ Fires `_unhandled_input` |
| `Input.parse_input_event(InputEventJoypadButton)` with `device = -1` | ⚠️ | ❌ Does NOT fire `_unhandled_input` for primary player |
| `Input.parse_input_event(InputEventMouseButton)` | ❌ No window in headless | ❌ |

**Practical implications for tests:**

```gdscript
# Movement (polling-based in player.gd via Input.get_vector): use action_press
Input.action_press("move_right", 1.0)
await get_tree().physics_frame  # let _physics_process tick
Input.action_release("move_right")

# Joypad-bound players (device_id = 0 in PartyConfig 2P): use real joypad events
var ev := InputEventJoypadMotion.new()
ev.device = 0
ev.axis = JOY_AXIS_LEFT_X
ev.axis_value = 1.0
Input.parse_input_event(ev)

# Primary player (device_id = -1) attack: events don't fire — call directly
p1._start_attack()  # mirrors the existing autobot.gd pattern
```

**Why P1 events don't fire:** Player's `_owns_event` returns `true` unconditionally for `device_id < 0`, but the engine's joypad event delivery in headless mode appears to require an actual device match. We bypass this by calling `_start_attack` (the function `_handle_controller_attack` ultimately invokes).

---

## Recipe 4 — Autobot regression triage

**Order of operations when an autobot suddenly fails:**

1. `./scripts/preflight.sh` — confirms whether the regression is real or environmental.
2. If parse-check fails: read the *first* error only. Subsequent errors usually cascade. Almost always a `class_name` issue (Recipe 1).
3. If GUT fails but autobots pass: a unit test depends on a behavior you changed. The test is the contract — fix your change, not the test, unless the test encoded a now-incorrect assumption.
4. If autobot 1P passes but 2P fails: check device assignment. P2's `device_id = 0` in `PartyConfig.set_two_player(...)`. Joypad events you fire need `device = 0`.
5. If `first_wave_spawned` fails despite enemies clearly spawning: timing race. The autobot `_run` is async-concurrent with `main._ready`. Use `_wait_until` with a longer timeout (15s) and `Time.get_ticks_msec()`-based polling, not `get_process_delta_time()` (returns 0 under custom SceneTree).
6. If `damage_dealt` doesn't accumulate: verify `main.gd` connected the signal. The `damage_dealt` / `damage_taken` signals on Player must be wired in `main._ready` after `run_stats` is constructed.

---

## Recipe 5 — Combo state during multiplayer tests

**Trap:** In 2P, P1 has `device_id = -1` which means `_owns_event` returns `true` for *any* event, including P2's joypad button presses. Result: when the test fires a button event for P2, P1's combo also advances.

**Workaround in tests:**

```gdscript
# Reset P1 before checking P1's response
p1._combo_stage = 0
p1._combo_window_open = false
var before := p1._combo_stage
p1._start_attack()
assert(p1._combo_stage > before)
```

Also: combat resets combo on damage taken (`player.gd` `take_damage()` line ~437). If you wait between attack and check while enemies are alive, combo can reset to 0. Capture combo *immediately* after the trigger, before any `await`.

---

## Recipe 6 — Adding a 4th (or 5th) autoload

Don't, unless you've:

1. Read `docs/architecture.md` §7 (current budget, justification for the existing 3+1).
2. Demonstrated that a non-autoload (static methods on a regular script, or a child of `main.gd`) can't do the job. `Settings` (ADR-009) and `RunStats` (ADR-010) both went non-autoload after consideration.
3. Written a new ADR in `architecture.md` §7 with: rationale, alternatives rejected, and the lifetime guarantee (autoloads live for the entire app).

**Pre-existing autoloads:** `DemonManager`, `HitFeedback`, `TransitionManager`, `PartyConfig`.

---

## Recipe 7 — Heredoc tab-stripping when writing GDScript via bash

**Trap:** `cat <<EOF >> file.gd` (and similar) silently strip leading tabs in many shell configurations. GDScript requires tabs (or consistent spaces) for indentation — broken indentation = parse error.

**Don't:**

```bash
cat <<EOF >> scripts/foo.gd
func bar():
	if x:
		return 1
EOF
```

**Do:** Use the agent's `edit` / `create` tools, or use Python:

```bash
python3 <<'PY'
with open("scripts/foo.gd", "a") as f:
    f.write("func bar():\n\tif x:\n\t\treturn 1\n")
PY
```

---

## Quick reference: where the gotchas live in code

| Gotcha | Affected files |
|---|---|
| `class_name` registry | `scripts/main.gd:36-37` (untyped `run_stats`/`biome_manager`), `scripts/party_config.gd:5` (`CharacterClassScript`), `scripts/items/character_class.gd` (self-ref via `_new_instance`) |
| Custom SceneTree runner | `scripts/e2e/autobot_runner.gd`, `scripts/e2e/autobot_play_runner.gd` |
| Headless input | `scripts/e2e/autobot_play.gd:155-173` (P1 `_start_attack` direct call) |
| Settings non-autoload | ADR-009 in `docs/architecture.md`; usages: `scripts/main.gd`, `scripts/ui/pause_menu.gd`, `tests/unit/test_settings.gd` |
| Player groups | `scripts/player.gd:_ready` (joins `player` + `player_<index>`) |
