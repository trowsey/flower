# Demon Spawn System Spec

## Overview

Demons enter the game through two methods: pre-placed (positioned in the scene editor, always in the same spot) and dynamically spawned (emerging from the ground near the player or at designated spawn points). Both methods feed into the same demon behavior system once the demon is active.

## Requirements

1. **Pre-placed demons** are positioned manually in the Godot scene editor — they exist in the scene tree from the start
2. **Dynamic spawns** use designated `SpawnPoint` marker nodes placed in the scene editor
3. Dynamic spawns are triggered by player proximity, wave timers, or scripted events
4. Demons emerging from the ground play an "emerge" animation and are **invulnerable during emergence**
5. Maximum demon count per area is enforced — no more than `max_demons` alive at once
6. Spawn cooldown prevents rapid-fire spawning
7. Wave management: spawn X demons, wait for Y to die, spawn next batch
8. Spawn system is scene-local (each room/area manages its own spawns)

## Pre-Placed Demons

### Editor Workflow

Pre-placed demons are simply instances of demon `.tscn` scenes dragged into the level scene in the Godot editor.

1. Open `main.tscn` (or any level scene) in the editor
2. Drag `scenes/enemies/demon_pure_drainer.tscn` into the scene tree
3. Position using the 3D gizmos
4. Set any exported property overrides (e.g., patrol path)
5. The demon starts in `IDLE` state and activates when the player enters detection range

Pre-placed demons start with `DemonState.IDLE` (or `PATROL` if a patrol path is assigned).

### Optional Patrol Paths

Pre-placed demons can have an optional `Path3D` sibling for patrol behavior:

```gdscript
# In demon_base.gd
@export var patrol_path: Path3D = null
@export var patrol_speed := 2.0
var _patrol_index := 0

func _process_patrol(delta: float) -> void:
    if not patrol_path or patrol_path.curve.point_count == 0:
        _transition(DemonState.IDLE)
        return
    var target := patrol_path.curve.get_point_position(_patrol_index)
    target = patrol_path.global_transform * target
    # ... navigate to target, advance index on arrival ...
```

## Dynamic Spawning

### SpawnPoint Node

A lightweight marker node placed in the level editor:

```gdscript
# scripts/spawn_point.gd
extends Marker3D
class_name SpawnPoint

@export var demon_scene: PackedScene           # which demon to spawn
@export var max_spawns := 3                     # how many this point can spawn total (0 = unlimited)
@export var spawn_cooldown := 5.0               # seconds between spawns from this point
@export var player_trigger_range := 12.0        # player must be within this range to activate
@export var emerge_from_ground := true          # play emerge animation?

var _spawns_remaining: int
var _cooldown_timer := 0.0
var _active := true

func _ready() -> void:
    _spawns_remaining = max_spawns if max_spawns > 0 else -1
```

### SpawnManager

Each level has a `SpawnManager` node that coordinates all spawn points in that scene:

```gdscript
# scripts/spawn_manager.gd
extends Node
class_name SpawnManager

@export var max_demons_alive := 8               # hard cap for this area
@export var wave_size := 3                       # demons per wave
@export var wave_delay := 10.0                   # seconds between waves
@export var require_kills_for_next_wave := true  # wait for wave to die before next

var _alive_demons: Array[Node3D] = []
var _wave_timer := 0.0
var _wave_active := false
var _player: CharacterBody3D = null

func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    # Clean up dead references
    _alive_demons = _alive_demons.filter(func(d): return is_instance_valid(d))

    if _alive_demons.size() >= max_demons_alive:
        return  # at cap

    _wave_timer -= delta
    if _wave_timer > 0.0:
        return

    if require_kills_for_next_wave and _wave_active and _alive_demons.size() > 0:
        return  # previous wave still alive

    _spawn_wave()

func _spawn_wave() -> void:
    var points := _get_eligible_spawn_points()
    var spawned := 0
    for point in points:
        if spawned >= wave_size:
            break
        if _alive_demons.size() >= max_demons_alive:
            break
        var demon := _spawn_at_point(point)
        if demon:
            _alive_demons.append(demon)
            spawned += 1
    _wave_active = true
    _wave_timer = wave_delay

func _get_eligible_spawn_points() -> Array[SpawnPoint]:
    var points: Array[SpawnPoint] = []
    for child in get_children():
        if child is SpawnPoint and child._active:
            if not _player:
                continue
            var dist := child.global_position.distance_to(_player.global_position)
            if dist <= child.player_trigger_range and child._cooldown_timer <= 0.0:
                points.append(child)
    points.shuffle()  # randomize which points activate
    return points

func _spawn_at_point(point: SpawnPoint) -> Node3D:
    if not point.demon_scene:
        return null
    var demon: CharacterBody3D = point.demon_scene.instantiate()
    get_tree().current_scene.add_child(demon)
    demon.global_position = point.global_position
    if point.emerge_from_ground:
        demon.start_emerge()  # sets DemonState.EMERGING
    else:
        demon.global_position.y = 0.0  # place on ground level
    point._cooldown_timer = point.spawn_cooldown
    if point._spawns_remaining > 0:
        point._spawns_remaining -= 1
        if point._spawns_remaining == 0:
            point._active = false
    return demon
```

## Emerge-From-Ground Animation

When `emerge_from_ground` is true, the demon spawns below the floor and rises up:

```gdscript
# In demon_base.gd
func start_emerge() -> void:
    _transition(DemonState.EMERGING)
    # Start below ground
    var target_y := global_position.y
    global_position.y = target_y - 2.0
    sprite.play("emerge")
    set_collision_layer(0)  # invulnerable: not on enemy layer during emerge

    # Tween upward over the emerge animation duration
    var tween := create_tween()
    tween.tween_property(self, "global_position:y", target_y, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_callback(_finish_emerge)

func _finish_emerge() -> void:
    set_collision_layer(4)  # back on enemy layer — can be hit
    _transition(DemonState.IDLE)
    sprite.play("idle")
```

### Emerge Visual Details
- Duration: ~1.2 seconds
- Demon starts 2 units below ground, tweens up with `EASE_OUT` / `TRANS_CUBIC`
- During emerge: collision layer = 0 (cannot be targeted/hit)
- Sprite plays "emerge" animation (claws reaching up, pulling body out of ground)
- Optional: particle effect at ground level (dust/debris) — see Open Questions

### Timing
| Phase | Duration |
|-------|----------|
| Emerge tween | 1.2s |
| Post-emerge idle (before chase) | 0.5s |
| Total invulnerability window | 1.7s |

## Level Scene Setup

```
Main (Node3D)
  ├── NavigationRegion3D
  │   └── Ground (StaticBody3D)
  ├── Walls...
  ├── Player
  ├── Camera3D
  ├── PrePlacedDemons (Node3D)  # organizational container
  │   ├── DemonPureDrainer (instance)   # pre-placed
  │   └── DemonFighterDrainer (instance) # pre-placed
  └── SpawnManager (SpawnManager)
      ├── SpawnPoint1 (SpawnPoint) [demon_scene=pure_drainer.tscn]
      ├── SpawnPoint2 (SpawnPoint) [demon_scene=fighter_drainer.tscn]
      └── SpawnPoint3 (SpawnPoint) [demon_scene=pure_drainer.tscn]
```

## File Structure

```
scripts/
  spawn_point.gd       # New — SpawnPoint marker node
  spawn_manager.gd     # New — wave/area spawn coordinator
  demon_base.gd        # Modified — add start_emerge(), EMERGING state
scenes/
  main.tscn            # Modified — add SpawnManager + SpawnPoints
```

## Open Questions

1. **Emerge particles**: Add a dust/debris GPUParticles3D at spawn point during emerge? (Recommend yes — Spec-writer task)
2. **Spawn point visibility in editor**: Custom icon for SpawnPoint in the editor? Godot supports `@icon` annotation
3. **Scripted spawns**: Do we need an API for cutscene/event-triggered spawns (e.g., boss enters when player opens a door)? If so, `SpawnManager.force_spawn(scene, position)` method
4. **Spawn point depletion**: When a spawn point runs out of spawns, should it visually change (e.g., hole seals up)?
5. **Off-screen spawning**: Should we prevent spawns that would be visible to the player's camera? Or is the emerge animation sufficient to make it look intentional?

## Dependencies

- **Depends on**: `demon-behavior.md` (demon scenes and DemonState.EMERGING), existing `NavigationRegion3D` in main.tscn
- **Depended on by**: level design workflow (designers place spawn points)
