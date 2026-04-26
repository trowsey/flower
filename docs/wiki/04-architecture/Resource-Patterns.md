# Resource Patterns

When to reach for a `Resource`, when for a `Node`, and when for a static
script. Pulled from [`docs/architecture.md`](../../architecture.md) §2.3
and [`docs/principles.md`](../../principles.md) — read those for the full
rationale; this page is the cheat sheet.

## The decision

| It needs… | Use |
|-----------|-----|
| To live in the scene tree | **Node** |
| `_process` / `_physics_process` / input events | **Node** |
| Pure data + small math, serialized to disk or `.tres` | **Resource** |
| To be unit-tested without `add_child_autofree` | **Resource** |
| Disk-persisted config + pure read/write functions | **Static script** (see below) |

Default to `Resource`. Convert to `Node` only when you actually need the
tree.

---

## Pattern 1 — `Resource` for data: `ItemResource`

`scripts/items/item_resource.gd` is a `class_name ItemResource extends Resource`.
Every drop is an instance carrying its stats; no node, no scene-tree
overhead. Loot tables in `item_factory.gd` are arrays/dicts that build
these on the fly. See `tests/unit/test_item_factory.gd` for fully
SceneTree-free coverage.

**Why a Resource:**
- Items are pure data — name, type, modifiers, level.
- We may want to serialize a save file later — Resources do that for free.
- The factory is testable as `ItemFactory.make_random()` without a scene.

---

## Pattern 2 — `Resource` instead of `Node`: `Inventory`

`scripts/items/inventory.gd` could plausibly have been a Node hung off the
player. Instead it's:

```gdscript
extends Resource
class_name Inventory

const CAPACITY := 30
signal items_changed
var slots: Array = []
```

The Player owns one (`player.inventory = Inventory.new()`) and the
inventory UI subscribes to `items_changed` directly. The benefit:
`tests/unit/test_inventory.gd` can do `_inv = Inventory.new()` in
`before_each` and never touch the SceneTree.

**Rule of thumb:** if the only reason you're tempted to make a Node is
"I need signals", remember Resources can emit signals too.

---

## Pattern 3 — Static script for disk-backed config: `Settings`

`scripts/settings.gd` is a module of `static func`s over a
`user://settings.cfg` file. No autoload. No instance. Callers do:

```gdscript
const SettingsScript = preload("res://scripts/settings.gd")

func _ready() -> void:
    SettingsScript.load_and_apply()
```

This is the canonical "data-only module" pattern (ADR-009). Use it
whenever something is *pure read/write over persistent state* with no
per-frame logic and no need to broadcast change inside one frame.

> ⚠ **Spec/code mismatch:** `principles.md` shows the static-module pattern
> as `extends Object` with no `class_name`. The actual `settings.gd` is
> `extends Node` *with* `class_name Settings` — both `Settings.foo()` and
> `SettingsScript.foo()` work today. The `extends Node` is unnecessary;
> nothing reads it as a node. If you write a new static module, prefer the
> documented `extends Object` form.

---

## Anti-patterns

- **Resource that reaches into the scene tree.** Resources may emit
  signals; consumers in the tree subscribe. Resources never call
  `get_tree()` or `add_child`. (architecture.md §4)
- **Node that holds only data.** If there's no `_process` and nothing
  visual, it should be a Resource owned by something else.
- **Singleton (autoload) for config.** Use the static-script pattern
  instead. The autoload budget is exhausted — see [Autoloads](Autoloads.md).

---

## Related

- [Autoloads](Autoloads.md) — when global state is genuinely required.
- [Scene Composition](Scene-Composition.md) — how Nodes are wired up at runtime.
- [Writing Tests](../05-contributing/Writing-Tests.md) — how the Resource pattern enables tree-free tests.
