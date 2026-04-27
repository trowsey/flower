# VFX and Feedback

## Purpose
The "wow it actually hit" layer. `HitFeedback` is a signal-bus autoload that any system can call to trigger camera shake, hit-stop (engine time slow), floating damage numbers, and sprite flashes — without coupling the caller to the camera or the UI. Player-facing behavior: every hit you land has a tiny pause, a screen shake, and a number; crits flash yellow, finishers flash orange.

## Key files
- `scripts/vfx/hit_feedback.gd` — autoload `HitFeedback`. Public methods: `enemy_hit`, `player_hit`, `finisher_hit`, `heal`. Internally fires four signals.
- `scripts/vfx/camera_shake.gd` — `CameraShake` RefCounted helper. Owns intensity + decay; `get_offset(delta)` returns a Vec3 to add to the camera position.
- `scripts/vfx/damage_number.gd` — `DamageNumber extends Label3D`. Static `spawn(parent, world_pos, amount, color)`. Rises 1.5u/s, fades over 0.8s.
- `scripts/camera.gd` — subscribes to `HitFeedback.request_camera_shake` + `request_hit_stop`.

## Data flow
```
caller (any system) → HitFeedback.<method>(args)
                         ↓
                      reads Settings (camera_shake scale, damage_numbers on/off)
                         ↓
                      emits one or more of:
  request_camera_shake(intensity, duration)
  request_hit_stop(real_seconds)
  request_damage_number(world_pos, amount, color)
  request_sprite_flash(node, color, duration)

camera.gd:
  request_camera_shake → CameraShake.start(intensity, duration)
                         (clamped to 0.4, additive)
  request_hit_stop     → Engine.time_scale = 0.05 for `duration` real seconds,
                         then back to 1.0

camera _physics_process:
  desired = focus + offset + offset.normalized() * zoom_extra
                  + _shake.get_offset(delta)
  global_position = lerp(current, desired, smooth_speed * delta)

DamageNumber.spawn (called by whichever system listens to request_damage_number;
                    today the player handles its own spawn calls — see TODO):
  Label3D billboard, no_depth_test, pixel_size 0.005
  font_size 28 if color == crit_yellow else 22
  random ±0.3 horizontal jitter to prevent stacking
  rises 1.5/0.8 u/s, fades alpha over 0.8s, queue_free
```

`HitFeedback` respects two `Settings` gates:
- `Settings.get_camera_shake()` — multiplier; `0.0` disables shake.
- `Settings.get_damage_numbers()` — bool; if false, suppress damage number requests.

## Public API
**`HitFeedback`** (`autoload "HitFeedback"`):
```gdscript
signal request_camera_shake(intensity: float, duration: float)
signal request_hit_stop(real_seconds: float)
signal request_damage_number(world_position: Vector3, amount: float, color: Color)
signal request_sprite_flash(node: Node3D, color: Color, duration: float)

func enemy_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null,
               is_critical: bool = false) -> void
   # 0.15 shake, 0.05 hit-stop, white number (yellow if crit)

func finisher_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null) -> void
   # 0.30 shake, 0.10 hit-stop, orange number — combo stage 3

func player_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null) -> void
   # 0.25 shake, no hit-stop, red number

func heal(world_position: Vector3, amount: float) -> void
   # green number, no shake/hit-stop
```

Optional `explosion(pos, radius)` is called by `Maddie._skill_ground_pound` and `EnemyBase._explode` if defined. (Verify in `hit_feedback.gd` before relying on it from new code; today only `enemy_hit / player_hit / finisher_hit / heal` are stable.)

**`CameraShake`** (`class_name CameraShake extends RefCounted`):
```gdscript
func start(intensity_units: float, duration: float) -> void
   # additive intensity, clamped at 0.4; max(time_left, duration)
func get_offset(delta: float) -> Vector3
   # decays linearly over duration; returns random shake offset
func is_active() -> bool
```

**`DamageNumber`** (`extends Label3D`):
```gdscript
static func spawn(parent: Node, world_pos: Vector3, amount: float, color: Color) -> void
```

## Tests
- VFX is mostly visual; covered indirectly by:
  - `tests/unit/test_player_combat_polish.gd` — finisher path triggers `HitFeedback.finisher_hit`.
  - `tests/unit/test_enemy_base.gd` — `take_damage` triggers blood + (optionally) explosion.
- Gap: no test that confirms `Settings.get_camera_shake() == 0.0` actually suppresses the shake signal; would need a signal spy.

## Extending
**Trigger from a new system (e.g. trap):**
```gdscript
if has_node("/root/HitFeedback"):
    get_node("/root/HitFeedback").enemy_hit(target.global_position, dmg, target, false)
```
Always guard with `has_node("/root/HitFeedback")` so unit tests without the autoload don't crash.

**Add a new feedback type (e.g. parry flash):** add a method on `hit_feedback.gd` that picks shake/hit-stop/number color and emits the existing signals. Avoid adding new signals unless the camera or HUD needs to differentiate.

**Hook a sprite-flash subscriber:** the `request_sprite_flash` signal currently has no listener (each enemy does its own modulate flash inside `enemy_base.gd::_apply_hit_flash_modulate`). To centralize, add a node that subscribes and runs `Tween` over the sprite's modulate.

**Spawn damage numbers from a different scope** (e.g. healing over time): call `DamageNumber.spawn(get_tree().current_scene, pos, n, Color.GREEN)` directly — it's a static.

## Known gaps
- `request_sprite_flash` is emitted but unsubscribed; either wire a consumer or remove.
- `request_damage_number` is emitted by `HitFeedback` but I cannot find a subscriber that calls `DamageNumber.spawn` — verify in your changes whether the player or another script does it; otherwise damage numbers may not appear despite the signal firing.
- No SFX layer at all; see [Audio](Audio.md).
- Hit-stop sets `Engine.time_scale = 0.05` globally — pause-immune nodes still resume at real speed. UI is currently using `PROCESS_MODE_ALWAYS` for menus, fine.
- No "knockback feedback" (e.g. lines, dust) on enemy push — the `_knockback` is purely position-shift.

## Spec/code mismatches
- `docs/specs/hit-feedback.md` should be checked against the magnitudes in `enemy_hit / finisher_hit / player_hit`. Code is canonical.
- `docs/specs/blood-particles.md` and `docs/specs/death-explosions.md` reference `_spawn_blood_particles` / `_spawn_death_particles` in `enemy_base.gd`; ensure the referenced `.tscn` files exist (`scenes/effects/blood_particles.tscn`, `scenes/effects/death_particles.tscn`).
