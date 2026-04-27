# Decision: Enemy/Demon System Architecture

**Author**: Alucard (Lead)
**Date**: 2025-07-14
**Status**: Agreed — ready for implementation

## Context

Tim and the team agreed on the core enemy/demon system for Flower. This decision documents the agreed design so all agents respect it going forward.

## Decision

### Soul Mechanic
- Soul is a 15-second drain timer (separate from health). Drains linearly from 100 → 0 when a demon is latched.
- Soul reaching 0 = death (demon absorbs the wisp, player collapses).
- Health is a conventional HP pool, damaged by non-demon enemies and fighter drainer melee attacks.
- Multiplayer soul recovery (teammate revive) is **deferred** — solo mode first.

### Latch Interaction
- One demon latches at a time. Others attack health normally while waiting.
- Player is frozen during latch (cannot move) but CAN still attack.
- Breaking free: deal enough cumulative damage to the latched demon (threshold varies by demon type).
- On demon death while latched: soul wisp is released and returns to player, restoring drained soul.

### Demon Types (first pass: 3 types)
1. **Pure Drainer** — approaches, latches, drains soul only. No health damage. Low HP. The pressure enemy.
2. **Fighter Drainer** — fights with melee AND can latch to drain. Dual threat. Medium HP.
3. **Boss/Elite** — tougher fighter drainer. More HP, special attacks (ground slam), faster drain. Appears at key points.

### Spawning
- Mix of pre-placed (scene editor) and dynamic (emerging from ground near player/at spawn points).
- Emerge animation: demon crawls out of ground, invulnerable during emerge (~1.7s window).
- SpawnManager per level area, wave-based with configurable limits.

### Visuals
- Soul wisp: ghost/spirit sprite that leaves player and floats to demon during drain. Returns on demon death. Absorbed on soul death.
- All enemies use AnimatedSprite3D (matching player visual style).
- Free/CC0 assets from itch.io and OpenGameArt.

### Architecture
- `DemonManager` autoload singleton coordinates one-at-a-time latch lock.
- `demon_base.gd` shared base with state machine, extended by each demon type.
- Player extended with soul/health properties, state machine, latch API.
- `SoulWispManager` handles wisp lifecycle based on player signals.

## Specs Written
- `docs/specs/soul-system.md` — Soul & Health System
- `docs/specs/demon-behavior.md` — Demon AI & Behavior
- `docs/specs/demon-spawning.md` — Spawn System
- `docs/specs/demon-assets.md` — Art Requirements & Asset Sourcing
- `docs/specs/soul-wisp-vfx.md` — Soul Wisp Visual Effects

## Consequences
- Player.gd needs significant extension (soul/health properties, state machine, latch API, signals)
- New autoload: DemonManager
- New scripts: demon_base.gd, three demon type scripts, spawn_point.gd, spawn_manager.gd, soul_wisp.gd, soul_wisp_manager.gd, player_hud.gd
- New scenes: 3 demon .tscn files, soul_wisp.tscn, player_hud.tscn
- Need to source demon + wisp sprites before visual implementation

## Assignment Recommendation
- **Trevor**: soul-system.md, demon-behavior.md, demon-spawning.md (gameplay systems)
- **Sypha**: demon-assets.md, soul-wisp-vfx.md (visual systems)
- Trevor starts with placeholders; Sypha sources real art in parallel
