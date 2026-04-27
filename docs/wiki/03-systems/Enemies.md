# Enemies

## Purpose
Hostile NPCs that pressure the player. All enemies share a common base (`EnemyBase`) for health, hit-flash, knockback, drops, and elite/boss behavior; each subclass adds an AI loop in `_physics_process`. Player-facing behavior: enemies spawn in waves around you, telegraph their attacks (charger windup, bomber fuse), and on death drop blood VFX, gold pickups, and item pickups whose rarity floor scales with elite/boss status.

## Key files
- `scripts/enemies/enemy_base.gd` — abstract base; health/damage/drops/explosions/blood.
- `scripts/enemies/skitterer.gd` — fast melee swarmer (HP 12, dmg 5).
- `scripts/enemies/brute.gd` — slow tank (HP 80, dmg 18).
- `scripts/enemies/archer.gd` — kiting hitscan ranged (HP 18, range 9, has LOS check).
- `scripts/enemies/charger.gd` — telegraph→charge→recover (FSM, charge_speed=6).
- `scripts/enemies/bomber.gd` — chase→fuse→explode (death_radius=2.5, dmg=30).
- `scripts/enemies/healer.gd` — keeps distance, heals nearest wounded ally.
- `scripts/enemies/imp_caster.gd` — mid-range hitscan caster.
- `scripts/enemies/elite_affixes.gd` — `EliteAffixes.make_elite(enemy, n)` mutator.
- `scripts/enemies/demon_base.gd` — soul-draining variant; coordinates with `DemonManager` autoload.

## Data flow
```
SpawnManager / main._spawn_wave → scene.instantiate() → add_child →
  enemy._ready (collision_layer=4, mask=1, joins "enemies" group) →
  player ref captured from "player" group.

each frame:
  EnemyBase._process(delta)  → tick hit-flash modulate; apply _knockback decay
  Subclass._physics_process  → AI: move/attack/cast

take_damage(amount):
  health -= amount → emit health_changed → _hit_flash_remaining=0.1
  knockback = (self - player).normalized() * 3.0
  _spawn_blood_particles → if health<=0: die()

die():
  emit enemy_died → player.add_xp (×2 if elite) → _drop_loot()
                  → _explode() if death_explosion_radius>0
                  → _spawn_death_particles → queue_free
```

`_drop_loot` rolls gold (`gold_drop_min..max`, ×4 if boss) and an item with `chance = item_drop_chance * (3.0 if elite)`. Set drops are tried first via `ItemFactory.maybe_make_set_item(item_level, 0.25 if boss else 0.03)`. Boss flag is `set_meta("is_boss", true)` from `main._spawn_wave`.

## Public API
Exported (every enemy): `max_health`, `damage`, `move_speed`, `attack_range`, `xp_reward`, `gold_drop_min/max`, `item_drop_chance`, `death_explosion_radius/damage`, `enemy_type`, `elite`, `affixes`.

Signals:
```gdscript
signal enemy_died(enemy: Node3D)
signal health_changed(new_value: float)
```

Methods: `take_damage(amount)`, `die()`, `distance_to_player()`. All AI is inside the subclass `_physics_process`. Subclass-specific exports (e.g. `Charger.charge_trigger_range`, `Archer.fire_range`) tune behavior.

`EliteAffixes.make_elite(enemy, num_affixes=2)` multiplies HP×2.5, dmg×1.5, xp×2.0, gold×3, item-chance×4, then picks affixes from `["fast", "tough", "explosive", "venomous", "armored"]`.

`DemonBase` (separate hierarchy, still extends `EnemyBase`): adds states `ROAMING/CHASING/LATCHED/DEAD`, calls `DemonManager.request_latch(self, player)` on contact and forces release on damage.

## Tests
- `tests/unit/test_enemy_base.gd` — base health/damage/drops/explosion path.
- `tests/unit/test_new_enemies.gd` — covers archer/charger/bomber/healer/imp_caster basics.
- Gap: `EliteAffixes` has no dedicated test (asserted indirectly via wave spawning); `DemonBase` is covered through `test_soul_drain.gd`.

## Extending
**Add a new enemy:** create `scripts/enemies/foo.gd extends EnemyBase`, override `_ready` to set stats and call `super._ready()`, write a `_physics_process` AI loop. Make a matching `scenes/enemies/foo.tscn` with a `MeshInstance3D` + a `CollisionShape3D`. Add the path to `BiomeDef.enemy_scenes` of any biome it belongs to (see [Biomes-And-Waves](Biomes-And-Waves.md)) and/or to `main.gd ENEMY_SCENES` for the default pool.

**Add a new elite affix:** append to `EliteAffixes.AFFIX_POOL` and add a `match` arm in `_apply_affix`. Pure stat tweaks live there; behavioral affixes (e.g. "summoner") belong on the enemy script behind an `affixes.has("summoner")` check.

**Tweak boss scaling:** edit `main.gd::_spawn_wave` block guarded by `is_boss_wave` (the `current_wave % 10 == 0` branch).

## Known gaps
- Hit-flash currently re-tints the mesh material every frame while the timer ticks; OK for now but allocates a `StandardMaterial3D` per first hit.
- Archer/imp use hitscan even though spec talks about projectiles — see [Combat](Combat.md).
- Bomber's `EXPLODED` state is unreachable (`die()` triggers `queue_free` before the next process tick).
- No flocking / separation: enemies stack on top of the player at melee range.

## Spec/code mismatches
- `docs/specs/enemy-variety.md` describes Imp Caster and Archer as projectile users; the implementations are hitscan with optional LOS (`archer.gd:48-61`, `imp_caster.gd:44-49`). Treat the spec as aspirational or update it.
- `docs/specs/elite-enemies.md` lists affix names that may not 1:1 match `AFFIX_POOL` (`fast/tough/explosive/venomous/armored`). Verify before adding new affixes.
