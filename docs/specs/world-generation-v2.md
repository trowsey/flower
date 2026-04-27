# Feature: World Generation v2 (status & roadmap)

## Status

The current shipping game uses a **wave-spawn ring** in `main.gd` — enemies are
spawned on a 12u radius around a single arena, with biome rotation modifying
visuals and enemy pool. There is **no dungeon, no rooms, no fog of war, and no
minimap** active in the running game today.

However the codebase contains four stub modules that look architectural but
are not wired into any scene:

| Module | File | Spec | Status |
|--------|------|------|--------|
| Dungeon generator | `scripts/world/dungeon_generator.gd` | [procedural-rooms.md](./procedural-rooms.md) | Stub — never instantiated |
| Spawn manager     | `scripts/world/spawn_manager.gd`     | (implicit) | Stub — never instantiated |
| Fog of war        | `scripts/world/fog_of_war.gd`        | [fog-of-war.md](./fog-of-war.md) | Stub — never added to scene |
| Minimap           | `scripts/ui/minimap.gd`              | [minimap.md](./minimap.md) | Stub — never added to HUD |

Per `docs/architecture.md` §6.1 (subtractive bias) these would normally be
deleted. They are kept on the explicit decision recorded in this spec because
together they form the **next major content arc** for the game.

This spec is the contract for getting them out of stub state.

## Goal

Replace the wave-spawn arena with an explorable mini-dungeon (4–8 rooms), keep
the existing wave/biome cadence inside each "combat" room, and surface
exploration through fog-of-war + minimap UI.

## Phased delivery

### Phase 0 — current state (DONE)

- Wave-spawn arena with biome rotation in `main.gd`.
- Stub modules exist but are unreferenced.

### Phase 1 — Spawn manager into `main.gd` (small)

**Why first**: lowest-coupling change. `main.gd._spawn_wave` already does what
`SpawnManager.spawn_wave` does, just inline. Replacing it removes duplication
and gives the dungeon work a hook point.

**Acceptance**:
- `main.gd` constructs one `SpawnManager` per "room" (initially: one room, the
  arena) and calls `spawn_wave()` on wave start.
- `SpawnManager` exposes `spawned` signal so `main.gd` can hook
  `tree_exiting` for kill stats.
- Existing wave-clear / boss-wave / elite-wave behaviour preserved.
- All existing tests still pass.

### Phase 2 — `DungeonGenerator` produces a graph (small)

**Why next**: data-only change, no scene-tree work. Generator produces a
`Dictionary<Vector2i, RoomData>`. Nothing visual yet.

**Acceptance**:
- `main.gd` instantiates a `DungeonGenerator`, calls `generate_floor(3)`.
- Player spawns in `current_room = (0,0)`. Existing arena is room (0,0).
- Other rooms exist as data only; no scene built.
- Add `test_dungeon_generator.gd` covering: room count, door symmetry,
  `mark_cleared`, `enter_room`.

### Phase 3 — Minimap reads dungeon graph (small)

**Why**: visualises Phase 2 with no scene-tree changes to the world.

**Acceptance**:
- `Minimap` instantiated as a HUD child by `main.gd` (like `InventoryScreen`).
- Reads from `main.dungeon` (or via an exposed accessor) and renders
  `RoomData` rectangles + player chevron.
- `enter_room` marks visited; minimap reflects it next frame.
- Add `test_minimap.gd`: visited room shown, unvisited not shown.

### Phase 4 — Fog of war + room teleport (medium)

**Why last**: this is the only phase that touches scene rendering.

**Acceptance**:
- Player carries an `OmniLight3D` (already partially set up in `player.tscn`).
- `WorldEnvironment.ambient_light_energy = 0.05`.
- Crossing a room edge triggers a fade + teleport to that room's spawn point;
  enemies are despawned and re-spawned via `SpawnManager` for the new room.
- Boss room is the last unvisited room with `room_type=="boss"`.

## Out of scope (for this spec)

- Hand-authored room templates (procedural-rooms.md REQ-1/REQ-2). The graph
  works with a single procedurally-walled arena per room until art exists.
- Multi-floor descent.
- Save/load of dungeon state.

## Notes for agents

- Each phase is independently shippable. **Do not** start Phase 2 before
  Phase 1 lands and is green.
- If a phase reveals that a module is structurally wrong, **delete the
  module** and update this spec. Don't keep code that doesn't fit.
- Architectural rule unchanged: world/* may not reach into scene tree
  internals of player or UI. Pass data via signals/properties.
