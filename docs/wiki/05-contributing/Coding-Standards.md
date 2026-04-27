# Coding Standards

Style for `.gd` files in this repo. The architectural *why* is in
[`docs/architecture.md`](../../architecture.md) and
[`docs/principles.md`](../../principles.md) — read those first. This
page is the syntax-level cheat sheet.

## Type hints — always

GDScript's optional types are mandatory here. They catch real bugs and
make the file self-documenting.

```gdscript
var hp: int = 100                                  # ✅ explicit
var hp := 100                                       # ✅ inferred-typed
var hp = 100                                        # ❌ untyped — reject in review

func take_damage(amount: float, is_crit: bool) -> void:    # ✅ all params + return
    ...

func best_target():                                 # ❌ missing return type
    ...
```

`-> void` is required even when "obvious".

## `class_name` — only when something else needs the name

Add `class_name Foo` only if another script references `Foo` directly
(`var x: Foo`, `Foo.new()`). Otherwise, callers should:

```gdscript
const FooScript = preload("res://scripts/foo.gd")
```

Why: `class_name` registers a global symbol resolved at parse time. In
some load orders (autoloads, tools, tests) the symbol can be undefined
when first referenced, producing a confusing parse error. `preload()`
references the file directly and avoids the load-order trap.

## `const X = preload(...)` at the top, never `var X = load(...)`

```gdscript
# ✅
const PlayerScene = preload("res://scenes/player.tscn")

# ❌ — Godot 4.6 emits a warning, and we treat warnings as errors
var player_scene = load("res://scenes/player.tscn")
```

The exception: `main.gd` uses `load()` for **enemy scenes** to break
preload cycles. See [Scene Composition](../04-architecture/Scene-Composition.md).

## Comments

Only when behavior is non-obvious. The signature, name, and types should
explain themselves; a comment that restates the code is noise.

```gdscript
# ❌
# Increment hp by amount.
func heal(amount: float) -> void:
    hp += amount

# ✅
# Soul-drained players cap at half max while drained — see soul-system.md.
func heal(amount: float) -> void:
    var cap := stats.max_health() * (0.5 if drained else 1.0)
    hp = min(hp + amount, cap)
```

## Resources vs Nodes

| It is data | `Resource` |
| It needs to live in the tree / process per frame | `Node` |

See [Resource Patterns](../04-architecture/Resource-Patterns.md) for
canonical examples.

## Naming

| Kind | Convention | Example |
|------|-----------|---------|
| File | `snake_case.gd` | `enemy_base.gd` |
| `class_name` | `PascalCase` | `EnemyBase` |
| Method | `snake_case`, verb-first | `take_damage`, `apply_temp_buff` |
| Local / field | `snake_case` | `var current_hp: float` |
| Private field | `_snake_case` | `var _hit_iframe_timer: float` |
| Constant | `UPPER_SNAKE` | `const STICK_DEADZONE := 0.2` |
| Signal | `snake_case`, **past tense** | `died`, `equipment_changed`, `wave_cleared` |
| Enum type | `PascalCase`, members `UPPER_SNAKE` | `enum PlayerState { NORMAL, DASHING }` |

Past-tense signal names are how a listener knows it's reacting to
something that already happened — `equipment_changed` (good),
`change_equipment` (looks like a method).

## Whitespace

- 1 blank line between methods inside a class.
- 2 blank lines between top-level declarations (constants block →
  signals → exports → vars → methods).
- Tabs for indentation (Godot default).
- No trailing whitespace; the editor strips it on save.

## File size

Soft limits (from `principles.md`):

| File | Limit | What to do |
|------|------:|------------|
| general `.gd` | 400 | Group related blocks with comments before splitting |
| `player.gd` (anchor file) | 900 | Stay one file; the *concept* is unified |
| Test file | 300 | Split by `REQ-N` if you exceed |

Splitting a 100-line file into five 20-line files is churn. Don't.

## Patterns

- **Cross-system communication →** signal. Within a system → method call.
  ([Signals Catalog](../04-architecture/Signals-Catalog.md))
- **Pure data + disk I/O →** static-script module like
  [`scripts/settings.gd`](../../../scripts/settings.gd). Not an autoload.
- **Many → one → many reactions →** route through the `HitFeedback`
  autoload pattern. ([Autoloads](../04-architecture/Autoloads.md))

## What this page does not cover

- Architectural decisions ("Should this be a base class?") →
  [Principles In Practice](../04-architecture/Principles-In-Practice.md).
- Test-specific style → [Writing Tests](Writing-Tests.md).
- Spec-writing style → [Writing Specs](Writing-Specs.md).
- Commit format → [Commit & PR Conventions](Commit-And-PR-Conventions.md).
