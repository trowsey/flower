# Repo Layout

Directory tour. One line per folder or significant file. Read this once, then keep it open as a reference while navigating.

## Top level

```
flower/
├── project.godot       # Engine config: autoloads, input map, viewport size
├── default_bus_layout.tres   # Audio buses (Master / Music / SFX)
├── design.md           # Character lore + class archetype mapping
├── README.md           # Squads CLI marketing blurb (not a code intro)
├── AGENTS.md, CLAUDE.md   # Per-tool agent operating instructions
├── scenes/             # All .tscn files
├── scripts/            # All GDScript code
├── addons/gut/         # Vendored GUT testing framework (patched for 4.6)
├── assets/             # Sprite sheets, textures
├── docs/               # architecture, principles, specs, this wiki
├── tests/              # GUT test suite (28 files; ~190 tests)
└── .agents/            # AI workforce squad definitions + memory
```

## `scenes/` — Godot scene files

```
scenes/
├── main.tscn           # The gameplay scene. Wave loop, biome tinting, all UI overlays.
├── player.tscn         # Player template — instanced once per slot by main.gd.
├── enemies/            # One .tscn per enemy type (skitterer/brute/archer/bomber/charger/healer)
├── items/              # gold_pickup.tscn, item_pickup.tscn (visual + Area3D)
└── ui/                 # main_menu, player_count, character_select, game_hud,
                        # game_over_screen, pause_menu, settings_menu, credits
```

Note: many UI panels (inventory, level-up, tutorial, damage-indicator) are built **procedurally** in `_ready()` and have no `.tscn` — see the procedural-UI pattern in [`docs/principles.md`](../../principles.md).

## `scripts/` — all .gd code

### Top-level (game-wide systems)

```
scripts/main.gd           # Game loop: wave/boss/shrine spawn, biome rotate, run-stats wiring.
scripts/player.gd         # The biggest file (~913 lines). Combat hub: movement,
                          # combo, soul-drain, stats, equipment, inventory, skills,
                          # multiplayer input filtering, dash, revive, magnet.
scripts/camera.gd         # Orthographic follow camera, smoothed.
scripts/demon_manager.gd  # Autoload — global one-at-a-time soul-latch lock.
scripts/transition_manager.gd  # Autoload — fade-to-room / fade-to-floor scene transitions.
scripts/party_config.gd   # Autoload — per-slot {character_class_id, device_id}.
scripts/run_stats.gd      # Per-run kill / gold / time / damage tracker (Node, instanced in main).
scripts/settings.gd       # Static module — load/save user://settings.cfg + apply audio buses.
```

The 4 autoloads — `DemonManager`, `HitFeedback`, `TransitionManager`, `PartyConfig` — are the entire global-state surface. Adding a 5th requires an ADR (see ADR-005 in [`docs/architecture.md`](../../architecture.md)).

### `scripts/items/` — pure data Resources (no scene tree)

```
character_class.gd     # Sarah/Maddie/Chan Xaic/Aiyana — base stats + signature skill.
player_stats.gd        # Derived stats, XP curve, stat-point allocation, modifier dict.
item_resource.gd       # Item type + rarity enums, sell value, rarity color/name.
item_factory.gd        # Random item + set-piece generation, prefix/suffix tables.
item_set.gd            # 3 named sets + 2/4/5-piece bonus thresholds.
inventory.gd           # 30-slot grid + add/remove signals.
equipment_manager.gd   # 5-slot equip + total modifier rollup (incl. set bonuses).
skill_resource.gd      # Skill name, cost, cooldown, execute_method dispatch string.
```

Resources never touch the scene tree — that's how they stay unit-testable.

### `scripts/enemies/` — `EnemyBase` + 7 subclasses + elite affixes

```
enemy_base.gd          # HP, knockback, hit-flash, drops (gold + item), death VFX hook.
demon_base.gd          # Specialization w/ soul-drain latching FSM.
skitterer.gd, brute.gd, charger.gd, archer.gd, bomber.gd, healer.gd, imp_caster.gd
elite_affixes.gd       # `EliteAffixes.make_elite(enemy, n)` — picks from
                       # [fast, tough, explosive, venomous, armored].
```

### `scripts/world/` — pickups, generation, props

```
pickup_base.gd         # Hover-bob Area3D base for gold + items.
gold_pickup.gd, item_pickup.gd  # Subclasses, item rarity tints + beam VFX.
destructible.gd        # Breakable barrels/urns; drop gold + items.
shrine.gd              # 4 buff types, 20s temp buff to first player to enter.
biome_def.gd           # Resource: floor/wall/ambient color + enemy_scenes pool.
biome_manager.gd       # Rotates biome every WAVES_PER_BIOME=5 cleared waves.
fog_of_war.gd          # Grid-based explored-tile dictionary; minimap reads it.
dungeon_generator.gd   # 3×3 procedural room layout (specced, not yet wired into main).
spawn_manager.gd       # Per-room spawn helper with elite chance.
```

### `scripts/ui/` — Control nodes / CanvasLayers

```
main_menu.gd, player_count.gd, character_select.gd, credits.gd, settings_menu.gd, pause_menu.gd
game_hud.gd            # Per-player HP/Soul/XP/skills panel; iterates "player" group.
health_mana_orbs.gd, skill_hotbar.gd, enemy_health_bar.gd, minimap.gd
inventory_screen.gd    # Procedural Diablo-style inventory (5 equip + 30-grid).
level_up_panel.gd      # Toast + stat allocation panel (C key).
tutorial_overlay.gd    # First-run controls overlay; persists "seen" via Settings.
game_over_screen.gd    # Death recap; reads RunStats.summary().
damage_indicator.gd    # NEW: red vignette flash on player damage.
```

### `scripts/vfx/` — visual feedback helpers

```
hit_feedback.gd        # Autoload. Single signal hub for shake/hit-stop/numbers/flash.
camera_shake.gd        # Pure RefCounted helper used by camera.gd.
damage_number.gd       # Floating Label3D, 0.8s rise + fade.
```

### `scripts/audio/`

```
ambient_audio.gd       # Crossfades ambient ↔ combat tracks based on enemy proximity.
```

### `scripts/e2e/` — autobot harness

```
autobot.gd             # 10 checkpoints, drives real Input + scene state, screenshots.
autobot_runner.gd      # SceneTree entry: load main.tscn + autobot, exit code 0/1.
```

## `addons/gut/`

The Godot Unit Test framework, vendored. Patched once: `Logger` → `GutLogger` in `addons/gut/utils.gd` for Godot 4.6 compatibility. Don't replace this tree without re-applying the patch.

## `docs/`

```
docs/
├── architecture.md      # The constitution — read before any structural change.
├── principles.md        # Daily-driver coding rules. Read first.
├── specs/               # 41 feature specs. Tests + impl derive from these.
├── wiki/                # This wiki. Pages organized by audience role.
└── demon-hunter-map-making-guide.md   # Reference doc for the level designer role.
```

## `tests/`

```
tests/
├── base_test.gd         # Common test base / helpers.
├── .gut_config.tres     # GUT runner defaults.
└── unit/
    └── test_<feature>.gd × 25   # GUT test suites (~191 test funcs total).
```

Tests mirror script paths: `test_player_movement.gd` ↔ `scripts/player.gd` movement code; `test_set_items.gd` ↔ `scripts/items/item_set.gd` and the equipment math in `equipment_manager.gd`.

## `assets/`

Placeholder sprite sheets and textures. No artist on the project yet — most enemies + props are CSG/MeshInstance primitives in code.

## `.agents/squads/engineering/`

The TDD pipeline definitions, mapped to Castlevania character names (ADR-003):

```
SQUAD.md       # Squad mission, output format
spec-writer.md       # Spec author
architect.md       # Architect / spec reviewer
test-writer.md      # Test author
test-reviewer.md     # Test reviewer
implementer.md      # Implementer
code-reviewer.md      # Code reviewer
test-runner.md       # Test runner
lead.md     # Lead / orchestrator
```

When you (an agent) start a new feature, the entry point is Spec-writer (write a spec under `docs/specs/`), then run the squad downstream. Existing specs are the contract — agents trust them over freelance interpretation (ADR-002).
