# Flower — Principles in Practice

> A short, opinionated cheat sheet for *how we write code on this project*.
> When `architecture.md` is the constitution, this is the daily-driver
> phrasebook. Read this first; reach for the constitution when something feels
> off.

---

## The five rules that catch 90% of bad code

1. **If you can't test it without a SceneTree, the logic is in the wrong file.**
   Move pure logic into a `Resource` or RefCounted helper. Leave the node thin.

2. **Two copies is fine. Three triggers an extraction.**
   Don't extract on the second occurrence. You don't yet know the seam.

3. **One signal per cross-system concern.** Within a system, call methods.
   Across systems, emit a signal and let the consumer subscribe.

4. **No new autoload without an ADR.** We have four (DemonManager, HitFeedback,
   TransitionManager, PartyConfig). Adding a fifth is a design decision,
   not an implementation detail. Pure data modules use the static-script
   pattern (see Settings) instead — no autoload required.

5. **Tests fail first, pass after.** Every behaviour change starts red.
   If a refactor turns a test red, the test is usually right.

---

## Day-to-day decisions

### "Where do I put this code?"

| It is...                       | Lives in                                      |
|--------------------------------|------------------------------------------------|
| Pure stat math                 | `scripts/items/<name>.gd` (Resource)          |
| Per-frame movement / physics   | `scripts/player.gd` or `scripts/enemies/...`  |
| World object (pickup, prop)    | `scripts/world/<name>.gd`                     |
| Visual feedback (shake, flash) | `scripts/vfx/...` + autoload signal           |
| HUD widget                     | `scripts/ui/<name>.gd`                        |
| Persistent global config       | `scripts/settings.gd` (static module)         |
| Per-run state (kill counts…)   | `scripts/run_stats.gd` instanced in main      |
| Cross-scene state              | An autoload — but justify it in an ADR        |

### "Should I make a base class?"

Ask:
1. Do **three** existing concrete cases share this behaviour?
2. Can I describe the shared concept in **one sentence**?
3. Will the next person searching for the behaviour find it on the base
   class, or get lost?

If any answer is "no," inline the duplication. We can always extract later.

### "Should this be a Resource or a Node?"

| It needs...                         | Use     |
|-------------------------------------|---------|
| To live in the scene tree           | Node    |
| `_process` / `_physics_process`     | Node    |
| To be saved to disk / serialized    | Resource|
| To be passed around without ownership | Resource |
| To be unit-tested                   | Resource (preferred) |

If unsure: try Resource first. Convert if you actually need the tree.

### "How big is too big?"

| File             | Soft limit | What to do at the limit                         |
|------------------|-----------:|-------------------------------------------------|
| `*.gd` (general) |       400  | Look for *paragraphs* of related code; group with comments. Only split if a clean concept emerges. |
| `player.gd`      |       900  | Player owns combat, movement, equipment, skills, multiplayer input. Long is fine; cluttered is not. |
| Test file        |       300  | If you exceed this, you are testing too many concepts in one file. |

Splitting `player.gd` into 10 mixins would make it *worse*, not better.
The *concept* is unified — keep the *file* unified.

---

## What "Diablo-like" buys you architecturally

ARPGs are item-driven. That makes our architecture choices obvious:

- **Items, skills, classes, affixes are all data** → Resources, not classes.
- **Combat math** → static functions on Resources, easy to test.
- **Loot tables** → arrays/dicts in `scripts/items/item_factory.gd`,
  not deeply nested classes.
- **Stat modifiers** → flat dictionaries summed by `EquipmentManager`.

If a future feature breaks this pattern (e.g., scripted bosses with custom
behaviours), accept the local complexity rather than refactoring the data
layer to accommodate it.

---

## Checklist before you open a PR

- [ ] **Spec** in `docs/specs/<feature>.md` — even if short. Tests reference it.
- [ ] **Tests** in `tests/unit/test_<feature>.gd` — at least one happy path,
      one edge case. They were red before your code, green after.
- [ ] **No new directories** without justification.
- [ ] **No new autoload** without an ADR.
- [ ] **No new singleton/global state** beyond Settings/PartyConfig pattern.
- [ ] **Autobot still passes** (`godot --headless --script
      res://scripts/e2e/autobot_runner.gd` → 10/10).
- [ ] **GUT still passes** (`godot --headless -s addons/gut/gut_cmdml.gd
      -gdir=res://tests/unit -gexit`).
- [ ] **Project still parses** (`godot --headless --quit`).
- [ ] **Co-author trailer** on commit:
      `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`

---

## Patterns we use repeatedly

### The static-module pattern (Settings)
For pure functions over disk-persisted state:
```gdscript
# scripts/settings.gd
extends Object  # or no extends — static-only

const _PATH := "user://settings.cfg"
const DEFAULTS := {"audio": {"master_db": 0.0}}

static func get_master_volume() -> float: ...
static func set_master_volume(db: float) -> void: ...
```
Caller imports it once: `const SettingsScript = preload(".../settings.gd")`.

### The procedural-UI pattern
For UI panels that only one screen instances:
```gdscript
extends CanvasLayer

func _ready() -> void:
    _build()  # all child nodes created here, no .tscn needed

func _build() -> void:
    var panel := PanelContainer.new()
    add_child(panel)
    ...
```
Reduces the number of .tscn files we have to maintain. Use a .tscn only when
designers / non-coders need to edit the layout.

### The signal-into-autoload pattern (HitFeedback)
For "many → one → many" reactions:
```gdscript
# producer
HitFeedback.enemy_hit(pos, dmg, sprite)

# autoload
signal request_camera_shake(intensity, duration)
func enemy_hit(...) -> void:
    request_camera_shake.emit(0.15, 0.2)
    ...

# consumer
HitFeedback.request_camera_shake.connect(camera.shake)
```
Producers don't know consumers exist. Consumers don't know producers exist.

---

## When to ask the architect

- Adding a 5th autoload.
- Splitting `player.gd` (or any "anchor" file).
- Introducing a base class with only two concrete subclasses.
- Replacing a Resource with a Node, or vice versa.
- Anything that touches `project.godot` autoload list.
- Anything that adds a new directory under `scripts/`.

For everything else — write the test, write the code, ship it.
