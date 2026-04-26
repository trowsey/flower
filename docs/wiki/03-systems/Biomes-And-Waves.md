# Biomes and Waves

## Purpose
The wave loop is the run's heartbeat: enemies spawn in a ring around the player; kill them all and a new wave starts after an 8-second beat. The biome rotates every 5 waves to change the enemy pool and visuals; every 10th wave is a boss; every 3rd wave (from wave 3 on) drops a shrine. Player-facing behavior: visible wave counter and biome name in the HUD banner, color-shift on the floor/walls when biomes flip, "BOSS WAVE" label on multiples of 10.

## Key files
- `scripts/main.gd` — owns the wave loop (`_process` → `_spawn_wave` → `_spawn_shrine`), enemy scaling, biome visual application.
- `scripts/world/biome_def.gd` — `BiomeDef` Resource + 4 hardcoded biomes (`crypt`, `cavern`, `forge`, `garden`).
- `scripts/world/biome_manager.gd` — `BiomeManager` Node, advances `_index` every 5 waves, increments `difficulty_loop` on full rotation.
- `scripts/world/dungeon_generator.gd` — currently unused by `main.gd`; reserved for future per-room layouts.
- `scripts/world/spawn_manager.gd` — alternate spawner used by tests / future room mode.

## Data flow
```
main._ready: BiomeManager added as child, _apply_biome_visuals(current biome)

main._process(delta):
  if no enemies in "enemies" group:
    _wave_timer += delta
    if _wave_timer >= 8.0:
      run_stats.record_wave_cleared()
      emit wave_cleared(current_wave)
      biome_manager.notify_wave_cleared(current_wave)
        if current_wave % 5 == 0:
          _index = (_index + 1) % _biomes.size()
          if _index == 0: difficulty_loop += 1
          emit biome_changed → main._on_biome_changed → _apply_biome_visuals
      current_wave += 1
      _spawn_wave()

_spawn_wave():
  count = 6 + (player_count-1)*4 + (current_wave-1)*2
  wave_mult = 1.0 + (current_wave-1)*0.10
            * difficulty_mult                      ← from PartyConfig meta
            * (1.0 + 0.20 * biome_manager.difficulty_loop)
  if current_wave % 5 == 0: pick a random spawn index to force-elite
  if current_wave % 10 == 0: index 0 becomes a boss (HP×5, dmg×1.8, xp×5, scale 1.6)
  pool = biome_manager.enemy_pool() if any, else main.ENEMY_SCENES
  for i in count: instantiate, _scale_enemy_for_difficulty, place around SPAWN_RING_RADIUS=12
  if current_wave >= 3 and current_wave % 3 == 0: _spawn_shrine()
```

`_scale_enemy_for_difficulty(enemy, avg_level, wave_mult)` applies:
- HP × `(1 + max(0, avg_level - 1) * 0.15) * (1 + (player_count-1) * 0.25) * wave_mult`
- DMG × `(1 + max(0, avg_level - 1) * 0.10) * wave_mult`

## Public API
**`BiomeDef`** (Resource): `biome_id`, `display_name`, `floor_color`, `wall_color`, `ambient_color`, `enemy_scenes: Array[String]`. `BiomeDef.ALL()` returns the 4 canonical biomes; constructed via `_make(...)`.

**`BiomeManager`** (Node):
```gdscript
const WAVES_PER_BIOME := 5
signal biome_changed(biome: Resource)
var difficulty_loop: int = 0    # +1 every full rotation through all biomes
func current() -> Resource
func enemy_pool() -> Array      # forwarded from current().enemy_scenes
func notify_wave_cleared(wave_just_cleared: int) -> void
```

**`main.gd`** signals: `wave_started(wave: int)`, `wave_cleared(wave: int)`, `biome_changed(biome)`. `current_biome()` accessor.

## Tests
- `tests/unit/test_biomes.gd` — `BiomeManager` rotation cadence and `difficulty_loop` increment.
- `tests/unit/test_world.gd` — covers `DungeonGenerator` (currently unused by main) and shared world helpers.
- Gap: no integration test for the boss-every-10 / shrine-every-3 cadence; would require a stubbed `main.gd` driver.

## Extending
**Add a new biome:** append a `_make(...)` entry to `BiomeDef.ALL()` with colors and `enemy_scenes`. The rotation picks it up automatically — biomes are visited in the order they appear.

**Change rotation cadence:** edit `BiomeManager.WAVES_PER_BIOME`. Boss interval (10) and shrine interval (3) live in `main.gd::_process` / `_spawn_wave`.

**Tune difficulty curve:** the three knobs are `_scale_enemy_for_difficulty`, the `(current_wave-1) * 0.10` term in `_spawn_wave`, and the `0.20 * biome_loop` post-rotation bump. Keep the per-wave term gentle (waves are frequent).

**Use proper rooms / hand-built layouts:** wire `DungeonGenerator` (`scripts/world/dungeon_generator.gd`) and `SpawnManager` (`scripts/world/spawn_manager.gd`) into `main.gd`. They exist but `main.gd` ignores them today; spawning is purely procedural-ring around the player.

## Known gaps
- Spawning is a ring of fixed radius (12u) with random angular offsets — no LoS/wall checks, no terrain awareness.
- Wave clear detection is "no nodes in 'enemies' group" — if a script forgets `add_to_group("enemies")` it'll skip wave clear.
- Shrine spawn point is also unguarded (random angle/distance), can land in walls in scenes with walls.
- `DungeonGenerator` and `SpawnManager` are dead code from the perspective of `main.gd`; either wire them up or remove.
- The current 4 biomes are visual-only color tints; no biome-specific hazards, music, or layouts yet.

## Spec/code mismatches
- `docs/specs/biomes.md` and `docs/specs/wave-counter.md` should be cross-referenced; the boss / shrine cadence is in `main.gd`, not specs.
- `docs/specs/procedural-rooms.md` describes a `DungeonGenerator`-driven layout that **is not in use** in `main.tscn`; treat as design doc, not implementation reference.
