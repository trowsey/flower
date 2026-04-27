# Feature: Enemy Variety

## Overview
Expand beyond the existing demon types with distinct enemy archetypes that force different player strategies. Each type has unique movement patterns, attack behaviors, and visual silhouettes so players can instantly recognize the threat.

## Requirements

### REQ-1: Ranged enemy type — Imp Caster
**Given** a ranged enemy spawns
**Then** it maintains distance (8-12 units) from the player, fires slow-moving projectiles (speed 6.0 units/sec), and retreats if the player gets within 5 units

### REQ-2: Imp Caster projectile
**Given** the Imp Caster attacks
**When** the attack cooldown (2.0s) is ready
**Then** it spawns a projectile (Area3D + CollisionShape3D on layer 4) that travels toward the player's position at time of fire, deals 10 damage on contact, and is freed after 4 seconds or on hit

### REQ-3: Swarm enemy type — Skitterer
**Given** a swarm enemy spawns
**Then** it has low HP (15), low damage (5), fast move_speed (6.0), and always spawns in groups of 3-5 from a single spawn point

### REQ-4: Skitterer behavior
**Given** Skitterers are active
**When** chasing the player
**Then** they use a flocking behavior with slight random offset per individual, creating a swarm look rather than stacking on one point

### REQ-5: Tank enemy type — Brute
**Given** a tank enemy spawns
**Then** it has high HP (150), slow move_speed (2.0), high damage (30), and a charge attack that covers distance quickly

### REQ-6: Brute charge attack
**Given** the Brute detects the player at range 5-10 units
**When** the charge cooldown (6.0s) is ready
**Then** the Brute winds up for 0.8 seconds (visual telegraph), then dashes at 12.0 units/sec toward the player's position, dealing 30 damage on collision, and is stunned for 1.0 second after the charge ends

### REQ-7: All enemies share base interface
**Given** any enemy type
**Then** it extends the demon_base pattern: CharacterBody3D, in "enemies" group, collision layer 4, has take_damage method, uses NavigationAgent3D, and AnimatedSprite3D

### REQ-8: Distinct visual silhouettes
**Given** the enemy types
**Then** each has a clearly different size and shape:
- Imp Caster: small and hunched (0.7x player height)
- Skitterer: tiny and wide (0.4x player height, wider)
- Brute: large and bulky (1.8x player height)

### REQ-9: Enemy stats as exported vars
**Given** any enemy script
**Then** all combat stats (max_health, move_speed, attack_damage, attack_cooldown, detection_range) are @export variables, tunable per-instance in the editor

### REQ-10: Enemy death integrates with existing systems
**Given** any enemy dies
**When** health reaches 0
**Then** it plays a death animation, drops loot (see item-drops spec), emits an enemy_died signal, and calls queue_free after the animation completes

## Edge Cases
- Imp Caster projectile hitting a wall — should be freed on world collision (layer 1)
- Brute charge hitting a wall — stops the charge and applies the stun
- Skitterer group partially killed — survivors continue with smaller flock
- All enemy types can be latched by the soul system if can_latch is true on their base

## Out of Scope
- Flying enemies (all enemies are ground-based for now)
- Enemy special abilities beyond what's listed
- Enemy resistances or damage types
