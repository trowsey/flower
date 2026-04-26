# Known Gaps

> Audience: agents about to "fix" something only to discover it was
> deliberately left out. Read this before opening an issue titled
> "Flower has no save system."

These are features that **don't exist on purpose** at the current scope.
Each section says **what's missing**, **how much exists today**, and
**why it's deferred**. If you want to take one on, see [Future Work](Future-Work.md)
and [Release Checklist](Release-Checklist.md) first.

## Audio

**Status today.** Only `scripts/audio/ambient_audio.gd` is wired. It swaps
the ambient track's `volume_db` based on `_in_combat`. Nothing else.

**Missing.**

- SFX on player attack (per combo stage), dodge, hit-stop impact
- SFX on enemy take-damage and death (per archetype)
- Item pickup, gold pickup, level-up jingles
- Skill cast / cooldown-ready cues
- UI clicks on menus
- A proper SFX bus split out from Master / Music

**Why deferred.** The `HitFeedback` autoload already broadcasts the
right signals (`request_camera_shake`, `request_hit_stop`, `request_damage_number`,
`request_sprite_flash`) — adding an `AudioRouter` listener is mechanical
once an asset pack lands. Held back on **audio asset sourcing**, not engineering.

## Multiplayer

**Status today.** Local **couch co-op** for 2 players via `PartyConfig`
(KB+M + 1 gamepad). See [Keybindings → Player 2](../06-reference/Keybindings.md#player-2-couch-co-op).

**Missing.**

- Networked play (peer-to-peer or hosted)
- 3+ player local
- Drop-in / drop-out mid-run
- Per-player camera split

**Why deferred.** Networking would touch every system that mutates state
(spawn manager, run stats, inventory, soul drain). It's a multi-sprint
investment and out of scope for v0.1. Couch co-op covers the "play with
a friend on the couch" use case at a fraction of the engineering cost.

## Story / narrative

**Status today.** None. There is no opening crawl, no NPC dialog, no
quest log, no lore beyond enemy/item flavour names.

**Why deferred.** v0.1 is a roguelike combat sandbox; design doesn't
yet require narrative framing. Adding story prematurely locks in tone
choices we haven't made.

## Save / load

**Status today.** `scripts/settings.gd` persists settings (volume,
fullscreen, damage numbers, camera shake) to disk. **Nothing else
saves.** Closing the game between waves loses the run.

**Missing.**

- Run state serialization (player stats, inventory, equipment, current
  wave/floor, RunStats counters)
- Profile / meta-progression (unlocks across runs)
- Cloud sync hooks

**Why deferred.** Roguelike runs are intentionally short; we want to
validate the loop before designing meta-progression. A full save also
needs a versioning story we haven't designed.

## Localization

**Status today.** All strings are hard-coded English. No `tr()` calls,
no `.po` / CSV translation tables, no font fallback for non-Latin scripts.

**Why deferred.** String set is still volatile (UI is being polished).
Localization should follow text freeze, not precede it.

## Stat respec, vendor / shop, town hub

**Status today.** Level-up panel grants permanent stat choices with
**no undo**. Items are picked up off the floor; **no shop NPC** exists
to sell or buy. There is **no town / hub scene** between runs — Game
Over returns straight to the main menu.

**Missing.**

- A "Reset stats" panel (probably gated behind cost or shrine)
- A vendor NPC selling items / re-rolling affixes
- A persistent hub scene with the vendor, stash, and run-start portal

**Why deferred.** All three depend on **save/load** to feel meaningful.
Without persistence, a vendor or hub is just a detour.

## Skill tree / passive nodes

**Status today.** Active skills are 4 hotbar slots (`SkillResource`).
"Passives" are flat numeric `stat_modifiers` rolled onto items or
applied via temporary buffs.

**Missing.** A node-graph passive tree (PoE-style), branching specializations,
keystone effects.

**Why deferred.** Branching trees explode the test matrix and the
balance surface. Flat modifiers are sufficient to ship the loop.

## Difficulty modes beyond Normal / Hard / Hell

**Status today.** Three discrete tiers with a difficulty multiplier on
enemy HP/damage. There is **no infinite-scaling endless mode**, **no
torment / paragon**, **no per-run modifiers** (e.g. "+50% enemy speed").

**Why deferred.** We want to balance the three baseline modes first.
Infinite scaling without a meta-progression vehicle (see save/load) gives
players nothing to chase.

## See also

- [Future Work](Future-Work.md) — what we *might* build next.
- [Tech Debt](Tech-Debt.md) — what's wrong with what we already built.
- [Spec Index](../06-reference/Spec-Index.md) — what *is* shipped.
