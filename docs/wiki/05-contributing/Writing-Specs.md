# Writing Specs

Specs are the single source of truth for everything downstream — Test-writer
writes tests from them, Test-reviewer audits coverage against them, Implementer
implements from them. **If the spec is wrong, fix the spec first.**

Specs live in [`docs/specs/<feature-name>.md`](../../specs). Browse that
directory for examples; particularly good ones to study:

- [`docs/specs/enemy-variety.md`](../../specs/enemy-variety.md) — clean
  numbered REQ format, edge cases, explicit out-of-scope.
- [`docs/specs/set-items.md`](../../specs/set-items.md) — data-shape
  spec with concrete tuning numbers and a `Tests` section.

## Template

```markdown
# <Feature Name>

## Problem
One paragraph. What's broken / missing / unclear today and why does it
matter? Who feels the pain? Avoid solution language.

## User-facing behavior
What changes from the player/contributor perspective. Describe inputs
and outputs, not implementation. Numbers (HP, speed, cooldown) belong
here when they affect feel.

## Acceptance criteria
Numbered `REQ-N` items. Each one is testable in isolation.

### REQ-1: <Short name>
**Given** <precondition>
**When** <action>
**Then** <observable outcome with concrete values>

### REQ-2: ...

## Out of scope
Bullet list of things this spec deliberately does NOT cover. Saves
arguments later.

## Open questions
`[NEEDS CLARIFICATION: …]` markers, or a list of decisions deferred to
implementation. Empty section is fine.
```

## What "testable from the spec alone" means

Test-writer will write tests **without reading any production code**. If the
spec doesn't tell him what numbers to assert, what signals to watch, or
what edge cases to cover, the tests will be wrong.

Two test you should be able to write straight from the spec:

> **REQ-3:** Skitterer has low HP (15), low damage (5), fast move_speed
> (6.0), and always spawns in groups of 3-5 from a single spawn point.

```gdscript
func test_req3_skitterer_stats() -> void:
    var s := SkittererScene.instantiate()
    assert_eq(s.max_health, 15.0)
    assert_eq(s.damage, 5.0)
    assert_eq(s.move_speed, 6.0)
```

If you can't trace a test back to a `REQ-N`, the spec is missing
something.

## What a good spec is not

- **Implementation guide.** No file paths, no class names, no "add a
  helper to `EquipmentManager`". Spec-writer describes WHAT; Architect and Implementer
  decide HOW.
- **Wishlist.** A spec ships in one PR. Anything bigger is two specs.
- **Stream of consciousness.** Edits should be possible in one screen of
  diff. Trim ruthlessly.
- **Code-reading shortcut.** "Look at how `imp_caster.gd` does it" is
  not a requirement.

## When the spec changes

Specs evolve. When a request is added or refined:

1. Edit the spec file in the same PR as the implementation change.
2. Bump or renumber `REQ-N` if behavior changes — old tests pinned to
   the old REQ get rewritten.
3. Note the change in the PR body so reviewers see it.

## Who owns specs

[Spec-writer](Squad-And-Agents.md#spec-writer--spec-writer) writes them. Anyone can
*propose* a spec, but Spec-writer + Lead sign off before tests start. See
[Workflow](Workflow.md) for where in the pipeline this happens.
