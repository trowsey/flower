# Spec: Enemy Variety — 4 New Types

## Goal
Diversify combat with enemies that force different responses (kite, dodge,
focus-down) instead of all chasing-melee.

## 1. Skeleton Archer (`scripts/enemies/archer.gd`)
- HP 18, dmg 8, speed 2.5, attack_range 9.0 (ranged)
- Behavior: kite — flee if player within 4m; otherwise stay at 6-8m and shoot.
- Cooldown 1.4s. Projectile = simple raycast hit at fire moment (no scene).
- xp_reward 30, gold 2-8.
- Sprite color: pale white.

## 2. Charger (`scripts/enemies/charger.gd`)
- HP 35, dmg 16, speed 6.0 during charge (else 2.5)
- Behavior: when within 8m, telegraph 0.6s (turns red), then dash in straight
  line for 1.0s. Hits player on contact, then 1.5s recovery.
- xp_reward 35, gold 1-6.
- Sprite color: orange-red.

## 3. Bomber (`scripts/enemies/bomber.gd`)
- HP 14, dmg 30 (explosion), speed 4.0
- Behavior: chase to 1.5m, then 1.0s fuse (yellow → red flash), then explode.
- death_explosion_radius 2.5, death_explosion_damage 30.
- xp_reward 25, gold 0-4.
- Sprite color: green.

## 4. Cult Healer (`scripts/enemies/healer.gd`)
- HP 25, dmg 0, speed 3.0
- Behavior: stays 5-7m from player. Every 2.5s, heals nearest living enemy
  in 8m radius for 10 HP (skips self). Flees player if within 3m.
- xp_reward 40, gold 4-10.
- Sprite color: cyan.
- Priority target — game intelligence: healer should be visually distinct
  (slightly larger) so players learn to focus it.

## Tests
- HP/damage/speed defaults match spec for each enemy.
- Archer fires only when in cast range; cooldown respected.
- Charger telegraph state observable as `state == "charging"`.
- Bomber detonates on fuse expiry (force-trigger via `_fuse_timer = 0`).
- Healer heals nearest other enemy; skips self.

## Out of scope
- Pathfinding around walls (we use direct LOS / move_and_slide).
- Boss-tier enemies (separate spec).
