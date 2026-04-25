# Soul Wisp Visual Effects Spec

## Overview

The soul wisp is a glowing ghost/spirit sprite that visually represents the player's soul during demon drain interactions. It leaves the player's body when a demon latches on, floats toward the demon during drain, returns on demon death, or is fully absorbed if the soul timer expires.

## Requirements

1. Wisp is a visual-only node — no collision, no gameplay logic (soul meter in `player.gd` is the source of truth)
2. Wisp appears ONLY during the drain interaction (not visible during normal play)
3. Wisp movement follows smooth curved paths (not linear), using tweens or `Path3D`
4. Wisp brightness/opacity correlates with remaining soul meter (dimmer = less soul left)
5. Wisp color: pale blue-white with soft glow (distinct from torch orange)
6. Three visual sequences: drain, recovery, and death absorption
7. Must be visible against the dark dungeon background at camera zoom level (ortho size=12)

## Wisp Node Structure

The wisp is managed by a dedicated script, instantiated when a latch begins:

```
SoulWisp (Node3D)
  ├── WispSprite (AnimatedSprite3D) [billboard=1, pixel_size=0.015]
  ├── WispGlow (OmniLight3D) [subtle blue-white point light]
  └── WispParticles (GPUParticles3D) [trailing sparkle particles]
```

### WispSprite
- `AnimatedSprite3D` with `SpriteFrames` containing wisp animations
- `billboard = 1` (Y-axis billboard, same as player/demons)
- `pixel_size = 0.015` (match existing sprites)
- `texture_filter = 0` (nearest neighbor)

### WispGlow
- `OmniLight3D` for soft ambient glow around the wisp
- Color: `Color(0.6, 0.7, 1.0, 1.0)` — pale blue-white
- Energy: 0.5–1.0 (subtle, not overpowering the scene)
- Range: 3.0 units
- Light energy fades with soul meter

### WispParticles (optional enhancement)
- `GPUParticles3D` for a trailing sparkle effect
- Small, short-lived particles that follow the wisp's path
- Color: white to light blue, fading to transparent
- Emission: 10–20 particles, lifetime 0.5s

## Visual Sequences

### 1. Soul Drain (player → demon)

**Trigger**: `player.state` changes to `BEING_DRAINED`

**Sequence**:
1. Wisp sprite fades in at player's chest position (player.global_position + Vector3(0, 1.0, 0))
2. WispSprite plays "drain_travel" animation
3. Wisp follows a **curved path** from player to demon over 1.5 seconds
4. Path: upward arc (rises ~1.5 units above the midpoint, then curves down to demon)
5. Once at the demon, wisp plays "captured" animation (looping, subtle pulse near the demon)
6. While captured, wisp opacity = `soul / MAX_SOUL` (gets dimmer as soul drains)
7. WispGlow energy also scales: `0.8 * (soul / MAX_SOUL)`

**Implementation**:
```gdscript
# scripts/soul_wisp.gd
extends Node3D

@onready var sprite: AnimatedSprite3D = $WispSprite
@onready var glow: OmniLight3D = $WispGlow

var _player: CharacterBody3D
var _demon: CharacterBody3D

func start_drain(player: CharacterBody3D, demon: CharacterBody3D) -> void:
    _player = player
    _demon = demon
    global_position = player.global_position + Vector3(0, 1.0, 0)
    visible = true
    sprite.play("drain_travel")

    # Curved path using tween with custom interpolation
    var start := global_position
    var end := demon.global_position + Vector3(0, 1.2, 0)
    var mid := (start + end) / 2.0 + Vector3(0, 1.5, 0)  # arc peak

    var tween := create_tween()
    tween.tween_method(_follow_arc.bind(start, mid, end), 0.0, 1.0, 1.5)
    tween.tween_callback(_arrive_at_demon)

func _follow_arc(t: float, start: Vector3, mid: Vector3, end: Vector3) -> void:
    # Quadratic Bezier: B(t) = (1-t)²·start + 2(1-t)t·mid + t²·end
    var p := (1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * mid + t * t * end
    global_position = p

func _arrive_at_demon() -> void:
    sprite.play("captured")
```

### 2. Soul Recovery (demon dies → wisp returns)

**Trigger**: Latched demon dies (health <= 0) while player soul > 0

**Sequence**:
1. Wisp plays "return" animation
2. Demon plays death animation simultaneously
3. Wisp follows a curved path from demon back to player over 1.0 seconds (faster than drain — feels snappy/rewarding)
4. Path: upward arc, same Bezier approach but reversed
5. On arrival at player: brief flash/pulse effect, wisp fades out
6. Soul meter restores (handled by `player.recover_soul()`)
7. WispGlow pulses brightly on return (energy 2.0 → fades to 0)

**Implementation**:
```gdscript
func start_return() -> void:
    sprite.play("return")
    var start := global_position
    var end := _player.global_position + Vector3(0, 1.0, 0)
    var mid := (start + end) / 2.0 + Vector3(0, 2.0, 0)

    var tween := create_tween()
    tween.tween_method(_follow_arc.bind(start, mid, end), 0.0, 1.0, 1.0)
    tween.tween_callback(_arrive_at_player)

func _arrive_at_player() -> void:
    # Flash effect
    glow.light_energy = 2.5
    var tween := create_tween()
    tween.tween_property(glow, "light_energy", 0.0, 0.5)
    tween.tween_callback(queue_free)
```

### 3. Soul Death (soul reaches 0 → demon absorbs wisp)

**Trigger**: `player.soul` reaches 0

**Sequence**:
1. Wisp plays "absorbed" animation
2. Wisp shrinks toward the demon's center (scale tweens from 1.0 to 0.0 over 0.8s)
3. WispGlow fades to 0
4. Brief dark pulse from the demon (demon sprite flashes red/dark)
5. Player collapse begins (sprite plays "death" animation)
6. Wisp node freed after absorption complete

**Implementation**:
```gdscript
func start_absorption() -> void:
    sprite.play("absorbed")
    var tween := create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector3.ZERO, 0.8).set_ease(Tween.EASE_IN)
    tween.tween_property(self, "global_position",
        _demon.global_position + Vector3(0, 1.0, 0), 0.8).set_ease(Tween.EASE_IN)
    tween.tween_property(glow, "light_energy", 0.0, 0.8)
    tween.chain().tween_callback(queue_free)
```

## Soul Timer Visual Feedback

As the soul drains, additional visual cues reinforce urgency:

### Wisp Dimming
- Wisp sprite modulate alpha: `soul / MAX_SOUL` (100% → 0%)
- Wisp glow energy: scales proportionally
- At 25% soul remaining: wisp starts flickering (modulate alpha oscillates ±0.2)

### Screen Effects (optional — needs Tim's input)
- Vignette: subtle dark edges that increase as soul drops below 50%
- Color desaturation: world gets grayer as soul drops
- Heartbeat pulse: screen pulses dark at low soul (below 25%)

Implementation for wisp dimming during drain:
```gdscript
func update_soul_visual(soul_ratio: float) -> void:
    # soul_ratio = current_soul / MAX_SOUL (1.0 = full, 0.0 = empty)
    sprite.modulate.a = max(soul_ratio, 0.1)  # never fully invisible until absorbed
    glow.light_energy = 0.8 * soul_ratio

    # Flicker at low soul
    if soul_ratio < 0.25:
        var flicker := sin(Time.get_ticks_msec() * 0.01) * 0.2
        sprite.modulate.a = max(soul_ratio + flicker, 0.05)
```

## Wisp Manager

A lightweight coordinator spawns/despawns the wisp in response to player state:

```gdscript
# scripts/soul_wisp_manager.gd
extends Node

const WispScene := preload("res://scenes/effects/soul_wisp.tscn")
var _active_wisp: Node3D = null

func _ready() -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player:
        player.latch_started.connect(_on_latch_started)
        player.latch_broken.connect(_on_latch_broken)
        player.soul_changed.connect(_on_soul_changed)

func _on_latch_started(demon: Node3D) -> void:
    if _active_wisp:
        _active_wisp.queue_free()
    _active_wisp = WispScene.instantiate()
    get_tree().current_scene.add_child(_active_wisp)
    _active_wisp.start_drain(
        get_tree().get_first_node_in_group("player"), demon)

func _on_latch_broken(demon: Node3D) -> void:
    if _active_wisp:
        _active_wisp.start_return()
        _active_wisp = null

func _on_soul_changed(new_value: float) -> void:
    if _active_wisp:
        _active_wisp.update_soul_visual(new_value / 100.0)
    if new_value <= 0.0 and _active_wisp:
        _active_wisp.start_absorption()
        _active_wisp = null
```

## Color Palette

| Element | Color | Hex |
|---------|-------|-----|
| Wisp core | Pale blue-white | #B8D4FF |
| Wisp glow | Soft blue | #99AAEE |
| Wisp trail particles | White to blue fade | #FFFFFF → #88AAFF |
| Wisp at low soul | Dim purple-gray | #776688 |
| Absorption flash (demon) | Dark red | #AA2222 |
| Return flash (player) | Bright white-blue | #DDEEFF |

## File Structure

```
scripts/
  soul_wisp.gd             # New — wisp node behavior (drain, return, absorb)
  soul_wisp_manager.gd     # New — spawns/despawns wisp based on player state
scenes/
  effects/
    soul_wisp.tscn          # New — wisp scene (AnimatedSprite3D + OmniLight3D + GPUParticles3D)
assets/
  effects/
    soul_wisp_idle_0.png    # Wisp sprite frames (see demon-assets.md)
    soul_wisp_drain_travel_0.png
    ...
```

## Open Questions

1. **Screen effects**: Does Tim want vignette/desaturation during soul drain, or is the wisp visual enough? Screen effects add polish but also dev time.
2. **Wisp size**: How large should the wisp be relative to the player? (Suggest: ~0.5× player sprite height)
3. **Sound**: Should there be a humming/ethereal sound during drain? This spec covers visuals only, but audio would pair well.
4. **Multiple soul drains**: If the player breaks free and gets latched again, does the wisp re-spawn fresh or continue from its current state? (Recommend: fresh spawn each latch)
5. **Wisp particles**: Are `GPUParticles3D` trail particles worth the effort for first pass, or save for polish? (Recommend: skip for first pass, add later)

## Dependencies

- **Depends on**: `soul-system.md` (player signals: latch_started, latch_broken, soul_changed), `demon-assets.md` (wisp sprite frames), `demon-behavior.md` (demon death triggers wisp return)
- **Depended on by**: nothing directly — this is a visual layer on top of the soul system
