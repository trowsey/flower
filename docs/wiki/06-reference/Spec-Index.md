# Spec Index

> Audience: agents triaging work. One row per spec in `docs/specs/`.
> Status reflects post-commit `3fea189` (190 unit + 10 E2E green).

**Status legend**

- ✅ **Shipped** — implementation in `scripts/` matches the spec; tests cover it.
- 🚧 **Partial** — code exists but some REQs are unimplemented or untested.
- 📋 **Specced only** — no implementation found in the codebase yet.
- ⚠️ **Spec drift** — implementation exists but diverges from the written spec; reconcile before relying on either.

Implementation paths are relative to repo root. "Tests" links to files under `tests/unit/`.

## Combat

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [player-attack](../../specs/player-attack.md) | ✅ Shipped | `test_player_attack.gd` | `scripts/player.gd` (`_perform_attack`, `_apply_attack_damage`) |
| [combo-attacks](../../specs/combo-attacks.md) | ✅ Shipped | `test_player_combat_polish.gd`, `test_player_attack.gd` | `scripts/player.gd` (`_combo_*`, `COMBO_DAMAGE_MULT`) |
| [attack-speed](../../specs/attack-speed.md) | ✅ Shipped | `test_player_stats.gd`, `test_xp_and_crit_stats.gd` | `scripts/items/player_stats.gd::attack_speed()` |
| [hit-feedback](../../specs/hit-feedback.md) | 🚧 Partial | `test_player_combat_polish.gd` | `scripts/vfx/hit_feedback.gd` autoload — **no SFX listener wired yet** |
| [blood-particles](../../specs/blood-particles.md) | 🚧 Partial | — | `scripts/enemies/enemy_base.gd::_spawn_blood_particles` loads `scenes/effects/blood_particles.tscn` (file present at runtime; per-enemy color tinting not verified) |
| [death-explosions](../../specs/death-explosions.md) | 🚧 Partial | — | Death VFX handled inside `enemy_base.gd::die()`; no per-archetype variation |

## Enemies

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [demon-behavior](../../specs/demon-behavior.md) | ✅ Shipped | `test_enemy_base.gd`, `test_new_enemies.gd` | `scripts/enemies/enemy_base.gd` + per-archetype scripts |
| [demon-spawning](../../specs/demon-spawning.md) | ✅ Shipped | `test_world.gd` | `scripts/world/spawn_manager.gd`, autoload `scripts/demon_manager.gd` |
| [demon-assets](../../specs/demon-assets.md) | 🚧 Partial | — | Sprites/scenes exist under `scenes/enemies/`; full sourcing checklist not tracked in code |
| [enemy-variety](../../specs/enemy-variety.md) | ⚠️ Spec drift | `test_new_enemies.gd` | Superseded by `enemy-variety-v2`; v1 archetype list partially diverges from current `scripts/enemies/` set |
| [enemy-variety-v2](../../specs/enemy-variety-v2.md) | ✅ Shipped | `test_new_enemies.gd` | `archer.gd`, `bomber.gd`, `brute.gd`, `charger.gd`, `healer.gd`, `imp_caster.gd`, `skitterer.gd` |
| [elite-enemies](../../specs/elite-enemies.md) | ✅ Shipped | `test_new_enemies.gd` | `scripts/enemies/elite_affixes.gd` |
| [enemy-health-bars](../../specs/enemy-health-bars.md) | ✅ Shipped | — | `scripts/ui/enemy_health_bar.gd` |

## Items & Loot

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [item-drops](../../specs/item-drops.md) | ✅ Shipped | `test_item_factory.gd` | `scripts/items/item_factory.gd`, `scripts/world/item_pickup.gd`, `scripts/world/pickup_base.gd` |
| [item-levels](../../specs/item-levels.md) | ✅ Shipped | `test_item_levels.gd` | `scripts/items/item_factory.gd` (iLvl rolling) |
| [equipment-slots](../../specs/equipment-slots.md) | ✅ Shipped | `test_inventory.gd`, `test_player_stats.gd` | `scripts/items/equipment_manager.gd`, `inventory.gd` |
| [inventory-ui](../../specs/inventory-ui.md) | ✅ Shipped | `test_inventory.gd` | `scripts/ui/inventory_screen.gd` |
| [inventory-screen](../../specs/inventory-screen.md) | ✅ Shipped | `test_inventory.gd` | `scripts/ui/inventory_screen.gd` |
| [set-items](../../specs/set-items.md) | ✅ Shipped | `test_set_items.gd` | `scripts/items/item_set.gd` (uses `load()` self-ref workaround) |
| [gold-economy](../../specs/gold-economy.md) | ✅ Shipped | `test_economy.gd` | `scripts/world/gold_pickup.gd`, player gold counter |

## Progression

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [xp-leveling](../../specs/xp-leveling.md) | ✅ Shipped | `test_progression.gd`, `test_xp_and_crit_stats.gd` | `scripts/items/player_stats.gd`, `scripts/player.gd` (`_grant_xp`) |
| [xp-bar](../../specs/xp-bar.md) | ✅ Shipped | — | `scripts/ui/game_hud.gd` |
| [level-up](../../specs/level-up.md) | ✅ Shipped | `test_progression.gd` | `scripts/ui/level_up_panel.gd` |
| [skill-hotbar](../../specs/skill-hotbar.md) | ✅ Shipped | `test_player_extras.gd` | `scripts/ui/skill_hotbar.gd`, `scripts/items/skill_resource.gd`, `player.gd::equip_skill` |
| [soul-system](../../specs/soul-system.md) | ✅ Shipped | `test_soul_drain.gd` | `scripts/player.gd` (`begin_soul_drain`, `get_soul_drain_rate`) |
| [death-recap](../../specs/death-recap.md) | ✅ Shipped | `test_run_stats.gd` | `scripts/run_stats.gd`, `scripts/ui/game_over_screen.gd` |
| [wave-counter](../../specs/wave-counter.md) | ✅ Shipped | `test_world.gd` | `scripts/world/spawn_manager.gd`, `scripts/ui/game_hud.gd` |

## World

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [scene-layout](../../specs/scene-layout.md) | ✅ Shipped | — | `scenes/main.tscn`, `scripts/main.gd` |
| [biomes](../../specs/biomes.md) | ✅ Shipped | `test_biomes.gd` | `scripts/world/biome_manager.gd`, `biome_def.gd` (uses `load()` self-ref workaround) |
| [procedural-rooms](../../specs/procedural-rooms.md) | ✅ Shipped | `test_world.gd` | `scripts/world/dungeon_generator.gd` |
| [room-transitions](../../specs/room-transitions.md) | ✅ Shipped | — | `scripts/transition_manager.gd` (autoload) |
| [fog-of-war](../../specs/fog-of-war.md) | ✅ Shipped | — | `scripts/world/fog_of_war.gd` |
| [destructibles](../../specs/destructibles.md) | ✅ Shipped | — | `scripts/world/destructible.gd` |
| [camera-follow](../../specs/camera-follow.md) | ✅ Shipped | `test_camera_follow.gd` | `scripts/camera.gd` |
| [soul-wisp-vfx](../../specs/soul-wisp-vfx.md) | 🚧 Partial | — | Pickup wired in `pickup_base.gd`; standalone wisp VFX scene not present |

## UI

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [main-menu](../../specs/main-menu.md) | ✅ Shipped | — | `scripts/ui/main_menu.gd`, `character_select.gd`, `player_count.gd` |
| [health-mana-orbs](../../specs/health-mana-orbs.md) | ✅ Shipped | — | `scripts/ui/health_mana_orbs.gd` |
| [minimap](../../specs/minimap.md) | 🚧 Partial | — | `scripts/ui/minimap.gd` — rendering not unit-tested |
| [tutorial-overlay](../../specs/tutorial-overlay.md) | ✅ Shipped | — | `scripts/ui/tutorial_overlay.gd` |

## Audio

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [ambient-sound](../../specs/ambient-sound.md) | 🚧 Partial | — | `scripts/audio/ambient_audio.gd` switches ambient/combat volume; no SFX bus or per-event sounds wired |

## Multiplayer

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [input-config](../../specs/input-config.md) | ✅ Shipped | `test_input_config.gd`, `test_party_config.gd` | `project.godot` `[input]`, `scripts/party_config.gd` (autoload) |

## Tutorial

| Spec | Status | Tests | Implementation |
|---|---|---|---|
| [tutorial-overlay](../../specs/tutorial-overlay.md) | ✅ Shipped | — | `scripts/ui/tutorial_overlay.gd` (also listed under UI) |

## Spec/code mismatches

- **`enemy-variety` (v1) vs `enemy-variety-v2`** — v1 was superseded but never deleted; new contributors land here first and can be misled. The active archetype list is in v2 + `scripts/enemies/`.
- **`hit-feedback`** — spec calls for SFX on hit; `hit_feedback.gd` only emits `request_sprite_flash`/`request_camera_shake`/`request_damage_number`. No audio listener.
- **`soul-wisp-vfx`** — spec describes a dedicated VFX/scene; only the pickup behavior is implemented.
- **`demon-assets`** — sprite-sheet sourcing checklist isn't tracked in code; assume informal compliance.
- **`death-explosions`** — implemented inside `enemy_base.die()` rather than the per-archetype variations the spec calls for.

## See also

- [Test Index](Test-Index.md) — what's actually exercised.
- [Known Gaps](../07-roadmap/Known-Gaps.md) — what we deliberately skipped.
