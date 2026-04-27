# Writing Tests

Flower uses [GUT](https://github.com/bitwes/Gut) (the Godot Unit
Testing framework). Tests live under `tests/unit/` and `tests/integration/`,
mirror the script layout, and are named `test_<thing>.gd`.

The full GUT config is in [`tests/.gut_config.tres`](../../../tests/.gut_config.tres).

## File anatomy

```gdscript
extends GutTest          # or extends "res://tests/base_test.gd"

const SomeScript = preload("res://scripts/some/path.gd")

var _thing: Foo


func before_each() -> void:
    _thing = Foo.new()


func test_some_behaviour() -> void:
    var result: int = _thing.do_something(5)
    assert_eq(result, 10, "doubling should produce 10")
```

- Filename: `test_<feature>.gd`. The prefix is required (it's in the
  GUT config).
- Function names: `test_<requirement>_<scenario>`. Map back to a `REQ-N`
  in the spec when possible.
- `before_each()` runs before every test; use it to reset state. Common
  example from [`test_settings.gd`](../../../tests/unit/test_settings.gd):

```gdscript
func before_each() -> void:
    if FileAccess.file_exists(SettingsScript.PATH):
        DirAccess.remove_absolute(SettingsScript.PATH)
```

## Asserts we use

| Assert | When |
|--------|------|
| `assert_eq(a, b)` | exact equality (use for ints, strings, refs) |
| `assert_almost_eq(a, b, eps)` | floats — always supply an epsilon |
| `assert_gt`, `assert_gte`, `assert_lt`, `assert_lte` | numeric ranges, clamps |
| `assert_true`, `assert_false` | booleans (always include a message) |
| `assert_null`, `assert_not_null` | null checks |
| `watch_signals(obj)` + `assert_signal_emitted(obj, "sig")` | signal emission tests |

Always pass a third-arg message when the assert isn't self-explanatory —
it makes Test-runner's failure reports actionable.

## Three canonical patterns

### 1 — Pure Resource (no SceneTree)

For data + math. Fastest, simplest. From
[`test_inventory.gd`](../../../tests/unit/test_inventory.gd):

```gdscript
extends GutTest

var _inv: Inventory


func before_each() -> void:
    _inv = Inventory.new()


func test_inventory_full_returns_negative() -> void:
    for i in _inv.slots.size():
        _inv.add(ItemFactory.make_random())
    var overflow: int = _inv.add(ItemFactory.make_random())
    assert_eq(overflow, -1, "Full inventory should reject new items")
```

No `add_child`, no `await`. Default to this whenever possible — see
[Resource Patterns](../04-architecture/Resource-Patterns.md).

### 2 — Node that needs the SceneTree

For player physics, animations, area overlaps. Use `add_child_autofree`
so GUT cleans up and `await get_tree().process_frame` so `_ready`
finishes. From [`test_player_movement.gd`](../../../tests/unit/test_player_movement.gd):

```gdscript
var _player: CharacterBody3D


func before_each() -> void:
    var scene := load("res://scenes/player.tscn")
    _player = scene.instantiate()
    add_child_autofree(_player)
    await get_tree().process_frame


func test_req6_stick_deadzone_constant() -> void:
    assert_eq(_player.STICK_DEADZONE, 0.2, "STICK_DEADZONE should be 0.2")
```

### 3 — Signal emission

```gdscript
func test_take_damage_emits_health_changed() -> void:
    watch_signals(_player)
    _player.take_damage(10.0)
    assert_signal_emitted(_player, "health_changed")
    var args = get_signal_parameters(_player, "health_changed", 0)
    assert_almost_eq(args[0], 90.0, 0.01)
```

For the catalog of cross-system signals you might want to watch, see
[Signals Catalog](../04-architecture/Signals-Catalog.md).

## Common pitfall: untyped locals in Godot 4.6

The 4.6 parser refuses to infer the type of a `var` initialized from a
function whose return type it can't resolve at parse time. Symptom:

```
error: Cannot infer the type of "x" variable...
```

Fix: annotate the local explicitly, or make the source's return type
explicit.

```gdscript
# ❌ may fail at parse time
var slot = _eq.set_equipped(ItemResource.ItemType.WEAPON, w1)

# ✅
var slot: ItemResource = _eq.set_equipped(ItemResource.ItemType.WEAPON, w1)
```

This bites tests more than production code because tests poke into
private corners. When in doubt, annotate.

## Running tests

Full suite (matches CI):

```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit,res://tests/integration -gprefix=test_ -gexit
```

Single file (fast iteration):

```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://tests/unit/test_xyz.gd -gexit
```

> ⚠ **Spec/code mismatch:** `docs/principles.md` checklist says
> `addons/gut/gut_cmdml.gd` — that's a typo. The real script is
> `gut_cmdln.gd` (with **n**, not **m**).

## Where Test-writer and Test-reviewer live

Tests are written by [Test-writer](Squad-And-Agents.md#test-writer--test-writer)
from the spec alone, then audited by
[Test-reviewer](Squad-And-Agents.md#test-reviewer--test-reviewer) for spec coverage
before any implementation begins. Once Test-reviewer approves, tests are
**frozen** — Test-runner can't edit them and Implementer can't "fix" them to make
the suite pass. If a test is wrong, it goes back to Test-writer.
