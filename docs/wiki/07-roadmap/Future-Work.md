# Future Work

> Audience: agents proposing or scoping new features. Grouped by **horizon**,
> not priority. Linked specs are drafts where they exist; if a row has no
> link, no spec has been written yet — write one before coding.

See also [Known Gaps](Known-Gaps.md) for things deliberately not on the
list, and [Release Checklist](Release-Checklist.md) for what gates v0.1.

## Next — could ship in the current sprint

These have a clear scope, existing scaffolding, and known integration points.

| Item | Why it's valuable | Hook into existing code |
|---|---|---|
| **SFX pass** | The single biggest "feel" win still on the board. Hit-stop and screen shake exist but the audio half is silent. | Add an `AudioRouter` autoload that listens to `HitFeedback.request_*` and to `Player`/`EnemyBase` death signals. See [`docs/specs/ambient-sound.md`](../../specs/ambient-sound.md) — extend, don't replace. |
| **Vendor NPC (run-local)** | Gives players agency over loot — sell junk, buy targeted gear. Even a run-local vendor (no save) closes the "useless drops" complaint. | New scene under `scenes/world/`, leverage `Inventory` and the gold counter on `Player`. |
| **Stat respec UI** | Low-cost fix for the "I picked the wrong level-up choice" footgun. | Reuse `LevelUpPanel` — add a "Respec" button that refunds points to a pool. `PlayerStats` already separates `base_*` from `modifiers`, so the math is straightforward. |
| **Pause-menu key-rebind** | One screen, mostly UI work. Closes a major Settings gap. | `Settings` already persists key/value; add a remap UI that writes to `InputMap` and serializes. |
| **Run-summary polish** | `RunStats` already tracks rich data; the screen under-uses it. | `scripts/ui/game_over_screen.gd`. |

## Later — needs a spec first

Real engineering work, plausible scope, but no spec has been written.

| Item | Why it's valuable |
|---|---|
| **Town hub scene** | Persistent space between runs to host vendor, stash, run-start portal — the visual home for meta-progression. Depends on **save/load** ([Known Gaps](Known-Gaps.md#save--load)). |
| **Skill tree / passive nodes** | Adds long-term build identity beyond flat affixes. Needs a node-graph schema, UI, and a balance pass. |
| **Networked co-op** | Lifts couch co-op into "play with a remote friend." Touches every state-mutating system; needs an authority model and replication layer. |
| **5+ biomes** | Today the biome rotation is short; more themed palettes increase per-run variety. Pattern is in `BiomeDef` / `BiomeManager`, just needs assets and an enemy mix per biome. |
| **Boss-only fights** | Dedicated rooms with a unique enemy and arena layout — gives floors a punctuation mark. `RunStats.boss_kills` already tracks it. |
| **Affix re-roll vendor** | Targeted item improvement; pairs with vendor work above but operates on `ItemResource.stat_modifiers`. |
| **Ground-effect telegraphs** | Visible warning circles before AoE attacks — readability improvement for elites and bosses. |
| **Damage / DPS overlay (debug)** | Optional contributor tool — read out per-second damage from the existing `RunStats.damage_dealt`. |

## Maybe — long shots

Worth considering only after the v0.1 loop is rock solid.

| Item | Why it's valuable |
|---|---|
| **Mod support** | User-defined items, skills, biomes — Godot's resource system makes this plausible (drop-in `.tres` files), but it requires a stable schema. |
| **Custom dungeons** | Players design / share dungeon layouts. Sits on top of `DungeonGenerator` — would need a serialization format and a sharing pipeline. |
| **Story campaign** | Hand-crafted floors with scripted encounters and dialog. Big content investment; would coexist with the roguelike mode rather than replace it. |
| **Map editor** | Both an internal designer tool and a player-facing feature once mod support exists. |
| **Daily seeded run / leaderboard** | Lightweight competitive mode; depends on `DungeonGenerator` becoming fully seedable and a back-end for scores. |
| **Cosmetic-only unlocks** | Class skins, weapon trails, pet companions — non-balance unlocks tied to meta-progression. |
| **Steam / itch achievements** | One-line wrappers around `RunStats` milestones; trivial *if* the platforms are targeted. |
| **Replay recording** | Record `Input` event stream + RNG seed to deterministically replay runs. Requires hard determinism in the simulation, which we don't currently guarantee. |

## How to land an entry from this list

1. Pick a row.
2. If it has no spec, write one in `docs/specs/<feature>.md` following the
   existing template (Overview / Requirements / Edge Cases / Out of Scope).
   See [Writing Specs](../05-contributing/Writing-Specs.md).
3. Add a corresponding row to [Spec Index](../06-reference/Spec-Index.md).
4. Add tests under `tests/unit/` and link them in [Test Index](../06-reference/Test-Index.md).
5. Open a PR following [Commit & PR Conventions](../05-contributing/Commit-And-PR-Conventions.md).

## See also

- [Known Gaps](Known-Gaps.md) · [Tech Debt](Tech-Debt.md) · [Release Checklist](Release-Checklist.md)
