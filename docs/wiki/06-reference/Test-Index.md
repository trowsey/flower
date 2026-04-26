# Test Index

> Audience: agents picking a system to modify and wanting to know what
> already covers it. Counts derived from `grep -c "^func test_" tests/unit/*.gd`
> at commit `3fea189`.

**Total: 190 unit tests across 24 files + 10 E2E (autobot) checks.** All green.

| Test file | What it covers | # of tests | System link |
|---|---|---:|---|
| [`test_biomes.gd`](../../../tests/unit/test_biomes.gd) | `BiomeDef`/`BiomeManager` data, biome rotation, palette loading | 4 | [Biomes](../03-systems/Biomes.md) |
| [`test_camera_follow.gd`](../../../tests/unit/test_camera_follow.gd) | Smooth-follow lerp, deadzone, zoom clamps, multi-target framing | 11 | [Camera](../03-systems/Camera.md) |
| [`test_character_class.gd`](../../../tests/unit/test_character_class.gd) | All 4 classes (Sarah/etc.), base stats, signature skill build | 9 | [Character Classes](../03-systems/Character-Classes.md) |
| [`test_economy.gd`](../../../tests/unit/test_economy.gd) | Gold pickup stacking, currency totals, drop multipliers | 7 | [Loot & Economy](../03-systems/Loot-And-Economy.md) |
| [`test_enemy_base.gd`](../../../tests/unit/test_enemy_base.gd) | Enemy take_damage, knockback, death drops, signal emit | 6 | [Enemies](../03-systems/Enemies.md) |
| [`test_input_config.gd`](../../../tests/unit/test_input_config.gd) | Every action defined, KB+M and joypad bindings, deadzones | 21 | [Input](../03-systems/Input.md) |
| [`test_inventory.gd`](../../../tests/unit/test_inventory.gd) | Inventory grid, equipment slots, stat (un)application, swap | 6 | [Inventory & Equipment](../03-systems/Inventory-And-Equipment.md) |
| [`test_item_factory.gd`](../../../tests/unit/test_item_factory.gd) | Rarity rolls, affix application, weighted drop tables | 6 | [Loot & Economy](../03-systems/Loot-And-Economy.md) |
| [`test_item_levels.gd`](../../../tests/unit/test_item_levels.gd) | iLvl scaling, mod ranges per tier | 3 | [Loot & Economy](../03-systems/Loot-And-Economy.md) |
| [`test_new_enemies.gd`](../../../tests/unit/test_new_enemies.gd) | Archer/bomber/brute/charger/healer/imp/skitterer behaviors + elite affixes | 6 | [Enemies](../03-systems/Enemies.md) |
| [`test_party_config.gd`](../../../tests/unit/test_party_config.gd) | Solo/co-op slot setup, device id assignment | 4 | [Couch Co-op](../03-systems/Couch-Coop.md) |
| [`test_player_attack.gd`](../../../tests/unit/test_player_attack.gd) | Attack windup, damage calc, range, combo advancement, crit | 13 | [Combat](../03-systems/Combat.md) |
| [`test_player_combat_polish.gd`](../../../tests/unit/test_player_combat_polish.gd) | Hit-stop, sprite-flash request, screen shake routing | 7 | [Combat](../03-systems/Combat.md) |
| [`test_player_extras.gd`](../../../tests/unit/test_player_extras.gd) | Skill hotbar equip/cast, signature skill, cooldowns, costs | 10 | [Skills](../03-systems/Skills.md) |
| [`test_player_movement.gd`](../../../tests/unit/test_player_movement.gd) | WASD + stick, click-to-move, dodge iframes, animation flips | 15 | [Player Movement](../03-systems/Player-Movement.md) |
| [`test_player_stats.gd`](../../../tests/unit/test_player_stats.gd) | Base + modifier dict, derived getters, defense formula | 7 | [Player Stats](../03-systems/Player-Stats.md) |
| [`test_progression.gd`](../../../tests/unit/test_progression.gd) | XP curve, level-up panel choices, peak-level tracking | 8 | [Progression](../03-systems/Progression.md) |
| [`test_run_stats.gd`](../../../tests/unit/test_run_stats.gd) | RunStats counters, time tracking, end-of-run snapshot | 6 | [Run Stats](../03-systems/Run-Stats.md) |
| [`test_set_items.gd`](../../../tests/unit/test_set_items.gd) | Set bonus thresholds (2/4 piece), bonus stacking | 5 | [Loot & Economy](../03-systems/Loot-And-Economy.md) |
| [`test_settings.gd`](../../../tests/unit/test_settings.gd) | Settings load/save, volume clamps, fullscreen toggle, defaults | 12 | [Settings](../03-systems/Settings.md) |
| [`test_shrine.gd`](../../../tests/unit/test_shrine.gd) | Shrine activation, single-use, temp buff application | 2 | [World](../03-systems/World.md) |
| [`test_soul_drain.gd`](../../../tests/unit/test_soul_drain.gd) | Soul drain begin/end, drain rate vs resist, soul refund | 7 | [Soul System](../03-systems/Soul-System.md) |
| [`test_world.gd`](../../../tests/unit/test_world.gd) | Spawn waves, wave counter, dungeon generator, biome rotation | 10 | [World](../03-systems/World.md) |
| [`test_xp_and_crit_stats.gd`](../../../tests/unit/test_xp_and_crit_stats.gd) | XP gain modifiers, crit chance/damage stat math | 5 | [Player Stats](../03-systems/Player-Stats.md) |

## Running tests

```bash
# Unit suite (GUT) — current baseline: 190/190 passing
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# E2E autobot — current baseline: 10/10 passing
godot --headless --path . --script res://scripts/e2e/autobot_runner.gd
```

See also [Running Tests](../02-getting-started/Running-Tests.md).

## Known coverage gaps

These are **intentionally untested** or hard to test in headless GUT.
Don't add bogus tests just to fill the table — file an issue if real coverage is needed.

- **`SkillResource`** — pure data container; values are exercised via `test_player_extras.gd` indirectly. No standalone test.
- **`TransitionManager` autoload** — scene-tree side effects are awkward in unit tests; covered loosely by E2E autobot.
- **`DemonManager` autoload** — global enemy registry; touched indirectly by spawn tests.
- **`damage_indicator` / `damage_number`** — visual VFX; no assertion harness for floating numbers.
- **Minimap rendering** — `scripts/ui/minimap.gd` is data-driven but the draw step has no test.
- **`hit_feedback.gd` SFX path** — no listener exists yet, so nothing to assert.
- **`ambient_audio.gd`** — only swaps `volume_db`; trivial, no test.
- **Destructibles, fog of war, shrine activation visuals** — logic touched by `test_shrine.gd` / `test_world.gd`; visual layer untested.
- **`autobot.gd` itself** — it *is* the test for the playable scene; meta-testing it is out of scope.

## See also

- [Spec Index](Spec-Index.md) — feature-by-feature ship status.
- [Writing Tests](../05-contributing/Writing-Tests.md) — GUT conventions.
