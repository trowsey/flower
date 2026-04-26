# Combat

## Purpose
The "feel" loop. Combat is the chain that runs from "player presses attack" to "enemy reacts visibly" — damage rolls, crits, knockback, hit-stop, screen shake, damage numbers, and stats tracking — all executed in a single frame's worth of signals. Player-facing behavior: every swing has weight (brief hit-stop), crits flash yellow, finishers (combo stage 3) flash orange and shake harder, and you have a 0.4s grace period after taking damage.

## Key files
- `scripts/player.gd::_start_attack` / `_deal_damage` — outbound damage pipeline.
- `scripts/enemies/enemy_base.gd::take_damage` — inbound damage on enemies.
- `scripts/vfx/hit_feedback.gd` — autoload that fans out shake/hit-stop/numbers/flash.
- `scripts/vfx/camera_shake.gd`, `scripts/vfx/damage_number.gd` — VFX primitives.
- `scripts/camera.gd` — listens to `HitFeedback.request_camera_shake` / `request_hit_stop`.

## Data flow
End-to-end on a single attack:

```
player presses attack
  ↓
_start_attack()                 advances combo stage 1..3, plays "attack[_n]"
  attack_shape.disabled = false
  attack_area.monitoring = true
  ↓ (await ATTACK_BASE_WINDOW_DELAY / atk_speed)
_deal_damage()
  for each body in attack_area.get_overlapping_bodies():
    if in "enemies" or "destructibles":
      crit = randf() < (0.10 + stats.crit_chance_bonus())
      crit_mult = 2.0 + stats.crit_damage_bonus()
      final = base * COMBO_DAMAGE_MULT[stage-1] * (crit_mult if crit else 1)
      target.take_damage(final)
      HitFeedback.enemy_hit(pos, final, sprite, crit)        ← normal
      HitFeedback.finisher_hit(pos, final, sprite)           ← stage 3
      run_stats.record_damage_dealt(final, crit)
  ↓
EnemyBase.take_damage:
  health -= amount; emit health_changed
  _hit_flash_remaining = 0.1
  _knockback = (self - player).normalized() * 3.0
  _spawn_blood_particles
  if health<=0: die()
  ↓
HitFeedback (autoload) emits:
  request_camera_shake(0.15, 0.2)   → camera.gd applies CameraShake offset
  request_hit_stop(0.05)            → camera sets Engine.time_scale=0.05
  request_damage_number(pos, n, c)  → DamageNumber.spawn(...)
  request_sprite_flash(node, c, t)  → consumer-side
```

Player-side intake: `player.take_damage(amount)` deducts after subtracting `stats.defense()` (min 1), starts `HIT_IFRAME_DURATION = 0.4s`, calls `HitFeedback.player_hit`, resets the combo, and routes to `down_player()` (2P) or `_die_health()` (solo) on lethal damage. While `state == DASHING` or `_hit_iframe_timer > 0` the hit is dropped entirely.

## Public API
**Outbound (player → world)** — the AttackArea is the contact surface. Its `collision_mask = 4` matches `EnemyBase.collision_layer = 4`. Damage uses `player.stats.attack_damage()` × `COMBO_DAMAGE_MULT[stage-1]` (1.0 / 1.25 / 1.75) × crit factor.

**Inbound (world → player)** — anything calling `player.take_damage(amount)`.

**HitFeedback signals** (subscribers: `camera.gd`, `damage_indicator.gd`, any future SFX):
```gdscript
signal request_camera_shake(intensity: float, duration: float)
signal request_hit_stop(real_seconds: float)
signal request_damage_number(world_position: Vector3, amount: float, color: Color)
signal request_sprite_flash(node: Node3D, color: Color, duration: float)
```

Trigger helpers (call these, don't emit raw signals):
```gdscript
HitFeedback.enemy_hit(pos, amount, sprite, is_critical)   # 0.15 shake, 0.05 hit-stop
HitFeedback.finisher_hit(pos, amount, sprite)             # 0.30 shake, 0.10 hit-stop, orange
HitFeedback.player_hit(pos, amount, sprite)               # 0.25 shake, red number
HitFeedback.heal(pos, amount)                             # green number, no shake
```

## Tests
- `tests/unit/test_player_attack.gd` — combo advance, AttackArea monitoring window.
- `tests/unit/test_player_combat_polish.gd` — iframes, finisher path, dash invuln.
- `tests/unit/test_enemy_base.gd` — `take_damage`, knockback, death.
- `tests/unit/test_xp_and_crit_stats.gd` — crit roll modifier path.
- Gap: `HitFeedback` itself isn't unit tested directly (it's signal glue). Add a smoke test that spies on the four signals if regressions appear.

## Extending
**Add a new damage source (e.g. trap, projectile):** call `target.take_damage(n)` then `HitFeedback.enemy_hit(target.global_position, n, target_sprite, false)` — that's it. No need to touch `player.gd`.

**Add a new "feel" pulse type (e.g. parry):** add a public method to `hit_feedback.gd` that picks shake/hit-stop/number color and emits the right signals. Don't introduce a new signal unless camera/HUD need to differentiate.

**Tune crit feel:** numbers live on `player.gd` (`CRIT_CHANCE`, `CRIT_MULTIPLIER`, `COMBO_DAMAGE_MULT`). Crit color is hard-coded to `Color(1, 0.95, 0.2)` in both `hit_feedback.gd::enemy_hit` and `damage_number.gd::spawn` (the latter uses it to enlarge the font).

## Known gaps
- No SFX layer at all — the four HitFeedback signals are visual-only.
- `request_sprite_flash` is emitted but nothing currently subscribes (each enemy does its own modulate flash inside `_apply_hit_flash_modulate`). Wire a subscriber or remove the signal.
- Player's `take_damage` ignores the source — no vector for player-side knockback or directional damage indicator.
- Crit chance has no soft cap; stacking item rolls past 1.0 always crits.

## Spec/code mismatches
- `docs/specs/hit-feedback.md` may describe shake/hit-stop magnitudes that don't match the constants in `hit_feedback.gd::enemy_hit/finisher_hit/player_hit`. The code is canonical; reconcile when next touching the spec.
- AttackArea is sometimes described as "layer 4". It is `collision_layer = 0, collision_mask = 4` (`scenes/player.tscn`) — i.e. it _detects_ enemies on layer 4 but doesn't broadcast onto layer 4 itself.
