# Tech Debt

> Audience: agents tempted to "just clean this up real quick." Each entry
> documents a known wart, where it came from, and why it isn't being fixed
> *today*. If you want to take one on, open an issue first and link it
> to its row here.

Entries are roughly ordered by surface area, not by severity.

## 1. Pre-existing parse errors on `main.gd` under autobot flag

`scripts/main.gd` reports standalone GDScript parse errors when the file is
loaded by the autobot runner (`scripts/e2e/autobot_runner.gd --script` flag),
specifically around `RunStats` and `BiomeManager` `class_name` resolution
order. The full game runs and tests pass — the errors are silent in the
normal scene-load path. **Origin:** introduced when `RunStats` and
`BiomeManager` were promoted to `class_name` types (pre-`3fea189`). **Fix:**
likely a small reorder of preloads or a switch to the static-script pattern;
held off because it's invisible to players and risks touching the boot path.

## 2. Manual Signals-Catalog

The signals catalog page is hand-maintained. Every new `signal foo()` in a
script means a wiki edit. **Origin:** added when the wiki was first scaffolded.
**Fix:** a small script that walks `scripts/**/*.gd`, greps `^signal `, and
regenerates the catalog. Defer because the rate of new signals is low and the
catalog is read more than written.

## 3. `load()` self-reference workarounds in Resources

`scripts/items/item_set.gd` and `scripts/world/biome_def.gd` use the pattern:

```gdscript
var Script: GDScript = load("res://scripts/items/item_set.gd")
```

…inside their own classes because Godot 4.6 still won't let a `class_name`
resource fully self-reference at parse time (the editor errors with
"identifier not declared" in factories). **Origin:** Godot 4.6 limitation —
not our bug. **Fix:** track upstream; revisit when 4.7 / 5.x ships. Don't
"clean up" by deleting these — the game won't load.

## 4. Settings file path is hard-coded

`scripts/settings.gd` writes to a single fixed `user://` path. There's no
per-profile override (e.g. `--user-dir`), no atomic write, no migration if
the schema changes. **Origin:** simplest thing that worked when settings
landed. **Fix:** introduce a versioned settings dict and a profile id; do
this together with the eventual save/load work, not separately.

## 5. `PartyConfig` uses untyped dicts

`PartyConfig.slots` is `Array` of `Dictionary` literals
`{"character_class_id": int, "device_id": int}`. It works and is unit-tested
but type-unsafe — typos in keys silently return `null`. **Origin:** chose
dicts over a typed `PartySlot` resource for speed during co-op bring-up.
**Fix:** migrate to a `PartySlot extends Resource` with typed `@export`s.
Mechanical, but touches `character_select.gd`, `player_count.gd`, and the
player spawn path in `main.gd`.

## 6. No script auto-builds Spec-Index

[Spec Index](../06-reference/Spec-Index.md) is hand-maintained against
`docs/specs/*.md`. New specs are easy to forget. **Origin:** wiki was
scaffolded by hand. **Fix:** small generator that lists `docs/specs/`,
greps for status hints, and writes the table. Defer until specs change
faster than humans can keep up.

## 7. `HitFeedback` has no SFX listener

The `HitFeedback` autoload broadcasts every signal a sound system would need
(`request_camera_shake`, `request_hit_stop`, `request_damage_number`,
`request_sprite_flash`) but no audio listener subscribes. The combat
feedback is silent. **Origin:** the audio pass is queued for the next
sprint (see [Future Work → SFX pass](Future-Work.md#next--could-ship-in-the-current-sprint)).
**Fix:** add an `AudioRouter` autoload; covered by the planned SFX pass.

## 8. Hit-flash duplicates surface material per hit

`scripts/enemies/enemy_base.gd:47` calls
`mesh.mesh.surface_get_material(0).duplicate()` on every flash to avoid
mutating the shared material. Suspected memory churn / leak — Godot
should garbage-collect these but we haven't profiled. **Origin:** safest
implementation when sprite flash was introduced. **Fix:** cache one
duplicated material per enemy on `_ready` and re-tween it. Verify with
`OS.get_static_memory_usage()` over a long autobot run before/after.

## 9. Knockback as `_process` positional offset

`scripts/enemies/enemy_base.gd` applies knockback by writing
`global_position += _knockback * delta` and decaying `_knockback` toward
zero. This is a workaround for AI velocity collisions clobbering the impulse
when each archetype subclass owns its own movement loop. **Origin:**
pragmatic fix during enemy-variety-v2 bring-up. **Fix:** unify enemy
movement under a base velocity model so knockback can apply to actual
`velocity` like a physics body. Revisit when (or if) the enemy AI gets
a single shared movement controller.

## 10. `enemy-variety` (v1) spec still in repo

`docs/specs/enemy-variety.md` was superseded by `enemy-variety-v2.md` but
never deleted. New contributors land here first. **Origin:** historical.
**Fix:** delete v1 (or move under a `docs/specs/_archived/` directory) and
update [Spec Index](../06-reference/Spec-Index.md). Cheap; just hasn't been
done.

## See also

- [Known Gaps](Known-Gaps.md) — *missing* features, vs. *broken* internals here.
- [Coding Standards](../05-contributing/Coding-Standards.md) — what good looks like.
