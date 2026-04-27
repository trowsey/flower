# Scene Composition

How `scenes/main.tscn` is wired at runtime, and the patterns we use for
spawning everything else.

## `scenes/main.tscn` — what's in the .tscn vs what's added at runtime

The `.tscn` itself is intentionally small. It owns only the *static*
playfield — geometry, lights, camera, the pre-placed Player slot, and the
HUD/pause/game-over CanvasLayers:

```
Main (Node3D, script: scripts/main.gd)
├── WorldEnvironment
├── DirectionalLight3D
├── NavigationRegion3D
│   └── Ground (StaticBody3D + MeshInstance3D + CollisionShape3D)
├── WallNorth / WallSouth / WallEast / WallWest (StaticBody3D)
├── Torches (Node3D, with 7 OmniLight3D children)
├── Player           (instance of scenes/player.tscn — slot 0)
├── Camera3D         (script: scripts/camera.gd)
├── PauseMenu        (instance of scenes/ui/pause_menu.tscn)
├── GameHUD          (instance of scenes/ui/game_hud.tscn)
└── GameOverScreen   (instance of scenes/ui/game_over_screen.tscn)
```

Everything else — additional players, enemies, pickups, shrines, the
inventory screen, the level-up panel, the damage indicator, the tutorial
overlay, run-stats, biome manager — is **added in `main.gd::_ready()`**.

## The runtime tree (typical mid-wave)

```
Main
├── … (static scene contents above)
├── Player              (slot 0 — pre-placed in .tscn, configured by main.gd)
├── Player2             (slot 1+ — instantiated by main.gd if PartyConfig.player_count() > 1)
├── RunStats            (Node — accumulates per-run stats)
├── BiomeManager        (Node — owns current biome Resource)
├── TutorialOverlay     (CanvasLayer)
├── InventoryScreen     (CanvasLayer)
├── LevelUpPanel        (CanvasLayer)
├── DamageIndicator     (CanvasLayer, added via call_deferred)
├── Shrine              (Node3D — every 3 waves)
├── <enemy>             (CharacterBody3D — N per wave)
├── <enemy>
├── …
├── <gold_pickup>       (instance of scenes/items/gold_pickup.tscn)
└── <item_pickup>       (instance of scenes/items/item_pickup.tscn)
```

Plus the four autoloads, which live under `/root/` outside the Main tree:
`/root/DemonManager`, `/root/HitFeedback`, `/root/TransitionManager`,
`/root/PartyConfig`.

## Spawn patterns

### Players
`main.gd` configures the pre-placed `Player` node for slot 0, then for
slot 1+ does:

```gdscript
const PLAYER_SCENE := preload("res://scenes/player.tscn")
var p: Node = PLAYER_SCENE.instantiate()
p.player_index = i
p.device_id = s.get("device_id", i)
p.character_class_id = s.get("character_class_id", ...)
add_child(p)
p.global_position = SPAWN_OFFSETS[i % SPAWN_OFFSETS.size()]
```

> Slot 0 keeps the .tscn-placed instance for backward compatibility — many
> existing nodes/UI fetch `$Player` by path. Don't remove it.

### Enemies — `load()` not `preload()`

`main.gd` lists scene **paths** (strings), not preloaded `PackedScene`s:

```gdscript
const ENEMY_SCENES := [
    "res://scenes/enemies/skitterer.tscn",
    "res://scenes/enemies/brute.tscn",
]
…
var scene := load(scene_path)   # runtime load, NOT preload
var enemy: Node3D = scene.instantiate()
```

**Why `load()` here:** preloading enemy scenes at the top of `main.gd`
would pull every enemy script (and every Resource they reference) into the
load graph for the main scene. With biome pools and dynamically-discovered
enemies, that risks circular references between `main.gd`, the enemy
scripts, and `EnemyBase`. Lazy `load()` keeps the import graph flat.

### Pickups
`item_pickup.tscn` and `gold_pickup.tscn` are spawned by enemies (in
`enemy_base.gd::_drop_loot`) the same way — `load()` then `instantiate()`,
then `add_child` onto whichever ancestor owns the world. The pickup adds
itself, sets `global_position`, and emits `collected(player)` when grabbed.

### CanvasLayer overlays
`InventoryScreen`, `LevelUpPanel`, `TutorialOverlay`, `DamageIndicator`
all extend `CanvasLayer` and **build their child UI procedurally in
`_build()`** — no .tscn. This is the procedural-UI pattern from
`principles.md`: fewer .tscn files to maintain, layout lives next to logic.

## Why this layout

- **The .tscn is editable by anyone.** Static geometry, lights, the player
  slot, and HUD layers — exactly what a level designer would touch.
- **`main.gd` is the orchestrator.** Anything that depends on
  `PartyConfig`, biome data, or run state is added at runtime so the .tscn
  doesn't need to know about those systems.
- **No circular preloads.** Cross-system glue uses `load()` strings or
  signal connections instead of preloaded references.

## Related

- [Autoloads](Autoloads.md) — the four `/root/*` singletons.
- [Signals Catalog](Signals-Catalog.md) — `Main.wave_started` etc.
- [Resource Patterns](Resource-Patterns.md) — why `BiomeManager` owns a `Biome` Resource, not a node.
