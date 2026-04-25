# Flower — Architecture Guide

> Audience: Grant (architect agent), human collaborators, and any future
> contributor who needs to understand *why* the codebase looks the way it does
> before changing it.
>
> This document is **the architectural compass**. Read it before you propose a
> refactor. When in doubt, prefer the choices documented here over your
> personal taste, but feel free to flag genuine drift in a `docs/adr/` ADR.

---

## 1. Mission and constraints

Flower is a small-scope **Diablo-like 3D action RPG built in Godot 4.6 with
GDScript**. We have one programmer plus an AI workforce, no artists yet, and
very limited time. Architectural decisions exist to serve *that* reality —
not the architecture of an enterprise CRM.

This shapes everything below. When evaluating a refactor, keep asking:

- Does it shrink the time between "I have an idea" and "I see it on screen"?
- Does it remove a class of bug, or just rearrange code?
- Could the next person — or agent — read the file and *immediately* tell
  what it does?

If the answer to all three is "no", it is probably the wrong refactor.

---

## 2. Principles (in priority order)

These are listed top-down. When two principles conflict, the higher one wins.

### 2.1 Boring code over clever code
We optimize for readability by people who haven't seen the file before. Plain
loops, named locals, early returns. No metaprogramming, no monkey-patching, no
virtual hierarchies built "for future flexibility". GDScript already trades
some safety for terseness — don't compound that with cleverness.

### 2.2 Right-sized abstraction (the Rule of Three)
Do not extract an interface, base class, or helper until the **third**
concrete use case demands it. Two copies is fine. Three copies, *and* you can
articulate the shared concept in one sentence, justifies an abstraction.

Wrong direction: "We might add another enemy type later, so let's build an
`AIBehaviorTree` framework."
Right direction: "We have three enemies that all chase the player, so
`EnemyBase._chase_player(target)` exists."

### 2.3 Data over machinery
Prefer Resources, dictionaries, and small data classes over deep class
hierarchies. Items, skills, stat modifiers, room templates — all of these are
*data*. The code that reads them should be small and obvious.

If you can describe a feature with a `.tres` file or a `Dictionary` literal,
do that before reaching for a new class.

### 2.4 Signals at the seams, direct calls within a system
Within a tightly-coupled system (e.g. the player and its stats Resource), use
direct method calls. Across system boundaries (combat → camera shake, enemy
death → UI), use signals. This keeps each system testable in isolation and
prevents a web of cross-references.

The signal hubs we already have:
- `HitFeedback` autoload — combat → camera/UI/sprite
- `DemonManager` autoload — global latch lock for soul-drain
- `TransitionManager` autoload — scene transitions

Resist adding a fourth singleton without a written justification.

### 2.5 Tests are the first contract
Every behaviour change starts with a failing test (TDD). The spec drives the
test, the test drives the implementation. If a refactor breaks tests, the
tests are usually right and the refactor is wrong — fix the refactor first.

### 2.6 Keep the file count flat
A new directory is a tax on every future search. Add one only when the
existing directory has > ~10 closely-related files *and* a clear sub-concept
emerges. Prefer a longer file with related functions over many tiny files
that hop around the tree.

### 2.7 Godot-idiomatic over framework-idiomatic
We use `@onready`, `@export`, scene composition, signals, and groups because
they are how Godot works. Do not import patterns from Java/TypeScript that
fight the engine. If the engine offers a built-in (e.g. `Tween`,
`AnimationPlayer`, `NavigationAgent3D`), use it before writing a substitute.

---

## 3. System map (current state)

```
                ┌──────────────────────────────────────┐
                │            Autoloads                 │
                │  DemonManager / HitFeedback /        │
                │       TransitionManager              │
                └──────────────────────────────────────┘
                          ▲       ▲       ▲
                          │ signals │ signals │
   ┌──────────────────────┴┐    ┌──┴──────┐  └─────────────┐
   │       Player          │    │ Enemies │                │
   │  (CharacterBody3D)    │◀──▶│ EnemyBase│                │
   │                       │    │ Demon /  │                │
   │  uses: PlayerStats,   │    │ Imp /    │                │
   │  Inventory,           │    │ Brute /  │                │
   │  EquipmentManager,    │    │ Skitterer│                │
   │  Skills[4]            │    └──────────┘                │
   └────┬──────────────────┘                                │
        │ signals                                           │
        ▼                                                   ▼
   ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐
   │     UI       │  │    World     │  │    E2E Autobot         │
   │ HealthOrbs/  │  │ DungeonGen,  │  │ Headless playthrough   │
   │ Hotbar/      │  │ FogOfWar,    │  │ + screenshot capture   │
   │ Minimap/     │  │ Pickups,     │  └────────────────────────┘
   │ Inventory    │  │ Destructible │
   └──────────────┘  └──────────────┘
```

Three independent surfaces touch the player:
1. **Stats / equipment / inventory** — pure data Resources, no scene tree.
2. **Combat** — uses `Area3D` overlap, talks to `HitFeedback`.
3. **Movement / state machine** — `_physics_process`, simple enum.

These three are kept separate inside `player.gd`. Don't merge them.

---

## 4. Layering rules

These rules are enforced by code review, not by tooling. They are tight
enough that violating them feels wrong.

| Layer | Allowed dependencies | Example |
|------|----------------------|---------|
| **Resources** (`scripts/items/`) | Other Resources, GDScript stdlib | `PlayerStats`, `ItemResource` |
| **World/Enemies** | Resources, `Node`/`CharacterBody3D` | `EnemyBase`, `DemonBase` |
| **Player** | Resources, World, Autoloads | `player.gd` |
| **UI** | Player (read-only via signals), Resources | `HealthManaOrbs` |
| **Autobot/Tests** | Everything | `autobot.gd` |

**Rule**: a Resource never reaches into the scene tree. If it needs to
broadcast change, it uses signals; the consumer in the scene tree subscribes.
This is what lets us unit-test stats and inventory without a SceneTree.

---

## 5. Naming and file conventions

- File names: `snake_case.gd`. Class names (`class_name`): `PascalCase`.
- One `class_name` per file, declared on line 2 (after a comment).
- `_private` prefix for fields the rest of the system shouldn't touch.
- Directory layout under `scripts/`:
  - `items/` — data Resources (PlayerStats, Inventory, ItemResource…)
  - `enemies/` — enemy nodes
  - `world/` — rooms, fog, pickups, destructibles
  - `ui/` — Control nodes
  - `vfx/` — visual feedback helpers
  - `audio/` — audio managers
  - `e2e/` — end-to-end autobot
- Tests mirror script paths under `tests/unit/test_<name>.gd`.

If a file doesn't fit any of these, ask before creating a new directory.

---

## 6. The architect's playbook

Grant, this section is yours.

### 6.1 What "architect" means here
You are **not** building cathedrals. You are the person who notices when a
file has crossed a complexity threshold and asks: "Can three lines of
deletion fix this instead of three classes of addition?"

Your bias should be **subtractive**. Delete code when possible. Move code
*before* abstracting it. Abstract only after duplication is undeniable.

### 6.2 Refactor heuristics — when to reach for which tool

| Symptom | First thing to try | Last resort |
|---------|-------------------|-------------|
| Two near-identical functions | Inline both, see if difference is meaningful | Extract a helper |
| 200-line function | Split by paragraph (group of related lines) into named locals or private functions in the same file | New class |
| `if type == FOO: ... elif type == BAR: ...` | Dictionary lookup | Polymorphism |
| "I might need this later" | Stop. Do not commit it. | — |
| Cross-system reference (player imports UI) | Replace with signal | Mediator/event bus |
| Shared mutable state (singletons multiplying) | Make data flow one-directional | Dependency injection |
| Test is hard to write | The *code* is wrong, not the test | — |

### 6.3 Refactor anti-patterns we explicitly reject

- **Speculative generalization.** "An interface for future enemy types." No.
- **Hexagonal architecture / ports & adapters.** This is a 3D game, not a
  banking system. `CharacterBody3D` *is* the abstraction.
- **Premature dependency injection.** Autoloads exist; using them is fine.
- **Premature event bus.** We have three signal hubs. A fourth needs an ADR.
- **Mass renames "for consistency".** Cost > benefit; touch only what you
  touch for other reasons.
- **Splitting a 100-line file into five 20-line files.** This is just churn.

### 6.4 The architect's review checklist

When reviewing a spec or implementation, in this order:

1. **Is this the simplest thing that satisfies the spec?**
   If you removed the abstraction, would the code still work? Then remove it.
2. **Where are the seams?**
   What can be tested without a SceneTree? Push as much logic there as
   possible.
3. **Does this duplicate existing infrastructure?**
   Check `HitFeedback`, `PlayerStats`, `EnemyBase`. Reuse before re-create.
4. **Is the data shape stable?**
   If the spec implies the shape will change every sprint, hold off on
   building anything reusable around it.
5. **Will the next reader understand this in 60 seconds?**
   No? Rewrite for clarity, not for elegance.

### 6.5 Output format for an architectural review

When Alucard sends you a spec or a diff, respond with three sections:

```
## Concerns
- [BLOCKING|MAJOR|MINOR] <one-line concern>: <why it matters>

## Suggestions
- <concrete code-level change>

## Approval
APPROVED | NEEDS-REVISION | REJECTED
```

`BLOCKING` = will cause bugs or violate a Principle.
`MAJOR` = will hurt readability/maintainability significantly.
`MINOR` = nit, take it or leave it.

Avoid prose-only responses. Concrete suggestions only. If you can't suggest
a specific change, you don't have a real concern yet.

### 6.6 What you don't own

- Game design / feel decisions — Alucard owns those.
- Spec content — Sypha owns those.
- Test design — Trevor and Richter own those.
- Performance micro-optimization — only flag if profiler shows a problem.
- Style/formatting that doesn't affect comprehension — leave it.

---

## 7. Decision log (lightweight ADRs)

We do not maintain a heavyweight ADR process. Instead, when a non-obvious
choice is made, add a one-paragraph entry here. New entries go on top.

### ADR-008: PartyConfig autoload (4th singleton)
*Why:* Character selections and per-player device assignments must survive
the scene transition from `character_select.tscn` to `main.tscn`. The
alternatives (passing a Resource via `set_meta`, querying the previous
scene) were more fragile than a single read-only-after-character-select
data carrier. PartyConfig holds **only configuration**, never per-frame
mutable state, which is why it's an acceptable singleton. The autoload
budget (Section 2.4) is now exhausted; a 5th requires a new ADR.

### ADR-007: PlayerStats is a Resource, not a node
*Why:* Stats are data. Making them a Resource lets us serialize, save, and
unit-test them without a SceneTree. The Player owns the resource.

### ADR-006: Signal-based hit feedback
*Why:* Camera shake, hit-stop, damage numbers, and sprite flash are all
"reactions to a hit". Centralizing them via `HitFeedback` autoload means new
hit sources only emit one signal; consumers wire themselves up.

### ADR-005: Three autoloads, no more without an ADR
*Why:* Autoloads are global state. Three is a budget; crossing it requires
explicit justification. (DemonManager, HitFeedback, TransitionManager.)

### ADR-004: GUT for testing
*Why:* It runs headless under Godot, has matchers, integrates with the
editor. Patched once for Godot 4.6 (`Logger` class collision renamed to
`GutLogger` in `addons/gut/utils.gd`).

### ADR-003: Castlevania-themed agent names mapped to TDD roles
*Why:* Easier to remember which agent does what; reinforces the pipeline
shape. Alucard (lead) → Sypha (spec) → Grant (architect) → Trevor (tests) →
Richter (test review) → Shanoa (impl) → Julius (code review) → Maria (test
runner).

### ADR-002: Specs are the contract
*Why:* Tests are derived from specs, implementation is derived from specs.
The spec is the only document that all downstream agents trust. If the spec
is wrong, fix the spec first.

### ADR-001: GDScript only, no GDExtension
*Why:* One language across the codebase. We can revisit if profiling reveals
a real hotspot.

---

## 8. When to deliberately violate this document

These principles are heuristics, not laws. Deviate when:

- **A bug is on fire.** Ship the fix; clean up after.
- **The engine forces it.** If Godot's idiom contradicts a principle, the
  engine wins.
- **You have a stronger argument.** Write it down as an ADR and propose it.
  We update the document, then we change the code.

Do *not* deviate because:

- Another codebase you saw did it differently.
- It "feels cleaner" without a concrete win.
- You're bored.

---

## 9. Quick reference for Grant

- Read the spec → check Section 2 (principles) → check Section 6.4
  (checklist) → respond in the Section 6.5 format.
- Default mode: subtractive.
- Default verdict: APPROVED with MINOR notes. Save BLOCKING for real
  problems.
- If you find yourself proposing a 5-file refactor for a 1-file change,
  stop and re-read Section 2.2.
