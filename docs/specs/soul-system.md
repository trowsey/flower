# Soul & Health System Spec

## Overview

The soul system is a 15-second drain timer separate from health. When a demon latches onto the player, their soul is drained — if it reaches zero, the player dies regardless of remaining health. Health is a conventional HP pool damaged by non-demon enemies and fighter-drainer demons.

## Requirements

1. Player has a **soul meter** (0–100, starts at 100)
2. Player has a **health meter** (0–100 HP, starts at 100)
3. Soul drains linearly from 100 → 0 over exactly 15 seconds when a demon is latched (drain rate: ~6.67/sec)
4. Soul drain ONLY occurs while a demon is latched — no passive drain
5. Soul meter pauses drain when no demon is latched
6. When soul reaches 0 → player death (soul_dead state), regardless of remaining HP
7. When health reaches 0 → player death (health_dead state), regardless of remaining soul
8. Killing a latched demon releases a soul wisp — collecting it restores the drained soul amount
9. Player is **frozen** (cannot move) while latched, but **can still attack**
10. Only ONE demon may latch at a time — others attack health normally
11. Breaking the latch (dealing enough damage to the latched demon) stops soul drain immediately
12. Soul recovery: wisp floats back → restores soul to pre-latch value (or a fixed recovery amount — see Open Questions)
13. UI displays: soul bar (purple/blue), health bar (red), and a drain timer countdown when being drained

## Technical Approach

### Player State Machine

Extend `player.gd` with a state enum and soul/health tracking:

```
enum PlayerState { NORMAL, BEING_DRAINED, SOUL_DEAD, HEALTH_DEAD }
```

**State transitions:**
```
NORMAL → BEING_DRAINED     (demon latches on)
BEING_DRAINED → NORMAL     (latch broken: demon killed or enough damage dealt)
BEING_DRAINED → SOUL_DEAD  (soul reaches 0)
NORMAL → HEALTH_DEAD       (health reaches 0)
BEING_DRAINED → HEALTH_DEAD (health reaches 0 while being drained)
```

### Modifications to `scripts/player.gd`

Add these properties:

```gdscript
const MAX_SOUL := 100.0
const MAX_HEALTH := 100.0
const SOUL_DRAIN_DURATION := 15.0
const SOUL_DRAIN_RATE := MAX_SOUL / SOUL_DRAIN_DURATION  # ~6.67/sec

var soul := MAX_SOUL
var health := MAX_HEALTH
var state: PlayerState = PlayerState.NORMAL
var _latched_demon: Node3D = null
var _soul_at_latch_start := MAX_SOUL

signal soul_changed(new_value: float)
signal health_changed(new_value: float)
signal player_state_changed(new_state: PlayerState)
signal latch_started(demon: Node3D)
signal latch_broken(demon: Node3D)
```

### Latch Interaction (called by demon)

```gdscript
func begin_soul_drain(demon: Node3D) -> bool:
    if state != PlayerState.NORMAL:
        return false  # already being drained or dead
    _latched_demon = demon
    _soul_at_latch_start = soul
    state = PlayerState.BEING_DRAINED
    latch_started.emit(demon)
    player_state_changed.emit(state)
    return true

func end_soul_drain() -> void:
    if state != PlayerState.BEING_DRAINED:
        return
    _latched_demon = null
    state = PlayerState.NORMAL
    player_state_changed.emit(state)
    latch_broken.emit(_latched_demon)
```

### Soul Drain in `_physics_process`

```gdscript
# Inside _physics_process, before movement code:
if state == PlayerState.BEING_DRAINED:
    soul -= SOUL_DRAIN_RATE * delta
    soul_changed.emit(soul)
    if soul <= 0.0:
        soul = 0.0
        _die_soul()
        return
```

### Movement Freeze During Latch

Modify `_physics_process`: when `state == BEING_DRAINED`, skip all movement code but **do not** skip attack input. The player can still press attack to hit the latched demon.

```gdscript
func _physics_process(delta: float) -> void:
    _process_soul_drain(delta)

    if state in [PlayerState.SOUL_DEAD, PlayerState.HEALTH_DEAD]:
        return

    # Attacking is always allowed (even when latched)
    if _attacking:
        return

    # Movement is blocked when latched
    if state == PlayerState.BEING_DRAINED:
        velocity = Vector3.ZERO
        return

    # ... existing movement code ...
```

### Health Damage (called by enemies)

```gdscript
func take_damage(amount: float) -> void:
    if state in [PlayerState.SOUL_DEAD, PlayerState.HEALTH_DEAD]:
        return
    health -= amount
    health_changed.emit(health)
    if health <= 0.0:
        health = 0.0
        _die_health()

func _die_soul() -> void:
    state = PlayerState.SOUL_DEAD
    player_state_changed.emit(state)
    velocity = Vector3.ZERO
    sprite.play("death")  # needs new animation

func _die_health() -> void:
    state = PlayerState.HEALTH_DEAD
    player_state_changed.emit(state)
    velocity = Vector3.ZERO
    sprite.play("death")
```

### Soul Recovery

When the latched demon dies, it emits a signal. The player (or a wisp manager) handles recovery:

```gdscript
func recover_soul(amount: float) -> void:
    soul = min(soul + amount, MAX_SOUL)
    soul_changed.emit(soul)
```

### UI

Create `scenes/ui/player_hud.tscn` with:

- **SoulBar**: `ProgressBar` node, range 0–100, purple/blue color
- **HealthBar**: `ProgressBar` node, range 0–100, red color
- **DrainTimer**: `Label` showing countdown (e.g., "12.3s") — visible only during BEING_DRAINED state
- **CanvasLayer** to keep UI on screen

Script `scripts/ui/player_hud.gd`:
- Connect to `soul_changed`, `health_changed`, `player_state_changed` signals
- Update bars and timer visibility

## File Structure

```
scripts/
  player.gd              # Modified — add soul/health, state machine, latch API
  ui/
    player_hud.gd        # New — HUD controller
scenes/
  ui/
    player_hud.tscn       # New — HUD scene (CanvasLayer + bars)
```

## Open Questions

1. **Soul recovery amount**: Restore to pre-latch value? Or a fixed percentage? (Recommend: restore the amount that was drained, i.e., back to `_soul_at_latch_start`)
2. **Death animation**: Do we need a separate "soul death" vs "health death" animation, or same collapse for both?
3. **Invulnerability frames**: Should the player get brief i-frames after latch is broken?
4. **Health regen**: Any passive health regeneration, or health only from pickups?
5. **Soul drain visual feedback**: Screen tint / vignette during drain? (See soul-wisp-vfx.md for wisp visuals)

## Dependencies

- **Depends on**: existing `player.gd` (extends it)
- **Depended on by**: `demon-behavior.md` (demons call `begin_soul_drain` / `take_damage`), `soul-wisp-vfx.md` (wisp visual tied to soul state), `demon-spawning.md` (spawn triggers may reference player state)
