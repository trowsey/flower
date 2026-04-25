# Feature: Destructible Objects

## Overview
The dungeon is littered with breakable objects — barrels, urns, crates, and bone piles. Hitting them with an attack breaks them apart, potentially dropping gold, health potions, or items. They add interactivity to the environment and reward thorough exploration.

## Requirements

### REQ-1: Destructible base class
**Given** a destructible object
**Then** it extends StaticBody3D, is in the "destructibles" group, has a take_damage method, and sits on collision layer 8 (new layer for destructibles)

### REQ-2: Player attack area detects destructibles
**Given** the player's AttackArea
**Then** its collision_mask includes layer 8 so attacks hit destructible objects

### REQ-3: Destructible health
**Given** a destructible object
**Then** it has an @export var health (default 1.0 — one-hit break), and when health reaches 0 it breaks

### REQ-4: Break animation
**Given** a destructible is destroyed
**When** health reaches 0
**Then** the sprite plays a "break" animation (2-3 frames), particle debris emits (5-10 small particles matching the object's color), and the node is freed after the animation

### REQ-5: Loot drop on break
**Given** a destructible breaks
**When** the break completes
**Then** it rolls on a loot table:
- 60% chance: nothing
- 25% chance: gold (1-5 coins)
- 10% chance: health potion (small, restores 15 HP)
- 5% chance: item (from common item pool)

### REQ-6: Object types
**Given** the destructible system
**Then** four visual variants exist: barrel (wood, brown), urn (ceramic, gray), crate (wood, darker), bone pile (white/gray)

### REQ-7: Placement in rooms
**Given** room templates
**Then** rooms have Marker3D nodes tagged "destructible_spawn" where objects are randomly placed during room instantiation (0-4 per room)

### REQ-8: Objects block navigation
**Given** a destructible is intact
**Then** it has a collision shape that blocks player and enemy movement. Once destroyed, the collision is removed and the path is clear.

### REQ-9: No respawn
**Given** a destructible is destroyed
**Then** it does not respawn — destroyed objects stay gone for the duration of the floor

### REQ-10: Break sound/feedback
**Given** a destructible breaks
**Then** the break integrates with the hit-feedback system: brief screen shake (intensity 0.05), and a damage number does NOT appear (it's an object, not an enemy)

## Edge Cases
- Player attacking a group of adjacent destructibles — each hit only damages objects in the attack area
- Destructible with health > 1 (e.g., reinforced crate with 3 HP) — shows damage cracks on each hit
- Enemy attacks do NOT break destructibles (only player attacks)

## Out of Scope
- Explosive barrels (chain reaction destructibles)
- Destructible walls / secret passages
- Object physics (broken pieces flying realistically)
