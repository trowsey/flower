# Demon AI & Behavior Spec

## Overview

Demons are the core enemy type in Flower. Each demon runs a state machine that governs approach, combat, soul-latching, and death. Three variants ship in the first pass: Pure Drainer, Fighter Drainer, and Boss/Elite Demon.

## Requirements

1. All demons extend `CharacterBody3D`, use `NavigationAgent3D` for pathfinding, and `AnimatedSprite3D` for visuals
2. All demons are in the `"enemies"` group (player's attack already checks this)
3. Demons must be on **collision layer 4** so the player's `AttackArea` (mask 4) detects them
4. Each demon type has its own state machine with shared base states
5. Only ONE demon may latch onto the player at a time — a global latch lock enforces this
6. Demons must call `player.begin_soul_drain(self)` to initiate a latch — if it returns `false`, they cannot latch
7. Latched demons take damage from the player's existing attack system (`take_damage` method)
8. When a latched demon dies, the latch is broken and a soul wisp is released
9. Demons face the player using `sprite.flip_h` (matching player convention)
10. All demons navigate via `NavigationAgent3D` on the existing `NavigationRegion3D`

## Shared Base: `demon_base.gd`

### Stats (exported for per-type tuning)

```gdscript
@export var max_health := 50.0
@export var move_speed := 3.5
@export var detection_range := 15.0
@export var latch_range := 1.5
@export var attack_range := 2.0
@export var attack_damage := 10.0
@export var attack_cooldown := 1.5
@export var latch_damage_threshold := 30.0  # damage needed to break latch
@export var can_latch := true
@export var can_melee := false
```

### Base State Machine

```
enum DemonState {
    IDLE,
    PATROL,
    CHASE,
    LATCH_APPROACH,
    LATCHING,       # playing latch animation, not yet draining
    DRAINING,       # latched and actively draining soul
    ATTACK,         # melee attack (fighter drainer only)
    STAGGERED,      # brief stun after taking damage
    DYING,          # death animation playing
    DEAD,           # cleanup / queue_free
    EMERGING,       # spawning from ground (see demon-spawning.md)
}
```

### State Transitions (shared)

```
IDLE → CHASE                (player enters detection_range)
PATROL → CHASE              (player enters detection_range)
CHASE → LATCH_APPROACH      (can_latch AND latch is available AND no other demon latched)
CHASE → ATTACK              (can_melee AND in attack_range AND latch not available)
LATCH_APPROACH → LATCHING   (within latch_range of player)
LATCHING → DRAINING         (latch animation complete, player.begin_soul_drain returns true)
LATCHING → CHASE            (player.begin_soul_drain returns false — someone else latched first)
DRAINING → DYING            (health <= 0)
DRAINING → STAGGERED        (took enough cumulative damage to break latch, but not dead)
STAGGERED → CHASE           (stagger timer expires)
ATTACK → CHASE              (attack animation complete)
ANY → DYING                 (health <= 0)
DYING → DEAD                (death animation complete)
```

### Core Methods

```gdscript
var health: float
var _state: DemonState = DemonState.IDLE
var _latch_damage_taken := 0.0  # cumulative damage since latch started
var _player: CharacterBody3D = null

func _ready() -> void:
    health = max_health
    add_to_group("enemies")
    _player = get_tree().get_first_node_in_group("player")
    nav_agent.path_desired_distance = 0.5
    nav_agent.target_desired_distance = 0.5

func take_damage(amount: float) -> void:
    health -= amount
    if _state == DemonState.DRAINING:
        _latch_damage_taken += amount
        if _latch_damage_taken >= latch_damage_threshold:
            _break_latch()
    if health <= 0.0:
        _die()

func _break_latch() -> void:
    _latch_damage_taken = 0.0
    if _player and _player.has_method("end_soul_drain"):
        _player.end_soul_drain()
    _transition(DemonState.STAGGERED)

func _die() -> void:
    if _state == DemonState.DRAINING:
        _player.end_soul_drain()
        _release_soul_wisp()
    _transition(DemonState.DYING)
    sprite.play("death")
    await sprite.animation_finished
    _transition(DemonState.DEAD)
    queue_free()
```

### Navigation

```gdscript
func _chase_player(delta: float) -> void:
    if not _player:
        return
    nav_agent.target_position = _player.global_position
    if nav_agent.is_navigation_finished():
        return
    var next := nav_agent.get_next_path_position()
    var dir := (next - global_position).normalized()
    dir.y = 0
    velocity = dir * move_speed
    sprite.flip_h = dir.x < 0
    move_and_slide()
```

## Latch Lock System

A singleton `DemonManager` (autoload) coordinates the one-at-a-time latch rule:

```gdscript
# scripts/demon_manager.gd — registered as autoload "DemonManager"
extends Node

var _latched_demon: Node3D = null

func request_latch(demon: Node3D) -> bool:
    if _latched_demon != null:
        return false
    _latched_demon = demon
    return true

func release_latch(demon: Node3D) -> void:
    if _latched_demon == demon:
        _latched_demon = null

func is_latch_available() -> bool:
    return _latched_demon == null

func get_latched_demon() -> Node3D:
    return _latched_demon
```

A demon must call `DemonManager.request_latch(self)` before transitioning to LATCHING. If it returns `false`, the demon falls back to CHASE or ATTACK.

## Demon Type 1: Pure Drainer

**Identity**: The pressure enemy. Approaches and latches. Cannot deal health damage while draining. Lower HP makes it easy to kill quickly if the player reacts.

### Stats
| Stat | Value |
|------|-------|
| max_health | 40 |
| move_speed | 4.0 |
| detection_range | 15.0 |
| latch_range | 1.5 |
| latch_damage_threshold | 20 |
| can_latch | true |
| can_melee | false |
| attack_damage | 0 (does not deal health damage) |

### Behavior
- IDLE → detects player → CHASE
- CHASE → approaches player, checks `DemonManager.is_latch_available()`
  - If latch available → LATCH_APPROACH (moves to latch_range)
  - If latch NOT available → continues CHASE (circles player at detection_range edge)
- LATCH_APPROACH → reaches latch_range → LATCHING
- LATCHING → plays grab animation → calls `DemonManager.request_latch(self)` and `player.begin_soul_drain(self)` → DRAINING
- DRAINING → drains soul (player handles timer), takes damage from player attacks
  - If `latch_damage_threshold` exceeded → latch breaks → STAGGERED
  - If killed → releases wisp → DYING
- Does NOT deal health damage at any point

### Unique: Circling Behavior
When another demon is latched and this Pure Drainer cannot latch, it should orbit the player at ~3–4 units distance, waiting for latch to become available. This creates visual pressure.

## Demon Type 2: Fighter Drainer

**Identity**: The dual threat. Fights with melee AND can latch to drain soul. More dangerous, higher HP.

### Stats
| Stat | Value |
|------|-------|
| max_health | 80 |
| move_speed | 3.5 |
| detection_range | 15.0 |
| latch_range | 1.5 |
| attack_range | 2.5 |
| attack_damage | 15 |
| attack_cooldown | 2.0 |
| latch_damage_threshold | 40 |
| can_latch | true |
| can_melee | true |

### Behavior
- IDLE → detects player → CHASE
- CHASE → reaches attack_range:
  - If latch available AND random chance (30% per decision tick) → LATCH_APPROACH
  - Otherwise → ATTACK (melee)
- ATTACK → plays attack animation → deals `attack_damage` to player health → CHASE
- LATCH_APPROACH → LATCHING → DRAINING (same as Pure Drainer)
- While DRAINING: does NOT deal health damage (latching is exclusive)
- Decision tick: every 1.0 seconds while in CHASE, re-evaluate latch vs. melee

### Melee Attack Implementation

```gdscript
func _perform_attack() -> void:
    _transition(DemonState.ATTACK)
    sprite.play("attack")
    await get_tree().create_timer(0.2).timeout  # hit frame
    if global_position.distance_to(_player.global_position) <= attack_range:
        if _player.has_method("take_damage"):
            _player.take_damage(attack_damage)
    await sprite.animation_finished
    _attack_timer = attack_cooldown
    _transition(DemonState.CHASE)
```

## Demon Type 3: Boss/Elite Demon

**Identity**: A tougher fighter drainer with special abilities. Appears at key dungeon moments.

### Stats
| Stat | Value |
|------|-------|
| max_health | 200 |
| move_speed | 3.0 |
| detection_range | 20.0 |
| latch_range | 2.0 |
| attack_range | 3.0 |
| attack_damage | 25 |
| attack_cooldown | 1.5 |
| latch_damage_threshold | 80 |
| can_latch | true |
| can_melee | true |
| soul_drain_multiplier | 1.5 (drains 50% faster) |

### Special Abilities
1. **Faster soul drain**: Modifies the drain rate by `soul_drain_multiplier` (communicated to player via signal or method arg)
2. **Ground slam**: AoE attack, deals damage in a radius, has a 5-second cooldown
3. **Enrage phase**: Below 30% HP, move_speed increases by 50%, attack_cooldown reduced by 0.5s

### Boss Behavior Extensions
```
CHASE → GROUND_SLAM         (cooldown ready AND player in slam_range 4.0)
GROUND_SLAM → CHASE         (slam animation complete)
ANY → ENRAGED               (health drops below 30% — one-time transition, stat buff applied)
```

Ground slam implementation:
```gdscript
@export var slam_damage := 30.0
@export var slam_radius := 5.0
@export var slam_cooldown := 5.0
var _slam_timer := 0.0

func _ground_slam() -> void:
    sprite.play("slam")
    await get_tree().create_timer(0.5).timeout  # wind-up
    # Damage all players in radius
    if global_position.distance_to(_player.global_position) <= slam_radius:
        _player.take_damage(slam_damage)
    _slam_timer = slam_cooldown
```

## Physics Process Structure

```gdscript
func _physics_process(delta: float) -> void:
    match _state:
        DemonState.IDLE:
            _process_idle(delta)
        DemonState.PATROL:
            _process_patrol(delta)
        DemonState.CHASE:
            _chase_player(delta)
            _evaluate_combat(delta)
        DemonState.LATCH_APPROACH:
            _approach_for_latch(delta)
        DemonState.LATCHING:
            pass  # animation playing
        DemonState.DRAINING:
            _process_drain(delta)
        DemonState.ATTACK:
            pass  # attack coroutine handles this
        DemonState.STAGGERED:
            _process_stagger(delta)
        DemonState.DYING, DemonState.DEAD:
            pass
        DemonState.EMERGING:
            pass  # handled by spawn system
```

## File Structure

```
scripts/
  demon_base.gd           # New — shared demon logic, state machine, stats
  demon_pure_drainer.gd    # New — extends demon_base, pure drainer behavior
  demon_fighter_drainer.gd # New — extends demon_base, fighter drainer behavior
  demon_boss.gd            # New — extends demon_base, boss behavior
  demon_manager.gd         # New — autoload singleton for latch coordination
scenes/
  enemies/
    demon_pure_drainer.tscn   # CharacterBody3D + AnimatedSprite3D + NavigationAgent3D + CollisionShape3D
    demon_fighter_drainer.tscn
    demon_boss.tscn
```

### Scene Node Structure (each demon .tscn)

```
DemonPureDrainer (CharacterBody3D) [collision_layer=4, collision_mask=1]
  ├── Sprite (AnimatedSprite3D) [billboard=1, pixel_size=0.015]
  ├── CollisionShape3D (CapsuleShape3D)
  ├── NavigationAgent3D
  ├── DetectionArea (Area3D) [monitors layer 2 — player]
  │   └── DetectionShape (CollisionShape3D, SphereShape3D radius=detection_range)
  └── LatchArea (Area3D) [monitors layer 2 — player]
      └── LatchShape (CollisionShape3D, SphereShape3D radius=latch_range)
```

**Collision layers used:**
- Layer 1: World/ground (player mask, demon mask)
- Layer 2: Player (demon detection mask)
- Layer 4: Enemies (player attack mask)

## Open Questions

1. **Stagger duration**: How long should the demon be stunned after latch breaks? (Suggest: 1.0s)
2. **Circling behavior**: Should waiting Pure Drainers actively orbit, or just stand at a distance? Orbiting looks cooler but is more complex.
3. **Boss arena**: Should the boss have a trigger zone / locked room, or just be a pre-placed tough enemy?
4. **Demon-to-demon collision**: Should demons collide with each other or pass through? (Suggest: pass through — avoids navigation jams)
5. **Aggro reset**: If the player runs far enough away, do demons reset to IDLE? What range? (Suggest: 25 units)
6. **Latch damage threshold**: Is this cumulative (damage since latch started) or per-hit? (Spec assumes cumulative)

## Dependencies

- **Depends on**: `soul-system.md` (player.begin_soul_drain API), existing `player.gd` (take_damage, groups), `demon-assets.md` (sprites), `demon-spawning.md` (EMERGING state)
- **Depended on by**: `soul-wisp-vfx.md` (wisp release on demon death), `demon-spawning.md` (spawn system instantiates these scenes)
